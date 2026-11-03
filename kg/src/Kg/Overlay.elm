module Kg.Overlay exposing (Overlay, refresh, dirtyEntries)

{-| The overlay of uncommitted files (§12.3 of the plan): HEAD's tree with the
worktree's dirty files applied, linked and indexed. The history is not
changed: uncommitted edits are not commits.

The dirty set's fingerprint is a SHA-256 over the sorted (path, status, blob)
entries; when it has not changed, the overlay is kept.

-}

import Dict exposing (Dict)
import Kg.Assemble exposing (ConceptSpec)
import Kg.Build as Build
import Kg.Codec as Codec
import Kg.Context exposing (Context)
import Kg.Extract as Extract
import Kg.Facts as Facts
import Kg.Fs as Fs
import Kg.Git as Git
import Kg.Graph exposing (Graph)
import Kg.Link exposing (PackageKernels)
import Kg.Search.Bm25 as Bm25
import Kg.Search.Chunks exposing (Chunk)
import Kg.Sha256 as Sha256
import Kg.Snapshot exposing (Snapshot)
import Kg.Stages as Stages
import Kg.Update as Update
import Task exposing (Task)


type alias Overlay =
    { fingerprint : String
    , fileCount : Int
    , files : List String
    , graph : Graph
    , chunks : List Chunk
    , bm25 : Bm25.Index
    }


{-| The dirty files kg reads: (path, Just blob) for a file present in the
worktree, (path, Nothing) for one deleted.
-}
dirtyEntries : Context -> Task String (List ( String, String, Maybe String ))
dirtyEntries ctx =
    Git.status ctx.worktree Stages.logPaths
        |> Task.andThen
            (\entries ->
                let
                    deletedFrom =
                        entries |> List.filterMap .from |> List.map (\p -> ( p, "R-", Nothing ))

                    relevant =
                        entries |> List.filter (\e -> Build.needsFacts e.path)

                    ( gone, present ) =
                        List.partition (\e -> String.contains "D" e.xy) relevant
                in
                Git.hashObjects ctx.worktree (List.map .path present)
                    |> Task.map
                        (\blobs ->
                            List.map2 (\e b -> ( e.path, e.xy, Just b )) present blobs
                                ++ List.map (\e -> ( e.path, e.xy, Nothing )) gone
                                ++ List.filter (\( p, _, _ ) -> Build.needsFacts p) deletedFrom
                        )
            )


fingerprintOf : List ( String, String, Maybe String ) -> String
fingerprintOf entries =
    entries
        |> List.map (\( p, xy, b ) -> p ++ "\t" ++ xy ++ "\t" ++ Maybe.withDefault "-" b)
        |> List.sort
        |> String.join "\n"
        |> Sha256.sha256


refresh : Context -> PackageKernels -> List ConceptSpec -> Update.Progress -> Snapshot -> Maybe Overlay -> Task String (Maybe Overlay)
refresh ctx packages concepts progress snap previous =
    dirtyEntries ctx
        |> Task.andThen
            (\entries ->
                if List.isEmpty entries then
                    Task.succeed Nothing

                else
                    let
                        fp =
                            fingerprintOf entries ++ snap.header.commit
                    in
                    case previous of
                        Just o ->
                            if o.fingerprint == fp then
                                Task.succeed (Just o)

                            else
                                build ctx packages concepts progress snap fp entries |> Task.map Just

                        Nothing ->
                            build ctx packages concepts progress snap fp entries |> Task.map Just
            )


build : Context -> PackageKernels -> List ConceptSpec -> Update.Progress -> Snapshot -> String -> List ( String, String, Maybe String ) -> Task String Overlay
build ctx packages concepts progress snap fp entries =
    let
        present =
            List.filterMap (\( p, _, b ) -> Maybe.map (\blob -> ( blob, p )) b) entries
    in
    present
        |> List.map (\( blob, path ) -> extractFromWorktree ctx blob path)
        |> Task.sequence
        |> Task.andThen (\_ -> Git.lsTree ctx.worktree snap.header.commit Stages.logPaths)
        |> Task.andThen
            (\tree ->
                let
                    applied =
                        List.foldl
                            (\( p, _, b ) t ->
                                case b of
                                    Just blob ->
                                        Dict.insert p blob t

                                    Nothing ->
                                        Dict.remove p t
                            )
                            tree
                            entries
                in
                Update.indexTree ctx packages concepts progress (Just ( snap.chunks, snap.bm25 )) applied
            )
        |> Task.map
            (\ix ->
                { fingerprint = fp
                , fileCount = List.length entries
                , files = List.map (\( p, _, _ ) -> p) entries
                , graph = ix.graph
                , chunks = ix.chunks
                , bm25 = ix.bm25
                }
            )


{-| Facts for a file that is not in git yet, read from the worktree and cached
under the blob id git would give it.
-}
extractFromWorktree : Context -> String -> String -> Task String ()
extractFromWorktree ctx blob path =
    let
        target =
            ctx.paths.facts blob (Build.factKind path)
    in
    Fs.exists target
        |> Task.andThen
            (\have ->
                if have then
                    Task.succeed ()

                else
                    Fs.readTextMaybe (ctx.worktree ++ "/" ++ path)
                        |> Task.andThen
                            (\text ->
                                let
                                    facts =
                                        case text of
                                            Just t ->
                                                Extract.extract path t

                                            Nothing ->
                                                Facts.Unparsed "not UTF-8, or unreadable"
                                in
                                Fs.writeAtomic target (Codec.encode Facts.codec facts)
                            )
            )
