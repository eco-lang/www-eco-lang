module Kg.Layout exposing
    ( Layout, NodeInfo, Geometry, StageBox, Section, KernelBand, Pos
    , empty, step, uidOf
    , nodeW, nodeH
    )

{-| Slots for nodes, kept from one commit to the next: a port of the `Layout`
class of `script/atlas-graph.py` (deleted once kg matched its output; see git history) (§17 of the plan).

A stage has a flow of slots for each depth, 0 for the nodes nothing else in the
stage imports, 1 and 2 for the ones further in. A flow runs down a column and
on into the next, `maxRows` slots to a column. The Elm foundation has a stack
of slots per column. A slot holds a node's uid or nothing, a hole left by a
node that has gone.

Two details of the Python matter to the output and are kept: `//` floors, and
the stacks are a dict, so when stacks past the last column are folded into
it, they are taken in the order they were created.

-}

import Array exposing (Array)
import Dict exposing (Dict)
import Kg.Stages as Stages
import Set exposing (Set)


nodeW : Int
nodeW =
    13


nodeH : Int
nodeH =
    3


colPitch : Int
colPitch =
    15


headRows : Int
headRows =
    9


stageGap : Int
stageGap =
    2


minCols : Int
minCols =
    2


maxRows : Int
maxRows =
    24


rowGap : Int
rowGap =
    3


foundHead : Int
foundHead =
    7


cppPerCol : Int
cppPerCol =
    4


{-| Rows of nodes in a column of the kernel sources band. -}
kernPerCol : Int
kernPerCol =
    10


type alias NodeInfo =
    { id : String, label : String, lang : String, stage : String, path : String, group : String }


type Where
    = InFlow ( String, Int )
    | InStack Int
    | InCpp
    | InKernel


type alias Pos =
    ( Int, Int )


type alias Layout =
    { uid : Dict String Int
    , uids : Array String
    , info : Dict Int NodeInfo
    , flows : Dict ( String, Int ) (List (Maybe Int))
    , stacks : Dict Int (List (Maybe Int))
    , stackOrder : List Int
    , where_ : Dict Int Where
    }


type alias StageBox =
    { gx : Int, gw : Int, row : Int, lang : String, gy : Int, gh : Int }


type alias Section =
    { key : String, title : String, gx : Int }


{-| A band of the kernel sources, one per kernel library: its title, first
column, width and sections.
-}
type alias KernelBand =
    { title : String, gx : Int, cols : Int, sections : List Section }


type alias Geometry =
    { stages : Dict String StageBox
    , elmEnd : Int
    , cppGx : Int
    , foundTop : Int
    , foundRows : Int
    , hasElmFound : Bool
    , hasCppFound : Bool
    , sections : List Section
    , kernTop : Int
    , kernRows : Int
    , kernCols : Int
    , kernSections : List Section
    , kernBands : List KernelBand
    , cols : Int
    , rows : Int
    }


empty : Layout
empty =
    { uid = Dict.empty, uids = Array.empty, info = Dict.empty, flows = Dict.empty, stacks = Dict.empty, stackOrder = [], where_ = Dict.empty }


uidOf : String -> Layout -> Maybe Int
uidOf id layout =
    Dict.get id layout.uid


floorDiv : Int -> Int -> Int
floorDiv a b =
    floor (toFloat a / toFloat b)


ceilDiv : Int -> Int -> Int
ceilDiv a b =
    -(floorDiv -a b)


key : Layout -> Int -> ( String, String )
key layout u =
    case Dict.get u layout.info of
        Just i ->
            ( i.group, i.label )

        Nothing ->
            ( "", "" )


setStack : Int -> List (Maybe Int) -> Layout -> Layout
setStack c slots layout =
    { layout
        | stacks = Dict.insert c slots layout.stacks
        , stackOrder =
            if List.member c layout.stackOrder then
                layout.stackOrder

            else
                layout.stackOrder ++ [ c ]
    }


dropStack : Int -> Layout -> Layout
dropStack c layout =
    { layout | stacks = Dict.remove c layout.stacks, stackOrder = List.filter ((/=) c) layout.stackOrder }


replaceFirst : Maybe Int -> Maybe Int -> List (Maybe Int) -> List (Maybe Int)
replaceFirst old new xs =
    case xs of
        x :: rest ->
            if x == old then
                new :: rest

            else
                x :: replaceFirst old new rest

        [] ->
            []


remove : Int -> Layout -> Layout
remove u layout =
    case Dict.get u layout.where_ of
        Nothing ->
            layout

        Just w ->
            let
                l =
                    { layout | where_ = Dict.remove u layout.where_ }
            in
            case w of
                InFlow fkey ->
                    { l | flows = Dict.update fkey (Maybe.map (replaceFirst (Just u) Nothing)) l.flows }

                InStack c ->
                    { l | stacks = Dict.update c (Maybe.map (replaceFirst (Just u) Nothing)) l.stacks }

                InCpp ->
                    l

                InKernel ->
                    l


insertFlow : Int -> ( String, Int ) -> Layout -> Layout
insertFlow u fkey layout =
    let
        slots =
            Dict.get fkey layout.flows |> Maybe.withDefault [] |> Array.fromList

        k =
            key layout u

        i =
            Array.foldl
                (\s ( j, acc ) ->
                    case s of
                        Just v ->
                            if compareKey (key layout v) k == LT then
                                ( j + 1, j + 1 )

                            else
                                ( j + 1, acc )

                        Nothing ->
                            ( j + 1, acc )
                )
                ( 0, 0 )
                slots
                |> Tuple.second

        n =
            Array.length slots

        hole =
            List.range i (n - 1) |> List.filter (\h -> Array.get h slots == Just Nothing) |> List.head

        list =
            Array.toList slots

        newSlots =
            case hole of
                Nothing ->
                    List.take i list ++ [ Just u ] ++ List.drop i list

                Just h ->
                    List.take i list ++ [ Just u ] ++ List.take (h - i) (List.drop i list) ++ List.drop (h + 1) list
    in
    { layout | flows = Dict.insert fkey newSlots layout.flows, where_ = Dict.insert u (InFlow fkey) layout.where_ }


{-| Python compares the (group, label) tuples as strings, by code point. -}
compareKey : ( String, String ) -> ( String, String ) -> Order
compareKey ( g1, l1 ) ( g2, l2 ) =
    case compare g1 g2 of
        EQ ->
            compare l1 l2

        o ->
            o


stackHeight : List (Maybe Int) -> Int
stackHeight stack =
    let
        go i xs =
            case xs of
                Nothing :: _ ->
                    i

                _ :: rest ->
                    go (i + 1) rest

                [] ->
                    i
    in
    go 0 stack


dropTrailingHoles : List (Maybe Int) -> List (Maybe Int)
dropTrailingHoles slots =
    case List.reverse slots of
        Nothing :: _ ->
            dropTrailingHoles (List.reverse (List.drop 1 (List.reverse slots)))

        _ ->
            slots


{-| Moves from the last commit's graph to this one's. `renamed` lists, in
order, a node id that has gone and the id it was renamed to.
-}
step : Dict String NodeInfo -> Set ( String, String ) -> List ( String, String ) -> Layout -> ( Layout, Geometry, Dict Int Pos )
step nodes edges renamed layout0 =
    let
        gone =
            Dict.keys layout0.uid |> List.filter (\i -> not (Dict.member i nodes))

        goneSet =
            Set.fromList gone

        oldUid =
            layout0.uid

        uid1 =
            List.foldl Dict.remove layout0.uid gone

        uid2 =
            List.foldl
                (\( old, new ) acc ->
                    if Set.member old goneSet && Dict.member new nodes && not (Dict.member new oldUid) then
                        case Dict.get old oldUid of
                            Just u ->
                                Dict.insert new u acc

                            Nothing ->
                                acc

                    else
                        acc
                )
                uid1
                renamed

        ( uid3, uids3, arrived ) =
            Dict.keys nodes
                |> List.foldl
                    (\i ( acc, us, arr ) ->
                        if Dict.member i acc then
                            ( acc, us, arr )

                        else
                            let
                                u =
                                    Array.length us
                            in
                            ( Dict.insert i u acc, Array.push i us, u :: arr )
                    )
                    ( uid2, layout0.uids, [] )
                |> (\( a, b, c ) -> ( a, b, List.reverse c ))

        live =
            Dict.values uid3 |> Set.fromList

        layout1 =
            Dict.keys layout0.where_
                |> List.foldl
                    (\u l ->
                        if Set.member u live then
                            l

                        else
                            remove u l |> (\l2 -> { l2 | info = Dict.remove u l2.info })
                    )
                    { layout0 | uid = uid3, uids = uids3 }

        ( layout2, moved ) =
            Dict.toList uid3
                |> List.foldl
                    (\( i, u ) ( l, mv ) ->
                        case Dict.get i nodes of
                            Just n ->
                                let
                                    before =
                                        Dict.get u l.info

                                    l2 =
                                        { l | info = Dict.insert u n l.info }
                                in
                                case before of
                                    Just b ->
                                        if b.stage /= n.stage && Dict.member u l2.where_ then
                                            ( remove u l2, u :: mv )

                                        else
                                            ( l2, mv )

                                    Nothing ->
                                        ( l2, mv )

                            Nothing ->
                                ( l, mv )
                    )
                    ( layout1, [] )

        layout3 =
            let
                flows =
                    layout2.flows |> Dict.map (\_ s -> dropTrailingHoles s) |> Dict.filter (\_ s -> not (List.isEmpty s))

                l =
                    { layout2 | flows = flows, stacks = Dict.map (\_ s -> dropTrailingHoles s) layout2.stacks }

                emptyStacks =
                    Dict.toList l.stacks |> List.filter (\( _, s ) -> List.isEmpty s) |> List.map Tuple.first
            in
            List.foldl dropStack l emptyStacks

        placing =
            List.sortWith (\a b -> compareKey (key layout3 a) (key layout3 b)) (arrived ++ List.reverse moved)

        stageOf i =
            Dict.get i nodes |> Maybe.map .stage |> Maybe.withDefault ""

        inAdj : Dict String (Set String)
        inAdj =
            Set.foldl
                (\( a, b ) acc ->
                    if stageOf a == stageOf b then
                        Dict.update b (\v -> Just (Set.insert a (Maybe.withDefault Set.empty v))) acc

                    else
                        acc
                )
                Dict.empty
                edges

        depth i seen =
            let
                preds =
                    Dict.get i inAdj |> Maybe.withDefault Set.empty |> Set.toList |> List.filter (\p -> not (List.member p seen))
            in
            if List.isEmpty preds || List.length seen > 2 then
                0

            else
                1 + (List.map (\p -> depth p (seen ++ [ i ])) preds |> List.maximum |> Maybe.withDefault 0)

        layout4 =
            List.foldl
                (\u l ->
                    case Dict.get u l.info of
                        Just inf ->
                            if inf.stage == "cppfound" then
                                { l | where_ = Dict.insert u InCpp l.where_ }

                            else if inf.stage == "kernelsrc" then
                                { l | where_ = Dict.insert u InKernel l.where_ }

                            else if inf.stage /= "foundation" then
                                insertFlow u ( inf.stage, min (depth inf.id []) 2 ) l

                            else
                                l

                        Nothing ->
                            l
                )
                layout3
                placing

        geo1 =
            geometry layout4

        pos1 =
            positions geo1 layout4

        users : Dict String (List String)
        users =
            Set.foldl (\( a, b ) acc -> Dict.update b (\v -> Just (a :: Maybe.withDefault [] v)) acc) Dict.empty edges

        found0 =
            List.filter (\u -> (Dict.get u layout4.info |> Maybe.map .stage) == Just "foundation") placing

        ncols =
            max 1 (floorDiv (geo1.elmEnd - 2 - nodeW) colPitch + 1)

        half =
            toFloat geo1.elmEnd / 2

        placePass everyone ( l, pos, found ) =
            let
                want : Dict Int Float
                want =
                    List.foldl
                        (\u acc ->
                            let
                                id =
                                    Dict.get u l.info |> Maybe.map .id |> Maybe.withDefault ""

                                xs =
                                    Dict.get id users
                                        |> Maybe.withDefault []
                                        |> List.filterMap (\a -> Dict.get a l.uid |> Maybe.andThen (\ua -> Dict.get ua pos))
                                        |> List.map Tuple.first
                            in
                            if List.isEmpty xs then
                                acc

                            else
                                Dict.insert u (toFloat (List.sum xs) / toFloat (List.length xs)) acc
                        )
                        Dict.empty
                        found

                order =
                    List.sortWith
                        (\a b ->
                            case compare (Dict.get a want |> Maybe.withDefault half) (Dict.get b want |> Maybe.withDefault half) of
                                EQ ->
                                    compareKey (key l a) (key l b)

                                o ->
                                    o
                        )
                        found

                ( l2, pos2 ) =
                    List.foldl
                        (\u ( la, pa ) ->
                            if not (Dict.member u want) && not everyone then
                                ( la, pa )

                            else
                                let
                                    x =
                                        Dict.get u want |> Maybe.withDefault half

                                    c0 =
                                        max 0 (min (toFloat (ncols - 1)) ((x - 1) / toFloat colPitch))

                                    cost col =
                                        toFloat (stackHeight (Dict.get col la.stacks |> Maybe.withDefault [])) + 2 * abs (toFloat col - c0)

                                    c =
                                        List.range 0 (ncols - 1)
                                            |> List.foldl
                                                (\cand best ->
                                                    case best of
                                                        Nothing ->
                                                            Just cand

                                                        Just bc ->
                                                            if cost cand < cost bc then
                                                                Just cand

                                                            else
                                                                best
                                                )
                                                Nothing
                                            |> Maybe.withDefault 0

                                    stack =
                                        Dict.get c la.stacks |> Maybe.withDefault []

                                    newStack =
                                        if List.member Nothing stack then
                                            replaceFirst Nothing (Just u) stack

                                        else
                                            stack ++ [ Just u ]

                                    la2 =
                                        setStack c newStack la
                                in
                                ( { la2 | where_ = Dict.insert u (InStack c) la2.where_ }
                                , Dict.insert u ( 1 + c * colPitch, 0 ) pa
                                )
                        )
                        ( l, pos )
                        order
            in
            ( l2, pos2, List.filter (\u -> not (Dict.member u l2.where_)) found )

        ( layout5, _, _ ) =
            ( layout4, pos1, found0 ) |> placePass False |> placePass True

        -- a stack beyond the foundation's columns moves in
        layout6 =
            layout5.stackOrder
                |> List.filter (\c -> c >= ncols)
                |> List.foldl
                    (\c l ->
                        let
                            moving =
                                Dict.get c l.stacks |> Maybe.withDefault [] |> List.filterMap identity

                            l2 =
                                dropStack c l
                        in
                        List.foldl
                            (\u la ->
                                let
                                    la2 =
                                        setStack (ncols - 1) ((Dict.get (ncols - 1) la.stacks |> Maybe.withDefault []) ++ [ Just u ]) la
                                in
                                { la2 | where_ = Dict.insert u (InStack (ncols - 1)) la2.where_ }
                            )
                            l2
                            moving
                    )
                    layout5

        geo =
            geometry layout6
    in
    ( layout6, geo, positions geo layout6 )


geometry : Layout -> Geometry
geometry layout =
    let
        liveStage : Dict String Int
        liveStage =
            Dict.foldl
                (\u _ acc ->
                    case Dict.get u layout.info of
                        Just i ->
                            Dict.update i.stage (\v -> Just (Maybe.withDefault 0 v + 1)) acc

                        Nothing ->
                            acc
                )
                Dict.empty
                layout.where_

        flowCols st =
            Dict.toList layout.flows
                |> List.filter (\( ( s, _ ), _ ) -> s == st)
                |> List.map (\( _, slots ) -> ceilDiv (List.length slots) maxRows)
                |> List.sum

        ( stagesD, _ ) =
            List.foldl
                (\s ( acc, rowX ) ->
                    let
                        rowX2 =
                            if s.row == 1 && s.key == Stages.branchTo then
                                case Dict.get Stages.branchFrom acc of
                                    Just f ->
                                        Dict.insert 1 (max (Dict.get 1 rowX |> Maybe.withDefault 0) (f.gx + f.gw + stageGap)) rowX

                                    Nothing ->
                                        rowX

                            else
                                rowX
                    in
                    if (Dict.get s.key liveStage |> Maybe.withDefault 0) > 0 then
                        let
                            gw =
                                max minCols (flowCols s.key) * colPitch

                            x =
                                Dict.get s.row rowX2 |> Maybe.withDefault 0
                        in
                        ( Dict.insert s.key { gx = x, gw = gw, row = s.row, lang = s.lang, gy = 0, gh = 0 } acc
                        , Dict.insert s.row (x + gw + stageGap) rowX2
                        )

                    else
                        ( acc, rowX2 )
                )
                ( Dict.empty, Dict.fromList [ ( 0, 0 ), ( 1, 0 ) ] )
                Stages.stages

        rowRows r =
            let
                tallest =
                    Dict.toList layout.flows
                        |> List.filterMap
                            (\( ( s, _ ), slots ) ->
                                case Dict.get s stagesD of
                                    Just b ->
                                        if b.row == r then
                                            Just (min (List.length slots) maxRows)

                                        else
                                            Nothing

                                    Nothing ->
                                        Nothing
                            )
                        |> List.maximum
                        |> Maybe.withDefault 0
            in
            if List.any (\b -> b.row == r) (Dict.values stagesD) then
                headRows + tallest * nodeH + 1

            else
                0

        r0 =
            rowRows 0

        r1 =
            rowRows 1

        rowTop r =
            if r == 0 then
                0

            else if r0 /= 0 then
                r0 + rowGap

            else
                0

        stagesFinal =
            Dict.map
                (\_ b ->
                    { b
                        | gy = rowTop b.row
                        , gh =
                            if b.row == 0 then
                                r0

                            else
                                r1
                    }
                )
                stagesD

        stageRows =
            if r1 /= 0 then
                rowTop 1 + r1

            else
                r0

        elmEnd =
            Dict.values stagesFinal |> List.filter (\b -> b.lang == "elm") |> List.map (\b -> b.gx + b.gw) |> List.maximum |> Maybe.withDefault 0

        tallestStack =
            Dict.values layout.stacks |> List.map List.length |> List.maximum |> Maybe.withDefault 0

        cppGx =
            max (Dict.values stagesFinal |> List.filter (\b -> b.lang == "cpp") |> List.map .gx |> List.minimum |> Maybe.withDefault 0)
                (if tallestStack > 0 then
                    elmEnd + stageGap

                 else
                    0
                )

        foundTop =
            stageRows + 3

        hasCppFound =
            Dict.toList layout.where_ |> List.any (\( u, _ ) -> (Dict.get u layout.info |> Maybe.map .stage) == Just "cppfound")

        foundRows =
            if tallestStack > 0 || hasCppFound then
                max (foundHead + tallestStack * nodeH)
                    (if hasCppFound then
                        foundHead + 2 + cppPerCol * nodeH

                     else
                        0
                    )
                    + 1

            else
                0

        ( sections, sx ) =
            List.foldl
                (\( k, title, ids ) ( acc, x ) ->
                    ( acc ++ [ { key = k, title = title, gx = x } ], x + ceilDiv (List.length ids) cppPerCol * colPitch + 2 )
                )
                ( [], cppGx + 1 )
                Stages.cppFound

        -- the kernel sources band, under the foundations
        plan =
            kernelPlan layout

        -- a band per library, side by side, each with a section per kernel
        ( kernBands, kx ) =
            plan
                |> List.foldl
                    (\( k, members ) acc ->
                        let
                            lib =
                                String.split "|" k |> List.head |> Maybe.andThen String.toInt |> Maybe.withDefault 0
                        in
                        case acc of
                            ( l, ms ) :: rest ->
                                if l == lib then
                                    ( l, ms ++ [ ( k, members ) ] ) :: rest

                                else
                                    ( lib, [ ( k, members ) ] ) :: acc

                            [] ->
                                [ ( lib, [ ( k, members ) ] ) ]
                    )
                    []
                |> List.reverse
                |> List.foldl
                    (\( lib, secs ) ( acc, x ) ->
                        let
                            ( bandSections, sx2 ) =
                                List.foldl
                                    (\( k, members ) ( sa, sxa ) ->
                                        ( sa ++ [ { key = k, title = sectionTitle k, gx = sxa } ], sxa + ceilDiv (List.length members) kernPerCol * colPitch + stageGap )
                                    )
                                    ( [], x + 1 )
                                    secs

                            width =
                                sx2 - stageGap + 1 - x
                        in
                        ( acc ++ [ { title = Stages.kernelLibraries |> List.drop lib |> List.head |> Maybe.map .title |> Maybe.withDefault "", gx = x, cols = width, sections = bandSections } ]
                        , x + width + stageGap
                        )
                    )
                    ( [], 0 )

        kernSections =
            List.concatMap .sections kernBands

        kernTop =
            if List.isEmpty plan then
                0

            else if foundRows /= 0 then
                foundTop + foundRows + rowGap

            else
                stageRows + rowGap

        kernRows =
            if List.isEmpty plan then
                0

            else
                foundHead + 2 + (plan |> List.map (Tuple.second >> List.length >> min kernPerCol) |> List.maximum |> Maybe.withDefault 0) * nodeH + 1

        kernCols =
            if List.isEmpty plan then
                0

            else
                kx - stageGap

        cols =
            (Dict.values stagesFinal |> List.map (\b -> b.gx + b.gw))
                ++ [ if hasCppFound then
                        sx

                     else
                        0
                   , kernCols
                   ]
                |> List.maximum
                |> Maybe.withDefault 0
    in
    { stages = stagesFinal
    , elmEnd = elmEnd
    , cppGx = cppGx
    , foundTop = foundTop
    , foundRows = foundRows
    , hasElmFound = tallestStack > 0
    , hasCppFound = hasCppFound
    , sections = sections
    , kernTop = kernTop
    , kernRows = kernRows
    , kernCols = kernCols
    , kernSections = kernSections
    , kernBands = kernBands
    , cols = cols
    , rows =
        if kernRows /= 0 then
            kernTop + kernRows

        else if foundRows /= 0 then
            foundTop + foundRows

        else
            stageRows
    }


{-| The kernel sources band's sections in order, each with its nodes in order:
Elm modules first, then C++ files, by label.
-}
kernelPlan : Layout -> List ( String, List Int )
kernelPlan layout =
    Dict.foldl
        (\u w acc ->
            case ( w, Dict.get u layout.info ) of
                ( InKernel, Just i ) ->
                    Dict.update i.group (\v -> Just (u :: Maybe.withDefault [] v)) acc

                _ ->
                    acc
        )
        Dict.empty
        layout.where_
        |> Dict.toList
        |> List.map
            (\( k, us ) ->
                ( k
                , List.sortBy
                    (\u ->
                        Dict.get u layout.info
                            |> Maybe.map
                                (\i ->
                                    ( if i.lang == "elm" then
                                        0

                                      else
                                        1
                                    , i.label
                                    )
                                )
                            |> Maybe.withDefault ( 2, "" )
                    )
                    us
                )
            )


{-| A section key is `library|kind|title`. -}
sectionTitle : String -> String
sectionTitle k =
    String.split "|" k |> List.drop 2 |> String.join "|"


positions : Geometry -> Layout -> Dict Int Pos
positions geo layout =
    let
        flowPos =
            Dict.foldl
                (\( st, d ) slots acc ->
                    case Dict.get st geo.stages of
                        Just s ->
                            let
                                off =
                                    List.range 0 (d - 1)
                                        |> List.filterMap (\e -> Dict.get ( st, e ) layout.flows)
                                        |> List.map (\sl -> ceilDiv (List.length sl) maxRows)
                                        |> List.sum
                            in
                            List.indexedMap Tuple.pair slots
                                |> List.foldl
                                    (\( j, slot ) a ->
                                        case slot of
                                            Just u ->
                                                Dict.insert u
                                                    ( s.gx + 1 + (off + j // maxRows) * colPitch
                                                    , s.gy + headRows + modBy maxRows j * nodeH
                                                    )
                                                    a

                                            Nothing ->
                                                a
                                    )
                                    acc

                        Nothing ->
                            acc
                )
                Dict.empty
                layout.flows

        stackPos =
            Dict.foldl
                (\c slots acc ->
                    List.indexedMap Tuple.pair slots
                        |> List.foldl
                            (\( j, slot ) a ->
                                case slot of
                                    Just u ->
                                        Dict.insert u ( 1 + c * colPitch, geo.foundTop + foundHead + j * nodeH ) a

                                    Nothing ->
                                        a
                            )
                            acc
                )
                flowPos
                layout.stacks
    in
    Dict.foldl
        (\u w acc ->
            case w of
                InCpp ->
                    let
                        id =
                            Dict.get u layout.info |> Maybe.map .id |> Maybe.withDefault ""
                    in
                    case Dict.get id Stages.cppFoundSlot of
                        Just ( s, k ) ->
                            let
                                sgx =
                                    List.drop s geo.sections |> List.head |> Maybe.map .gx |> Maybe.withDefault 0
                            in
                            Dict.insert u ( sgx + (k // cppPerCol) * colPitch, geo.foundTop + foundHead + 2 + modBy cppPerCol k * nodeH ) acc

                        Nothing ->
                            acc

                _ ->
                    acc
        )
        stackPos
        layout.where_
        |> (\placed ->
                List.map2
                    (\( _, members ) sec ->
                        List.indexedMap
                            (\j u ->
                                ( u
                                , ( sec.gx + (j // kernPerCol) * colPitch
                                  , geo.kernTop + foundHead + 2 + modBy kernPerCol j * nodeH
                                  )
                                )
                            )
                            members
                    )
                    (kernelPlan layout)
                    geo.kernSections
                    |> List.concat
                    |> List.foldl (\( u, p ) acc -> Dict.insert u p acc) placed
           )
