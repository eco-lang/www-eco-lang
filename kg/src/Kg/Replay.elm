module Kg.Replay exposing
    ( State, Recorder, HistoryAcc, init, step, CommitInput
    , proseNodeId
    )

{-| The replay of the main line, one commit at a time (§10.1 of the plan): a
port of `main` in `script/atlas-graph.py` (deleted once kg matched its output; see git history), recording both the atlas frames
(§17) and the history the knowledge graph keeps (§10.2).

Pure: the IO driver hands each commit over with the facts of the blobs it
changed.

-}

import Array exposing (Array)
import Dict exposing (Dict)
import Kg.Facts exposing (FileFacts(..))
import Kg.Git exposing (Change, Commit)
import Kg.Layout as Layout exposing (Geometry, Layout)
import Kg.Link as Link exposing (ModuleGraph)
import Kg.PathUtil as P
import Kg.Stages as Stages
import Set exposing (Set)


type alias CommitInput =
    { index : Int, commit : Commit, facts : Dict String FileFacts }


{-| What the atlas needs, by uid and frame. Lists are newest first. -}
type alias Recorder =
    { frames : List ( String, Int, String )
    , frameCount : Int
    , tracks : Dict Int (List ( Int, Int, Int ))
    , infos : Dict Int (List ( Int, ( Int, String ), ( String, String ) ))
    , lives : Dict Int (List Int)
    , edits : Dict Int (List Int)
    , edgeLives : Dict ( Int, Int ) (List Int)
    , stageTracks : Dict String (List (List Int))
    , world : List (List Int)
    , kernelSections : List ( Int, List ( ( String, Int, Int ), List ( String, Int ) ) )
    , lastPos : Dict Int ( Int, Int )
    , lastInfo : Dict Int ( Int, ( String, String, String ) )
    , lastEdges : Set ( Int, Int )
    , lastGeo : Dict String ( ( Int, Int ), ( Int, Int ) )
    }


{-| What the knowledge graph keeps, by node id and commit index. Lists are
newest first.
-}
type alias HistoryAcc =
    { lives : Dict String (List Int)
    , renames : Dict String (List ( Int, String ))
    , edits : Dict String (List Int)
    , coChange : Dict ( String, String ) Int
    }


type alias State =
    { files : Dict String FileFacts
    , shaOf : Dict String String
    , cpp : Dict String Link.Prepared
    , prose : Dict String String
    , layout : Layout
    , prevFileNode : Dict String String
    , graph : ModuleGraph
    , rec : Recorder
    , history : HistoryAcc
    , liveNodes : Set String
    , touchedCommits : Int
    , atlas : Bool
    }


init : State
init =
    { files = Dict.empty
    , shaOf = Dict.empty
    , cpp = Dict.empty
    , prose = Dict.empty
    , layout = Layout.empty
    , prevFileNode = Dict.empty
    , graph = { nodes = Dict.empty, edges = Set.empty, fileNode = Dict.empty, programs = Set.empty, kernelSources = Link.emptyKernelSources }
    , rec =
        { frames = []
        , frameCount = 0
        , tracks = Dict.empty
        , infos = Dict.empty
        , lives = Dict.empty
        , edits = Dict.empty
        , edgeLives = Dict.empty
        , stageTracks = Dict.empty
        , world = []
        , kernelSections = []
        , lastPos = Dict.empty
        , lastInfo = Dict.empty
        , lastEdges = Set.empty
        , lastGeo = Dict.empty
        }
    , history = { lives = Dict.empty, renames = Dict.empty, edits = Dict.empty, coChange = Dict.empty }
    , liveNodes = Set.empty
    , touchedCommits = 0
    , atlas = True
    }


{-| The node id of a prose file: a plan, or a design doc, or THEORY.md. -}
proseNodeId : String -> Maybe String
proseNodeId path =
    if String.startsWith "plans/" path && String.endsWith ".md" path && List.length (String.split "/" path) == 2 then
        Just ("plan:" ++ P.stripExtension (P.basename path))

    else if (String.startsWith "design_docs/" path && String.endsWith ".md" path) || path == "THEORY.md" then
        Just ("doc:" ++ path)

    else if path == "design_docs/invariants.csv" then
        Just "doc:design_docs/invariants.csv"

    else
        Nothing


push : comparable -> a -> Dict comparable (List a) -> Dict comparable (List a)
push k v d =
    Dict.update k (\l -> Just (v :: Maybe.withDefault [] l)) d


step : Link.PackageKernels -> CommitInput -> State -> State
step packages input state0 =
    let
        commit =
            input.commit

        t =
            commit.time

        -- prose: tracked for the knowledge graph's history only
        ( prose, proseTouched ) =
            List.foldl
                (\c ( pr, touched ) ->
                    let
                        afterOld =
                            if (c.status == 'D' || c.status == 'R') && Dict.member c.old pr then
                                ( Dict.remove c.old pr, c.old :: touched )

                            else
                                ( pr, touched )
                    in
                    if c.status /= 'D' && proseNodeId c.new /= Nothing then
                        ( Dict.insert c.new c.blob (Tuple.first afterOld), c.new :: Tuple.second afterOld )

                    else
                        afterOld
                )
                ( state0.prose, [] )
                commit.changes

        proseEdits =
            List.filterMap proseNodeId proseTouched |> Set.fromList

        -- the module graph's files
        apply c ( st, renamedPaths, touched ) =
            let
                ( st1, touched1 ) =
                    if (c.status == 'D' || c.status == 'R') && Dict.member c.old st.files then
                        ( { st | files = Dict.remove c.old st.files, shaOf = Dict.remove c.old st.shaOf, cpp = Dict.remove c.old st.cpp }, True )

                    else
                        ( st, touched )

                renamed1 =
                    if c.status == 'R' then
                        renamedPaths ++ [ ( c.old, c.new ) ]

                    else
                        renamedPaths
            in
            if c.status /= 'D' && Stages.relevant c.new && Dict.get c.new st1.shaOf /= Just c.blob then
                let
                    facts =
                        Dict.get c.blob input.facts |> Maybe.withDefault (Unparsed "missing")

                    cpp =
                        case facts of
                            CppFile f ->
                                Dict.insert c.new (Link.prepare f) st1.cpp

                            _ ->
                                Dict.remove c.new st1.cpp
                in
                ( { st1 | files = Dict.insert c.new facts st1.files, shaOf = Dict.insert c.new c.blob st1.shaOf, cpp = cpp }, renamed1, True )

            else
                ( st1, renamed1, touched1 )

        ( state1, renamedPaths0, touchedAny ) =
            List.foldl apply ( { state0 | prose = prose }, [], False ) commit.changes

        withProseEdits st =
            { st | history = { lives = st.history.lives, renames = st.history.renames, coChange = st.history.coChange, edits = Set.foldl (\id e -> push id input.index e) st.history.edits proseEdits } }
    in
    if not touchedAny then
        withProseEdits state1

    else
        let
            graph =
                Link.modules { files = state1.files, cpp = state1.cpp, packages = packages }

            before =
                state1.prevFileNode

            renamed =
                renamedPaths0
                    |> List.filterMap
                        (\( old, new ) ->
                            case ( Dict.get old before, Dict.get new graph.fileNode ) of
                                ( Just a, Just b ) ->
                                    if a /= b then
                                        Just ( a, b )

                                    else
                                        Nothing

                                _ ->
                                    Nothing
                        )

            -- the atlas also lists the kernel libraries' files in full
            nodeInfos =
                Dict.union graph.nodes graph.kernelSources.nodes
                    |> Dict.map (\_ n -> { id = n.id, label = n.label, lang = n.lang, stage = n.stage, path = n.path, group = n.group })

            edgePairs =
                Set.union (Link.pairs graph) (Link.kernelPairs graph)

            ( layout, geo, pos ) =
                if state1.atlas then
                    Layout.step nodeInfos edgePairs (dedupeRenames renamed) state1.layout

                else
                    ( state1.layout, noGeometry, Dict.empty )

            touchedIds =
                commit.changes
                    |> List.filterMap
                        (\c ->
                            if c.status == 'D' then
                                Dict.get c.old before

                            else
                                Dict.get c.new graph.fileNode
                        )

            touchedKernelSources =
                commit.changes
                    |> List.filterMap
                        (\c ->
                            if c.status == 'D' then
                                Nothing

                            else
                                Dict.get c.new graph.kernelSources.fileNode
                        )

            -- atlas edits, by uid, as times
            recEdits =
                List.foldl
                    (\id acc ->
                        case Layout.uidOf id layout of
                            Just u ->
                                case Dict.get u acc |> Maybe.andThen List.head of
                                    Just last ->
                                        if last == t then
                                            acc

                                        else
                                            push u t acc

                                    Nothing ->
                                        push u t acc

                            Nothing ->
                                acc
                    )
                    state1.rec.edits
                    (touchedIds ++ touchedKernelSources)

            rec =
                if state1.atlas then
                    let
                        rec0 =
                            state1.rec
                    in
                    record commit layout geo pos edgePairs { rec0 | edits = recEdits }

                else
                    state1.rec

            -- knowledge-graph history
            nowNodes =
                Dict.keys graph.nodes |> Set.fromList

            changedLife =
                Set.union (Set.diff nowNodes state1.liveNodes) (Set.diff state1.liveNodes nowNodes)

            liveIds =
                Set.fromList (List.filter (\id -> Dict.member id graph.nodes || List.member id (List.map Tuple.first renamed)) touchedIds)

            editedIds =
                Set.union proseEdits (Set.filter (\id -> Dict.member id graph.nodes) liveIds)

            moduleTouched =
                Set.filter (\id -> Dict.member id graph.nodes) liveIds |> Set.toList

            coChange =
                if List.length moduleTouched > 50 then
                    state1.history.coChange

                else
                    List.foldl
                        (\a acc ->
                            List.foldl
                                (\b acc2 ->
                                    if a < b then
                                        Dict.update ( a, b ) (\v -> Just (Maybe.withDefault 0 v + 1)) acc2

                                    else
                                        acc2
                                )
                                acc
                                moduleTouched
                        )
                        state1.history.coChange
                        moduleTouched

            history =
                { lives = Set.foldl (\id l -> push id input.index l) state1.history.lives changedLife
                , renames = List.foldl (\( a, b ) r -> push b ( input.index, a ) r) state1.history.renames renamed
                , edits = Set.foldl (\id e -> push id input.index e) state1.history.edits editedIds
                , coChange = coChange
                }
        in
        { state1
            | layout = layout
            , prevFileNode = graph.fileNode
            , graph = graph
            , rec = rec
            , history = history
            , liveNodes = nowNodes
            , touchedCommits = state1.touchedCommits + 1
        }


noGeometry : Geometry
noGeometry =
    { stages = Dict.empty, elmEnd = 0, cppGx = 0, foundTop = 0, foundRows = 0, hasElmFound = False, hasCppFound = False, sections = [], kernTop = 0, kernRows = 0, kernCols = 0, kernSections = [], kernBands = [], cols = 0, rows = 0 }


{-| Python builds `renamed` as a dict, so a later rename of the same old node
replaces an earlier one, keeping the earlier one's place.
-}
dedupeRenames : List ( String, String ) -> List ( String, String )
dedupeRenames rs =
    List.foldl
        (\( a, b ) acc ->
            if List.any (\( x, _ ) -> x == a) acc then
                List.map
                    (\( x, y ) ->
                        if x == a then
                            ( x, b )

                        else
                            ( x, y )
                    )
                    acc

            else
                acc ++ [ ( a, b ) ]
        )
        []
        rs


record : Commit -> Layout -> Geometry -> Dict Int ( Int, Int ) -> Set ( String, String ) -> Recorder -> Recorder
record commit layout geo pos edgePairs rec =
    let
        uidEdges =
            Set.foldl
                (\( a, b ) acc ->
                    case ( Layout.uidOf a layout, Layout.uidOf b layout ) of
                        ( Just ua, Just ub ) ->
                            Set.insert ( ua, ub ) acc

                        _ ->
                            acc
                )
                Set.empty
                edgePairs

        infoNow =
            Dict.map (\_ i -> ( Stages.stageIndex i.stage, ( i.id, i.label, i.path ) )) layout.info

        stageNow =
            Dict.map (\_ s -> ( ( s.gx, s.gw ), ( s.gy, s.gh ) )) geo.stages

        sectionGx k =
            List.drop k geo.sections |> List.head |> Maybe.map .gx |> Maybe.withDefault 0

        worldNow =
            [ geo.cols
            , geo.rows
            , geo.foundTop
            , geo.foundRows
            , if geo.hasElmFound then
                geo.elmEnd

              else
                0
            , if geo.hasCppFound then
                geo.cppGx

              else
                0
            , if geo.hasCppFound then
                geo.cols - geo.cppGx

              else
                0
            , geo.kernTop
            , geo.kernRows
            , geo.kernCols
            , sectionGx 0 - geo.cppGx
            , sectionGx 1 - geo.cppGx
            ]

        lastWorld =
            List.head rec.world |> Maybe.map (List.drop 1)

        kernelNow =
            List.map (\b -> ( ( b.title, b.gx, b.cols ), List.map (\sec -> ( sec.title, sec.gx )) b.sections )) geo.kernBands

        lastKernel =
            List.head rec.kernelSections |> Maybe.map Tuple.second |> Maybe.withDefault []
    in
    if pos == rec.lastPos && infoNow == rec.lastInfo && uidEdges == rec.lastEdges && stageNow == rec.lastGeo && lastWorld == Just worldNow && kernelNow == lastKernel then
        rec

    else
        let
            f =
                rec.frameCount

            allUids =
                Set.union (Set.fromList (Dict.keys pos)) (Set.fromList (Dict.keys rec.lastPos))

            ( lives, tracks, infos ) =
                Set.foldl
                    (\u ( l, tr, inf ) ->
                        let
                            was =
                                Dict.member u rec.lastPos

                            now =
                                Dict.member u pos

                            l2 =
                                if now /= was then
                                    push u f l

                                else
                                    l

                            tr2 =
                                case Dict.get u pos of
                                    Just ( x, y ) ->
                                        if not was || Dict.get u rec.lastPos /= Just ( x, y ) then
                                            push u ( f, x, y ) tr

                                        else
                                            tr

                                    Nothing ->
                                        tr

                            inf2 =
                                case Dict.get u infoNow of
                                    Just ( si, ( id, label, path ) ) ->
                                        if now && (not was || Dict.get u rec.lastInfo /= Just ( si, ( id, label, path ) )) then
                                            push u ( f, ( si, id ), ( label, path ) ) inf

                                        else
                                            inf

                                    Nothing ->
                                        inf
                        in
                        ( l2, tr2, inf2 )
                    )
                    ( rec.lives, rec.tracks, rec.infos )
                    allUids

            changedEdges =
                Set.union (Set.diff uidEdges rec.lastEdges) (Set.diff rec.lastEdges uidEdges)

            stageKeys =
                Set.union (Set.fromList (Dict.keys stageNow)) (Set.fromList (Dict.keys rec.lastGeo))

            stageTracks =
                Set.foldl
                    (\k st ->
                        if Dict.get k stageNow /= Dict.get k rec.lastGeo then
                            case Dict.get k stageNow of
                                Just ( ( a, b ), ( c, d ) ) ->
                                    push k [ f, a, b, c, d ] st

                                Nothing ->
                                    push k [ f ] st

                        else
                            st
                    )
                    rec.stageTracks
                    stageKeys
        in
        { rec
            | frames = ( String.left 10 commit.hash, commit.time, commit.subject ) :: rec.frames
            , frameCount = f + 1
            , lives = lives
            , tracks = tracks
            , infos = infos
            , edgeLives = Set.foldl (\e el -> push e f el) rec.edgeLives changedEdges
            , stageTracks = stageTracks
            , world =
                if lastWorld /= Just worldNow then
                    (f :: worldNow) :: rec.world

                else
                    rec.world
            , kernelSections =
                if kernelNow /= lastKernel then
                    ( f, kernelNow ) :: rec.kernelSections

                else
                    rec.kernelSections
            , lastPos = pos
            , lastInfo = infoNow
            , lastEdges = uidEdges
            , lastGeo = stageNow
        }
