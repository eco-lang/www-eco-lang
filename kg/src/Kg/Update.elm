module Kg.Update exposing (Progress, build, update, indexTree, Indexed, loadConcepts, reindexAt)

{-| Keeping a worktree's snapshot current (§12 of the plan).

    head  <- git rev-parse HEAD
    snap  <- the snapshot, or none
    same commit           -> nothing to do
    no snapshot           -> replay the whole first-parent history
    snapshot is ancestor  -> replay snapshot..head
    otherwise             -> truncate the history to the merge base, rebuild
                             the replay's state there, replay base..head

then the graph at head is linked whole from cached facts, and the search
indexes are rebuilt from it.

-}

import Array exposing (Array)
import Dict exposing (Dict)
import Json.Decode as D
import Kg.Assemble as Assemble exposing (ConceptSpec)
import Kg.Build as Build
import Kg.Context exposing (Context)
import Kg.Facts exposing (FileFacts(..))
import Kg.Fs as Fs
import Kg.Git as Git
import Kg.Graph exposing (Graph)
import Kg.History as History exposing (History)
import Kg.Link as Link exposing (PackageKernels)
import Kg.Replay as Replay
import Kg.Search.Bm25 as Bm25
import Kg.Search.Chunks as Chunks exposing (Chunk)
import Kg.Search.Tokens as Tokens
import Kg.Sha256 as Sha256
import Kg.Snapshot as Snapshot exposing (Base, Snapshot)
import Kg.Stages as Stages
import Set
import Task exposing (Task)
import Time


type alias Progress =
    String -> Task String ()


packagesHash : PackageKernels -> String
packagesHash packages =
    Dict.keys packages |> List.map (\( a, b ) -> a ++ "@" ++ b) |> String.join "," |> Sha256.short 16


conceptsHash : List ConceptSpec -> String
conceptsHash concepts =
    concepts
        |> List.map (\c -> String.join "\u{0001}" ([ c.slug, c.name, c.summary ] ++ c.aliases ++ List.map (\l -> l.node ++ "=" ++ l.role) c.links))
        |> String.join "\u{0002}"
        |> Sha256.short 16


{-| `kg/knowledge/concepts.json`, next to the kg binary's directory. -}
loadConcepts : String -> Task x (List ConceptSpec)
loadConcepts kgHome =
    Fs.readTextMaybe (kgHome ++ "/knowledge/concepts.json")
        |> Task.map
            (\text ->
                text
                    |> Maybe.andThen (D.decodeString (D.list conceptDecoder) >> Result.toMaybe)
                    |> Maybe.withDefault []
            )


conceptDecoder : D.Decoder ConceptSpec
conceptDecoder =
    D.map5 ConceptSpec
        (D.field "slug" D.string)
        (D.field "name" D.string)
        (D.oneOf [ D.field "aliases" (D.list D.string), D.succeed [] ])
        (D.oneOf [ D.field "summary" D.string, D.succeed "" ])
        (D.oneOf [ D.field "links" (D.list (D.map2 (\n r -> { node = n, role = r }) (D.field "node" D.string) (D.field "role" D.string))), D.succeed [] ])


type alias Indexed =
    { graph : Graph, chunks : List Chunk, bm25 : Bm25.Index, files : Dict String FileFacts }


{-| Links a tree (path → blob) whole, from cached facts, and indexes it. -}
indexTree : Context -> PackageKernels -> List ConceptSpec -> Progress -> Maybe ( List Chunk, Bm25.Index ) -> Dict String String -> Task String Indexed
indexTree ctx packages concepts progress previous tree =
    let
        pairs =
            Dict.toList tree |> List.filter (\( p, _ ) -> Build.needsFacts p) |> List.map (\( p, b ) -> ( b, p ))
    in
    stage progress "facts checked" (Build.ensureFacts ctx progress pairs)
        |> Task.andThen (\_ -> stage progress "facts loaded" (Build.loadFacts ctx pairs))
        |> Task.andThen (\byBlob -> indexFacts progress packages concepts previous tree byBlob)


indexFacts : Progress -> PackageKernels -> List ConceptSpec -> Maybe ( List Chunk, Bm25.Index ) -> Dict String String -> Dict String FileFacts -> Task String Indexed
indexFacts progress packages concepts previous tree byBlob =
    let
        files =
            Dict.toList tree
                |> List.filterMap (\( p, b ) -> Dict.get b byBlob |> Maybe.map (\f -> ( p, f )))
                |> Dict.fromList

        moduleFiles =
            Dict.filter (\p _ -> Stages.relevant p) files

        pure name f =
            stage progress name (Task.succeed () |> Task.map f)
    in
    pure "module graph linked"
        (\_ ->
            Link.modules
                { files = moduleFiles
                , cpp =
                    Dict.foldl
                        (\p f acc ->
                            case f of
                                CppFile c ->
                                    Dict.insert p (Link.prepare c) acc

                                _ ->
                                    acc
                        )
                        Dict.empty
                        moduleFiles
                , packages = packages
                }
        )
        |> Task.andThen (\mg -> pure "graph assembled" (\_ -> Assemble.assemble mg files concepts))
        |> Task.andThen (\graph -> pure "chunks made" (\_ -> ( graph, Chunks.withHashes (Maybe.map Tuple.first previous) (Chunks.build graph files) )))
        |> Task.andThen
            (\( graph, chunks ) ->
                pure "keyword index built" (\_ -> keywordIndex previous chunks)
                    |> Task.map (\bm25 -> { graph = graph, chunks = chunks, bm25 = bm25, files = files })
            )


{-| The keyword index, built afresh, or from the previous one when most chunks
are unchanged.
-}
keywordIndex : Maybe ( List Chunk, Bm25.Index ) -> List Chunk -> Bm25.Index
keywordIndex previous chunks =
    case previous of
        Nothing ->
            Bm25.build (List.map (\c -> ( c.id, Tokens.tokenize c.text )) chunks)

        Just ( oldChunks, oldIndex ) ->
            let
                oldIds =
                    List.foldl (\c d -> Dict.insert ( c.node, c.text ) c.id d) Dict.empty oldChunks

                reused =
                    Array.fromList (List.map (\c -> Dict.get ( c.node, c.text ) oldIds) chunks)

                fresh =
                    chunks |> List.filter (\c -> Array.get c.id reused |> Maybe.andThen identity |> (==) Nothing) |> List.map (\c -> ( c.id, Tokens.tokenize c.text ))
            in
            if List.length fresh * 2 > List.length chunks then
                Bm25.build (List.map (\c -> ( c.id, Tokens.tokenize c.text )) chunks)

            else
                Bm25.rebuild oldIndex reused fresh


{-| Runs a task and reports how long it took, when ECO_KG_TIMING is set. -}
stage : Progress -> String -> Task String a -> Task String a
stage progress name task =
    Time.now
        |> Task.andThen
            (\t0 ->
                task
                    |> Task.andThen
                        (\a ->
                            Time.now
                                |> Task.andThen (\t1 -> progress ("  " ++ name ++ ": " ++ String.fromInt (Time.posixToMillis t1 - Time.posixToMillis t0) ++ " ms"))
                                |> Task.map (\_ -> a)
                        )
            )


treeAt : Context -> String -> Task String (Dict String String)
treeAt ctx commit =
    Git.lsTree ctx.worktree commit Stages.logPaths


{-| The replay's state rebuilt from a snapshot's base, with facts from the cache. -}
stateFrom : Context -> Base -> History -> Task String Replay.State
stateFrom ctx base history =
    let
        pairs =
            Dict.toList base.shaOf |> List.map (\( p, b ) -> ( b, p ))

        newestFirst d =
            Dict.map (\_ l -> List.reverse l) d
    in
    Build.ensureFacts ctx (\_ -> Task.succeed ()) pairs
        |> Task.andThen (\_ -> Build.loadFacts ctx pairs)
        |> Task.map
            (\byBlob ->
                let
                    files =
                        Dict.toList base.shaOf |> List.filterMap (\( p, b ) -> Dict.get b byBlob |> Maybe.map (\f -> ( p, f ))) |> Dict.fromList

                    init =
                        Replay.init
                in
                { init
                    | files = files
                    , shaOf = base.shaOf
                    , cpp =
                        Dict.foldl
                            (\p f acc ->
                                case f of
                                    CppFile c ->
                                        Dict.insert p (Link.prepare c) acc

                                    _ ->
                                        acc
                            )
                            Dict.empty
                            files
                    , prose = base.prose
                    , prevFileNode = base.fileNode
                    , liveNodes = base.liveNodes
                    , history = { lives = newestFirst history.lives, renames = newestFirst history.renames, edits = newestFirst history.edits, coChange = history.coChange }
                    , atlas = False
                }
            )


baseOf : Replay.State -> Base
baseOf st =
    { shaOf = st.shaOf, prose = st.prose, fileNode = st.prevFileNode, liveNodes = st.liveNodes }


{-| The base at a commit, rebuilt from its tree: its files, linked. -}
baseAt : Context -> PackageKernels -> String -> Task String Base
baseAt ctx packages commit =
    treeAt ctx commit
        |> Task.andThen
            (\tree ->
                let
                    shaOf =
                        Dict.filter (\p _ -> Stages.relevant p) tree

                    pairs =
                        Dict.toList shaOf |> List.map (\( p, b ) -> ( b, p ))
                in
                Build.ensureFacts ctx (\_ -> Task.succeed ()) pairs
                    |> Task.andThen (\_ -> Build.loadFacts ctx pairs)
                    |> Task.map
                        (\byBlob ->
                            let
                                files =
                                    Dict.toList shaOf |> List.filterMap (\( p, b ) -> Dict.get b byBlob |> Maybe.map (\f -> ( p, f ))) |> Dict.fromList

                                cpp =
                                    Dict.foldl (\p f acc -> case f of
                                        CppFile c -> Dict.insert p (Link.prepare c) acc
                                        _ -> acc) Dict.empty files

                                mg =
                                    Link.modules { files = files, cpp = cpp, packages = packages }
                            in
                            { shaOf = shaOf
                            , prose = Dict.filter (\p _ -> Replay.proseNodeId p /= Nothing) tree
                            , fileNode = mg.fileNode
                            , liveNodes = Set.fromList (Dict.keys mg.nodes)
                            }
                        )
            )


finishAt : Context -> PackageKernels -> List ConceptSpec -> Progress -> Maybe ( List Chunk, Bm25.Index ) -> String -> Base -> History -> Task String Snapshot
finishAt ctx packages concepts progress previous head base history =
    treeAt ctx head
        |> Task.andThen (indexTree ctx packages concepts progress previous)
        |> Task.andThen
            (\ix ->
                Time.now
                    |> Task.map
                        (\now ->
                            { header =
                                { worktree = ctx.worktree
                                , commit = head
                                , packages = packagesHash packages
                                , model = ctx.model
                                , dirty = ""
                                , concepts = conceptsHash concepts
                                , builtAt = Time.posixToMillis now
                                }
                            , base = base
                            , history = history
                            , graph = ix.graph
                            , chunks = ix.chunks
                            , bm25 = ix.bm25
                            }
                        )
            )


{-| A full build from nothing: replays the whole history. -}
build : Context -> PackageKernels -> List ConceptSpec -> Progress -> Task String Snapshot
build ctx packages concepts progress =
    Git.head ctx.worktree
        |> Task.andThen
            (\head ->
                Git.log ctx.worktree head Stages.logPaths
                    |> Task.andThen
                        (\commits ->
                            let
                                init =
                                    Replay.init
                            in
                            Build.replayFrom ctx packages progress { init | atlas = False } Array.empty commits
                        )
                    |> Task.andThen
                        (\r ->
                            finishAt ctx packages concepts progress Nothing head (baseOf r.state) (History.fromReplay r.commits r.state.history)
                        )
            )


{-| Brings a snapshot up to HEAD; Nothing when it already is. -}
update : Context -> PackageKernels -> List ConceptSpec -> Progress -> Maybe Snapshot -> Task String (Maybe Snapshot)
update ctx packages concepts progress existing =
    Git.head ctx.worktree
        |> Task.andThen
            (\head ->
                case existing of
                    Nothing ->
                        build ctx packages concepts progress |> Task.map Just

                    Just snap ->
                        if snap.header.commit == head && snap.header.packages == packagesHash packages && snap.header.concepts == conceptsHash concepts then
                            Task.succeed Nothing

                        else if snap.header.commit == head && snap.header.packages == packagesHash packages then
                            -- only the curated concepts changed: link and index again, no replay
                            finishAt ctx packages concepts progress (Just ( snap.chunks, snap.bm25 )) head snap.base snap.history |> Task.map Just

                        else if snap.header.packages /= packagesHash packages || snap.history.lastIndexed == "" then
                            build ctx packages concepts progress |> Task.map Just

                        else
                            Git.isAncestor ctx.worktree snap.history.lastIndexed head
                                |> Task.andThen
                                    (\ancestor ->
                                        if ancestor then
                                            continueFrom ctx packages concepts progress (Just ( snap.chunks, snap.bm25 )) head snap.history.lastIndexed snap.base snap.history

                                        else
                                            Git.mergeBase ctx.worktree snap.history.lastIndexed head
                                                |> Task.andThen (\mb -> Git.git ctx.worktree ([ "log", "-1", "--first-parent", "--format=%H", mb, "--" ] ++ Stages.logPaths) |> Task.map String.trim)
                                                |> Task.andThen
                                                    (\base ->
                                                        let
                                                            keep =
                                                                indexOfCommit base snap.history
                                                        in
                                                        case keep of
                                                            Nothing ->
                                                                build ctx packages concepts progress

                                                            Just k ->
                                                                progress ("history rewritten: truncating to the merge base " ++ String.left 10 base)
                                                                    |> Task.andThen (\_ -> baseAt ctx packages base)
                                                                    |> Task.andThen (\b -> continueFrom ctx packages concepts progress (Just ( snap.chunks, snap.bm25 )) head base b (History.truncateTo (k + 1) snap.history))
                                                    )
                                    )
                                |> Task.map Just
            )


{-| The index of a commit in the history; for a commit that touched none of
kg's paths, the last indexed commit before it.
-}
indexOfCommit : String -> History -> Maybe Int
indexOfCommit hash history =
    Array.toIndexedList history.commits
        |> List.filter (\( _, c ) -> c.hash == hash)
        |> List.head
        |> Maybe.map Tuple.first


continueFrom : Context -> PackageKernels -> List ConceptSpec -> Progress -> Maybe ( List Chunk, Bm25.Index ) -> String -> String -> Base -> History -> Task String Snapshot
continueFrom ctx packages concepts progress previous head from base history =
    stateFrom ctx base history
        |> Task.andThen
            (\state ->
                Git.log ctx.worktree (from ++ ".." ++ head) Stages.logPaths
                    |> Task.andThen (\commits -> Build.replayFrom ctx packages progress state history.commits commits)
            )
        |> Task.andThen
            (\r ->
                let
                    h =
                        History.fromReplay r.commits r.state.history
                in
                finishAt ctx packages concepts progress previous head (baseOf r.state) h
            )


{-| A snapshot rebuilt at a given commit, for the determinism check. -}
reindexAt : Context -> PackageKernels -> List ConceptSpec -> Progress -> String -> Task String Snapshot
reindexAt ctx packages concepts progress commit =
    Git.log ctx.worktree commit Stages.logPaths
        |> Task.andThen
            (\commits ->
                let
                    init =
                        Replay.init
                in
                Build.replayFrom ctx packages progress { init | atlas = False } Array.empty commits
            )
        |> Task.andThen (\r -> finishAt ctx packages concepts progress Nothing commit (baseOf r.state) (History.fromReplay r.commits r.state.history))
