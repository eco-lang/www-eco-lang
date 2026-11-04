module Atlas.Graph exposing
    ( History, Frame, data, first, last, frameAt
    , Graph, World, Stage, Section, KernelBand, Node
    , at, node, matches
    )

{-| The compiler's dependency graph through its history, as `kg export --atlas` (`npm run atlas`) writes it to
`content/atlas/history.json`: every Elm module and C++ component there has ever been, the stage of the pipeline it was
in, and its place on the grid, in cells, at each commit that changed any of that.

`at` gives the atlas at a moment of the history, as a `Graph`. A change made by a commit is not shown all at once: over
a short while after the commit, what moved slides from its old place to its new one, and what arrived or left fades in
or out.

@docs History, Frame, data, first, last, frameAt
@docs Graph, World, Stage, Section, KernelBand, Node
@docs at, node, matches

-}

import Array exposing (Array)
import BackendTask exposing (BackendTask)
import BackendTask.File
import Dict exposing (Dict)
import FatalError exposing (FatalError)
import Json.Decode as Decode exposing (Decoder)



-- HISTORY


{-| The history: the commits that changed the graph, oldest first, and what each node, link, stage and the world as a
whole was from each one on.
-}
type History
    = History HistoryData


type alias HistoryData =
    { frames : Array Frame
    , stages : List StageInfo
    , branchFrom : String
    , branchTo : String
    , sections : List String
    , nodeW : Int
    , nodeH : Int
    , nodes : Array Track
    , edges : List EdgeTrack
    , stageTracks : Dict String (Array ( Int, Maybe Box ))
    , world : Array ( Int, WorldBox )
    , kernelBands : Array ( Int, List KernelBand )
    }


{-| A commit: its short hash, its time in seconds since 1970, and its subject.
-}
type alias Frame =
    { hash : String
    , time : Int
    , subject : String
    }


type alias StageInfo =
    { key : String
    , title : String
    , blurb : String
    , lang : String
    , row : Int
    }


{-| A node's history. `life` lists the frames it arrived and left in, alternately; `pos` its place from each frame
it moved in and `info` what it was called from each frame that changed. `edits` has the time of every commit that
touched its files, in seconds after the first frame; most of those commits change nothing else.
-}
type alias Track =
    { lang : String
    , life : Array Int
    , pos : Array { frame : Int, gx : Int, gy : Int }
    , info : Array Info
    , edits : Array Float
    }


type alias Info =
    { frame : Int
    , stage : Int
    , id : String
    , label : String
    , path : String
    }


type alias EdgeTrack =
    { from : Int
    , to : Int
    , life : Array Int
    }


type alias Box =
    { gx : Float, gw : Float, gy : Float, gh : Float }


type alias WorldBox =
    { cols : Float
    , rows : Float
    , foundTop : Float
    , foundRows : Float
    , foundCols : Float
    , cppFoundCol : Float
    , cppFoundCols : Float
    , kernTop : Float
    , kernRows : Float
    , kernCols : Float
    , sectionOffsets : List Float
    }


{-| Read the history.
-}
data : BackendTask FatalError History
data =
    BackendTask.File.jsonFile (Decode.map History decoder) "content/atlas/history.json"
        |> BackendTask.allowFatal


{-| When the history starts and ends: the times of its first and last commits.
-}
first : History -> Float
first (History history) =
    Array.get 0 history.frames |> Maybe.map (.time >> toFloat) |> Maybe.withDefault 0


{-| -}
last : History -> Float
last (History history) =
    Array.get (Array.length history.frames - 1) history.frames |> Maybe.map (.time >> toFloat) |> Maybe.withDefault 0


{-| The last commit at or before a time, if any.
-}
frameAt : History -> Float -> Maybe Frame
frameAt (History history) t =
    Array.get (frameIndex history t) history.frames


frameIndex : HistoryData -> Float -> Int
frameIndex history t =
    -- the number of frames at or before t, less one
    countAtOrBefore (\f -> toFloat f.time <= t) history.frames - 1


{-| How many elements at the start of a sorted array pass a test that, once it fails, fails for the rest.
-}
countAtOrBefore : (a -> Bool) -> Array a -> Int
countAtOrBefore test arr =
    let
        go lo hi =
            if lo >= hi then
                lo

            else
                let
                    mid =
                        (lo + hi) // 2
                in
                case Array.get mid arr of
                    Just a ->
                        if test a then
                            go (mid + 1) hi

                        else
                            go lo mid

                    Nothing ->
                        lo
    in
    go 0 (Array.length arr)


{-| The last entry of a track at or before a frame.
-}
latest : Int -> (a -> Int) -> Array a -> Maybe a
latest k frameOf arr =
    Array.get (countAtOrBefore (\a -> frameOf a <= k) arr - 1) arr


alive : Int -> Array Int -> Bool
alive k life =
    modBy 2 (countAtOrBefore (\f -> f <= k) life) == 1



-- THE ATLAS AT A MOMENT


{-| The atlas at one moment. `nodes` has every node there has ever been, by index; those not there have an opacity of

1.  `out` lists what each node imports and `inn` what imports it, both by index and sorted by label. `index` finds a
    node that is there by its id.

-}
type alias Graph =
    { world : World
    , stages : List Stage
    , nodes : Array Node
    , edgeCount : Int
    , out : Array (List Int)
    , inn : Array (List Int)
    , index : Dict String Int
    }


{-| The size of the world in cells, where its parts are, and the footprint of a node. The foundations have no columns
before the first module that belongs in them.
-}
type alias World =
    { cols : Float
    , rows : Float
    , branchFrom : String
    , branchTo : String
    , foundTop : Float
    , foundRows : Float
    , foundCols : Float
    , foundOpacity : Float
    , cppFoundCol : Float
    , cppFoundCols : Float
    , cppFoundOpacity : Float
    , cppSections : List Section
    , kernTop : Float
    , kernRows : Float
    , kernCols : Float
    , kernOpacity : Float
    , kernBands : List KernelBand
    , nodeW : Int
    , nodeH : Int
    }


{-| A stage of the pipeline: its footprint, and the row of the pipeline it is in, 0 for the shared front end and the
erased JavaScript path, 1 for the typed path.
-}
type alias Stage =
    { key : String
    , title : String
    , blurb : String
    , lang : String
    , row : Int
    , gx : Float
    , gw : Float
    , gy : Float
    , gh : Float
    , count : Int
    , opacity : Float
    , order : Int
    }


{-| A section of the C++ foundation, and the column it starts on.
-}
type alias Section =
    { title : String
    , gx : Float
    }


{-| A band of kernel sources, one per kernel library: its title, first column, width and a section per kernel.
-}
type alias KernelBand =
    { title : String
    , gx : Float
    , cols : Float
    , sections : List Section
    }


{-| A module or C++ component. `glow` is 1 when a commit has just touched its files, and fades to 0.
-}
type alias Node =
    { index : Int
    , id : String
    , label : String
    , lang : String
    , stage : String
    , stageName : String
    , path : String
    , gx : Float
    , gy : Float
    , opacity : Float
    , glow : Float
    }


{-| The atlas at a time. Each commit's changes ease in over `settle` seconds of history after it. When commits come
close together their changes overlap, each going at its own pace, and add up. A node a commit touches glows, and the
glow fades over `glow` seconds of history; another commit touching it lights it up again.
-}
at : History -> { settle : Float, glow : Float } -> Float -> Graph
at (History history) { settle, glow } t =
    let
        sinceStart =
            t - (Array.get 0 history.frames |> Maybe.map (.time >> toFloat) |> Maybe.withDefault 0)

        k =
            frameIndex history t

        -- every change up to frame m has settled
        m =
            frameIndex history (t - settle)

        settling =
            List.range (m + 1) k
                |> List.map
                    (\j ->
                        ( j
                        , Array.get j history.frames
                            |> Maybe.map (\f -> ease (clamp 0 1 ((t - toFloat f.time) / settle)))
                            |> Maybe.withDefault 1
                        )
                    )

        -- a value as it was at frame m, plus each change since, as far as it has got
        blend f =
            f m + List.foldl (\( j, e ) acc -> acc + (f j - f (j - 1)) * e) 0 settling

        -- whether a track has an entry in a frame still settling
        changing frameOf arr =
            countAtOrBefore (\a -> frameOf a <= k) arr > countAtOrBefore (\a -> frameOf a <= m) arr

        stageKeys =
            List.map .key history.stages ++ [ "foundation", "cppfound", "kernelsrc" ]

        stageKey i =
            List.drop i stageKeys |> List.head |> Maybe.withDefault "foundation"

        world =
            blendWorld history blend k

        nodes =
            Array.indexedMap
                (\u track ->
                    let
                        present j =
                            if alive j track.life then
                                1

                            else
                                0

                        -- where the node is at frame j, or was last, or will first be
                        place j =
                            case latest j .frame track.pos of
                                Just p ->
                                    p

                                Nothing ->
                                    Array.get 0 track.pos |> Maybe.withDefault { frame = 0, gx = 0, gy = 0 }

                        ( ( gx, gy ), opacity ) =
                            if changing identity track.life || changing .frame track.pos then
                                ( ( blend (place >> .gx >> toFloat), blend (place >> .gy >> toFloat) )
                                , clamp 0 1 (blend present)
                                )

                            else
                                ( ( toFloat (place k).gx, toFloat (place k).gy ), present k )

                        i =
                            latest k .frame track.info |> Maybe.withDefault { frame = 0, stage = 0, id = "", label = "", path = "" }

                        st =
                            stageKey i.stage
                    in
                    { index = u
                    , id = i.id
                    , label = i.label
                    , lang = track.lang
                    , stage = st
                    , stageName = stageName history world st gx
                    , path = i.path
                    , gx = gx
                    , gy = gy
                    , opacity = opacity
                    , glow =
                        if opacity > 0 then
                            glowing glow sinceStart track.edits

                        else
                            0
                    }
                )
                history.nodes

        here =
            Array.filter (\n -> n.opacity > 0) nodes

        counts =
            Array.foldl
                (\n d ->
                    if alive k (trackLife history n.index) then
                        Dict.update n.stage (Maybe.withDefault 0 >> (+) 1 >> Just) d

                    else
                        d
                )
                Dict.empty
                here

        stages =
            List.filterMap identity <|
                List.indexedMap
                    (\order s ->
                        let
                            entries =
                                Dict.get s.key history.stageTracks |> Maybe.withDefault Array.empty

                            present j =
                                case latest j Tuple.first entries |> Maybe.andThen Tuple.second of
                                    Just _ ->
                                        1

                                    Nothing ->
                                        0

                            -- the stage's box at frame j, or its last or first one
                            box j =
                                let
                                    boxes =
                                        Array.toList entries |> List.filterMap (\( f, b ) -> Maybe.map (Tuple.pair f) b)
                                in
                                case List.filter (\( f, _ ) -> f <= j) boxes |> List.reverse |> List.head of
                                    Just ( _, b ) ->
                                        b

                                    Nothing ->
                                        List.head boxes |> Maybe.map Tuple.second |> Maybe.withDefault { gx = 0, gw = 0, gy = 0, gh = 0 }

                            opacity =
                                clamp 0 1 (blend present)
                        in
                        if opacity <= 0 then
                            Nothing

                        else if changing Tuple.first entries then
                            Just
                                (stage s
                                    order
                                    { gx = blend (box >> .gx), gw = blend (box >> .gw), gy = blend (box >> .gy), gh = blend (box >> .gh) }
                                    opacity
                                    counts
                                )

                        else
                            Just (stage s order (box k) opacity counts)
                    )
                    history.stages

        edges =
            List.filter (\ed -> alive k ed.life) history.edges

        empty =
            Array.repeat (Array.length nodes) []

        add ( from, to ) arr =
            Array.set from (to :: Maybe.withDefault [] (Array.get from arr)) arr

        byLabel =
            List.sortBy (\i -> Array.get i nodes |> Maybe.map .label |> Maybe.withDefault "")
    in
    { world = world
    , stages = stages
    , nodes = nodes
    , edgeCount = List.length edges
    , out = List.foldl (\ed -> add ( ed.from, ed.to )) empty edges |> Array.map byLabel
    , inn = List.foldl (\ed -> add ( ed.to, ed.from )) empty edges |> Array.map byLabel
    , index = Array.toList here |> List.map (\n -> ( n.id, n.index )) |> Dict.fromList
    }


trackLife : HistoryData -> Int -> Array Int
trackLife history u =
    Array.get u history.nodes |> Maybe.map .life |> Maybe.withDefault Array.empty


stage : StageInfo -> Int -> Box -> Float -> Dict String Int -> Stage
stage s order b opacity counts =
    { key = s.key
    , title = s.title
    , blurb = s.blurb
    , lang = s.lang
    , row = s.row
    , gx = b.gx
    , gw = b.gw
    , gy = b.gy
    , gh = b.gh
    , count = Dict.get s.key counts |> Maybe.withDefault 0
    , opacity = opacity
    , order = order
    }


stageName : HistoryData -> World -> String -> Float -> String
stageName history world key gx =
    if key == "cppfound" then
        world.cppSections
            |> List.filter (\c -> c.gx <= gx)
            |> List.reverse
            |> List.head
            |> Maybe.map (\c -> "C++ foundation · " ++ c.title)
            |> Maybe.withDefault "C++ foundation"

    else if key == "foundation" then
        "Shared foundation"

    else if key == "kernelsrc" then
        case world.kernBands |> List.filter (\b -> b.gx <= gx) |> List.reverse |> List.head of
            Just b ->
                b.sections
                    |> List.filter (\c -> c.gx <= gx)
                    |> List.reverse
                    |> List.head
                    |> Maybe.map (\c -> b.title ++ " · " ++ c.title)
                    |> Maybe.withDefault b.title

            Nothing ->
                "Kernel sources"

    else
        List.filter (\s -> s.key == key) history.stages |> List.head |> Maybe.map .title |> Maybe.withDefault key


{-| The world at a time, given how to blend a value over the frames still settling and the frame the time is in. A
foundation that is not there takes the shape it last had, or will first have, and fades.
-}
blendWorld : HistoryData -> ((Int -> Float) -> Float) -> Int -> World
blendWorld history blend k =
    let
        none =
            { cols = 0, rows = 0, foundTop = 0, foundRows = 0, foundCols = 0, cppFoundCol = 0, cppFoundCols = 0, kernTop = 0, kernRows = 0, kernCols = 0, sectionOffsets = [] }

        boxes =
            Array.toList history.world

        at_ j =
            latest j Tuple.first history.world |> Maybe.map Tuple.second |> Maybe.withDefault none

        -- a part's value at frame j, or the last or first one it had when it was there
        part f j =
            let
                there =
                    List.filter (\( _, w ) -> f w > 0) boxes
            in
            case List.filter (\( g, _ ) -> g <= j) there |> List.reverse |> List.head of
                Just ( _, w ) ->
                    f w

                Nothing ->
                    List.head there |> Maybe.map (Tuple.second >> f) |> Maybe.withDefault 0

        present f j =
            if f (at_ j) > 0 then
                1

            else
                0

        cppGx =
            blend (part .cppFoundCol)
    in
    { cols = blend (at_ >> .cols)
    , rows = blend (at_ >> .rows)
    , branchFrom = history.branchFrom
    , branchTo = history.branchTo
    , foundTop = blend (part .foundTop)
    , foundRows = blend (part .foundRows)
    , foundCols = blend (part .foundCols)
    , foundOpacity = clamp 0 1 (blend (present .foundCols))
    , cppFoundCol = cppGx
    , cppFoundCols = blend (part .cppFoundCols)
    , cppFoundOpacity = clamp 0 1 (blend (present .cppFoundCols))
    , cppSections = List.map2 (\title dx -> { title = title, gx = cppGx + dx }) history.sections (at_ k).sectionOffsets
    , kernTop = blend (part .kernTop)
    , kernRows = blend (part .kernRows)
    , kernCols = blend (part .kernCols)
    , kernOpacity = clamp 0 1 (blend (present .kernCols))
    , kernBands = latest k Tuple.first history.kernelBands |> Maybe.map Tuple.second |> Maybe.withDefault []
    , nodeW = history.nodeW
    , nodeH = history.nodeH
    }


{-| How brightly a node glows, `t` seconds into the history, given the times of its edits.
-}
glowing : Float -> Float -> Array Float -> Float
glowing duration t edits =
    case Array.get (countAtOrBefore (\e -> e <= t) edits - 1) edits of
        Just e ->
            if t - e < duration then
                1 - ease ((t - e) / duration)

            else
                0

        Nothing ->
            0


{-| Slow in, slow out.
-}
ease : Float -> Float
ease p =
    p * p * (3 - 2 * p)


{-| A node by index.
-}
node : Graph -> Int -> Maybe Node
node graph i =
    Array.get i graph.nodes
        |> Maybe.andThen
            (\n ->
                if n.opacity > 0 then
                    Just n

                else
                    Nothing
            )


{-| The nodes there now whose labels contain a search, ignoring case.
-}
matches : Graph -> String -> List Node
matches graph query =
    let
        q =
            String.toLower (String.trim query)
    in
    if q == "" then
        []

    else
        Array.toList graph.nodes |> List.filter (\n -> n.opacity > 0 && String.contains q (String.toLower n.label))



-- DECODING


decoder : Decoder HistoryData
decoder =
    Decode.succeed HistoryData
        |> field "frames" (Decode.array (Decode.map3 Frame (Decode.index 0 Decode.string) (Decode.index 1 Decode.int) (Decode.index 2 Decode.string)))
        |> field "stages"
            (Decode.list
                (Decode.map5 StageInfo
                    (Decode.field "key" Decode.string)
                    (Decode.field "title" Decode.string)
                    (Decode.field "blurb" Decode.string)
                    (Decode.field "lang" Decode.string)
                    (Decode.field "row" Decode.int)
                )
            )
        |> andMap (Decode.field "branch" (Decode.index 0 Decode.string))
        |> andMap (Decode.field "branch" (Decode.index 1 Decode.string))
        |> field "sections" (Decode.list (Decode.field "title" Decode.string))
        |> field "nodeW" Decode.int
        |> field "nodeH" Decode.int
        |> field "nodes" (Decode.array trackDecoder)
        |> field "edges" (Decode.list edgeDecoder)
        |> field "stageTracks" (Decode.dict (Decode.array stageEntryDecoder))
        |> field "world" (Decode.array worldEntryDecoder)
        |> field "kernelBands" (Decode.array kernelBandsDecoder)


{-| `[frame, [[title, gx, cols, [[section title, gx], ...]], ...]]`: the kernel sources bands from that frame on.
-}
kernelBandsDecoder : Decoder ( Int, List KernelBand )
kernelBandsDecoder =
    Decode.map2 Tuple.pair
        (Decode.index 0 Decode.int)
        (Decode.index 1
            (Decode.list
                (Decode.map4 KernelBand
                    (Decode.index 0 Decode.string)
                    (Decode.index 1 Decode.float)
                    (Decode.index 2 Decode.float)
                    (Decode.index 3
                        (Decode.list
                            (Decode.map2 Section
                                (Decode.index 0 Decode.string)
                                (Decode.index 1 Decode.float)
                            )
                        )
                    )
                )
            )
        )


trackDecoder : Decoder Track
trackDecoder =
    Decode.map5 Track
        (Decode.field "lang" Decode.string)
        (Decode.field "life" (Decode.array Decode.int))
        (Decode.field "pos"
            (Decode.array
                (Decode.map3 (\f x y -> { frame = f, gx = x, gy = y })
                    (Decode.index 0 Decode.int)
                    (Decode.index 1 Decode.int)
                    (Decode.index 2 Decode.int)
                )
            )
        )
        (Decode.field "info"
            (Decode.array
                (Decode.map5 Info
                    (Decode.index 0 Decode.int)
                    (Decode.index 1 Decode.int)
                    (Decode.index 2 Decode.string)
                    (Decode.index 3 Decode.string)
                    (Decode.index 4 Decode.string)
                )
            )
        )
        -- the seconds to the first edit, and from each to the next
        (Decode.field "edits" (Decode.list Decode.float |> Decode.map (List.foldl (\gap ( t, ts ) -> ( t + gap, Array.push (t + gap) ts )) ( 0, Array.empty ) >> Tuple.second)))


{-| `[from, to, frame, frame, ...]`: the frames the link appears and goes in, alternately.
-}
edgeDecoder : Decoder EdgeTrack
edgeDecoder =
    Decode.list Decode.int
        |> Decode.andThen
            (\xs ->
                case xs of
                    from :: to :: life ->
                        Decode.succeed { from = from, to = to, life = Array.fromList life }

                    _ ->
                        Decode.fail "a link needs two ends"
            )


{-| `[frame, gx, gw, gy, gh]`, or `[frame]` from when the stage has nothing in it.
-}
stageEntryDecoder : Decoder ( Int, Maybe Box )
stageEntryDecoder =
    Decode.list Decode.float
        |> Decode.andThen
            (\xs ->
                case xs of
                    [ f, gx, gw, gy, gh ] ->
                        Decode.succeed ( round f, Just { gx = gx, gw = gw, gy = gy, gh = gh } )

                    [ f ] ->
                        Decode.succeed ( round f, Nothing )

                    _ ->
                        Decode.fail "a stage entry is [frame] or [frame, gx, gw, gy, gh]"
            )


{-| `[frame, cols, rows, foundTop, foundRows, foundCols, cppFoundCol, cppFoundCols, kernTop, kernRows, kernCols,
section offsets...]`
-}
worldEntryDecoder : Decoder ( Int, WorldBox )
worldEntryDecoder =
    Decode.list Decode.float
        |> Decode.andThen
            (\xs ->
                case xs of
                    f :: cols :: rows :: foundTop :: foundRows :: foundCols :: cppFoundCol :: cppFoundCols :: kernTop :: kernRows :: kernCols :: offsets ->
                        Decode.succeed
                            ( round f
                            , { cols = cols
                              , rows = rows
                              , foundTop = foundTop
                              , foundRows = foundRows
                              , foundCols = foundCols
                              , cppFoundCol = cppFoundCol
                              , cppFoundCols = cppFoundCols
                              , kernTop = kernTop
                              , kernRows = kernRows
                              , kernCols = kernCols
                              , sectionOffsets = offsets
                              }
                            )

                    _ ->
                        Decode.fail "a world entry is too short"
            )


field : String -> Decoder a -> Decoder (a -> b) -> Decoder b
field name d =
    andMap (Decode.field name d)


andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap =
    Decode.map2 (|>)
