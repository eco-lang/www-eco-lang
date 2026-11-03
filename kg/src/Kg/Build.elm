module Kg.Build exposing (Replayed, replay, replayFrom, ensureFacts, loadFacts, factKind, needsFacts, CommitInfo)

{-| The IO driver of the replay (§10.1 and §12.1 of the plan): reads the
first-parent log, makes sure every blob it needs has facts in the cache, and
steps `Kg.Replay` through the commits.

Facts are cached by blob id, the kind of file and the extractor version, under
`facts/` in the repository's cache directory, and are written once.

-}

import Array exposing (Array)
import Bytes exposing (Bytes)
import Dict exposing (Dict)
import Kg.Codec as Codec
import Kg.Context exposing (Context)
import Kg.Extract as Extract
import Kg.Facts as Facts exposing (FileFacts(..))
import Kg.Fs as Fs
import Kg.Git as Git exposing (Commit)
import Kg.Link exposing (PackageKernels)
import Kg.Replay as Replay
import Kg.Sha256 as Sha256
import Kg.Stages as Stages
import Set exposing (Set)
import Task exposing (Task)


type alias CommitInfo =
    { hash : String, time : Int, subject : String }


type alias Replayed =
    { state : Replay.State
    , commits : Array CommitInfo
    , packages : PackageKernels
    , extracted : Int
    }


{-| The part of the cache key that depends on the path: the kind of file, and
for the extractors whose output depends on the path itself, a hash of it.
-}
factKind : String -> String
factKind path =
    let
        v =
            "." ++ String.fromInt Facts.extractorVersion

        withPath k =
            k ++ "-" ++ Sha256.short 8 path ++ v
    in
    if Stages.isConfigPath path then
        withPath "elmcfg"

    else
        case Extract.kind path of
            Extract.ElmSource ->
                "elm" ++ v

            Extract.CppSource ->
                if String.endsWith ".td" path then
                    "td" ++ v

                else
                    "cpp" ++ v

            Extract.ElmJsonFile ->
                "json" ++ v

            Extract.CMakeFile ->
                withPath "cmake"

            Extract.MarkdownFile ->
                withPath "md"

            Extract.InvariantsFile ->
                "csv" ++ v

            Extract.Other ->
                "other" ++ v


{-| Whether kg reads a path at all: the module graph's files and the prose. -}
needsFacts : String -> Bool
needsFacts path =
    Stages.relevant path || Replay.proseNodeId path /= Nothing || Stages.isConfigPath path


factPath : Context -> String -> String -> String
factPath ctx blob path =
    ctx.paths.facts blob (factKind path)


{-| Extracts and caches the facts of every (blob, path) not yet in the cache.
Gives the number extracted.
-}
ensureFacts : Context -> (String -> Task String ()) -> List ( String, String ) -> Task String Int
ensureFacts ctx progress wanted =
    let
        unique =
            wanted
                |> List.foldl (\( blob, path ) d -> Dict.insert ( blob, factKind path ) ( blob, path ) d) Dict.empty
                |> Dict.values
    in
    unique
        |> List.map (\( blob, path ) -> Fs.exists (factPath ctx blob path) |> Task.map (\e -> ( e, ( blob, path ) )))
        |> sequenceChunked 200
        |> Task.andThen
            (\checked ->
                let
                    missing =
                        List.filterMap
                            (\( e, bp ) ->
                                if e then
                                    Nothing

                                else
                                    Just bp
                            )
                            checked
                in
                if List.isEmpty missing then
                    Task.succeed 0

                else
                    progress ("extracting facts for " ++ String.fromInt (List.length missing) ++ " blobs")
                        |> Task.andThen (\_ -> Fs.makeDirs ctx.paths.scratch)
                        |> Task.andThen (\_ -> extractBatches ctx progress missing 0)
                        |> Task.map (\_ -> List.length missing)
            )


extractBatches : Context -> (String -> Task String ()) -> List ( String, String ) -> Int -> Task String ()
extractBatches ctx progress missing done =
    case missing of
        [] ->
            Task.succeed ()

        _ ->
            let
                batch =
                    List.take 300 missing

                rest =
                    List.drop 300 missing

                blobs =
                    List.map Tuple.first batch |> Set.fromList |> Set.toList
            in
            Git.catFiles ctx.worktree ctx.paths.scratch blobs
                |> Task.andThen
                    (\contents ->
                        batch
                            |> List.map
                                (\( blob, path ) ->
                                    let
                                        facts =
                                            case Dict.get blob contents |> Maybe.andThen Fs.bytesToString of
                                                Just text ->
                                                    Extract.extract path text

                                                Nothing ->
                                                    Unparsed "not UTF-8, or missing"
                                    in
                                    Fs.writeAtomic (factPath ctx blob path) (Codec.encode Facts.codec facts)
                                )
                            |> Task.sequence
                    )
                |> Task.andThen (\_ -> progress ("  " ++ String.fromInt (done + List.length batch) ++ " extracted"))
                |> Task.andThen (\_ -> extractBatches ctx progress rest (done + List.length batch))


{-| The facts of (blob, path) pairs from the cache, by blob. -}
loadFacts : Context -> List ( String, String ) -> Task String (Dict String FileFacts)
loadFacts ctx pairs =
    pairs
        |> List.map
            (\( blob, path ) ->
                Fs.readBytesMaybe (factPath ctx blob path)
                    |> Task.map
                        (\bytes ->
                            ( blob
                            , bytes
                                |> Maybe.andThen (Codec.decode Facts.codec)
                                |> Maybe.withDefault (Unparsed "fact file missing or unreadable")
                            )
                        )
            )
        |> Task.sequence
        |> Task.map Dict.fromList


sequenceChunked : Int -> List (Task x a) -> Task x (List a)
sequenceChunked n tasks =
    -- Task.sequence on a very long list builds a deep chain; this keeps it shallow.
    if List.length tasks <= n then
        Task.sequence tasks

    else
        Task.sequence (List.take n tasks)
            |> Task.andThen (\first -> sequenceChunked n (List.drop n tasks) |> Task.map (\rest -> first ++ rest))


{-| The whole first-parent history up to HEAD, replayed from nothing. -}
replay : Context -> PackageKernels -> (String -> Task String ()) -> Task String Replayed
replay ctx packages progress =
    Git.log ctx.worktree "" Stages.logPaths
        |> Task.andThen (\commits -> replayFrom ctx packages progress Replay.init Array.empty commits)


{-| Replays `commits` on top of a state whose history has `known` commits. -}
replayFrom : Context -> PackageKernels -> (String -> Task String ()) -> Replay.State -> Array CommitInfo -> List Commit -> Task String Replayed
replayFrom ctx packages progress state known commits =
    let
        wanted =
            commits
                |> List.concatMap .changes
                |> List.filter (\c -> c.status /= 'D' && needsFacts c.new)
                |> List.map (\c -> ( c.blob, c.new ))

        total =
            List.length commits

        base =
            Array.length known

        stepAll i cs st =
            case cs of
                [] ->
                    Task.succeed st

                c :: rest ->
                    let
                        relevantChanges =
                            c.changes |> List.filter (\ch -> ch.status /= 'D' && Stages.relevant ch.new) |> List.map (\ch -> ( ch.blob, ch.new ))
                    in
                    loadFacts ctx relevantChanges
                        |> Task.andThen
                            (\facts ->
                                let
                                    next =
                                        Replay.step packages { index = base + i, commit = c, facts = facts } st
                                in
                                (if modBy 200 i == 0 then
                                    progress
                                        ("  commit " ++ String.fromInt (i + 1) ++ "/" ++ String.fromInt total ++ ": " ++ String.fromInt (Dict.size next.graph.nodes) ++ " nodes, " ++ String.fromInt (Set.size next.graph.edges) ++ " edges")

                                 else
                                    Task.succeed ()
                                )
                                    |> Task.andThen (\_ -> stepAll (i + 1) rest next)
                            )
    in
    ensureFacts ctx progress wanted
        |> Task.andThen
            (\extracted ->
                stepAll 0 commits state
                    |> Task.map
                        (\st ->
                            { state = st
                            , commits = Array.append known (Array.fromList (List.map (\c -> { hash = c.hash, time = c.time, subject = c.subject }) commits))
                            , packages = packages
                            , extracted = extracted
                            }
                        )
            )
