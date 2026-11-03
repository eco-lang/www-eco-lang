module Kg.Query exposing
    ( Resolution(..), resolve
    , Neighbour, neighbours
    , paths
    , HistorySummary, historyOf
    , LayerGroup, layering
    , Hit, locate, LocateOptions, rrf
    , dependencyKinds, plansFor, invariantsFor, gatedBy, plansForStage
    )

{-| Every query the tools make (§13.6, §14.2 of the plan), over a snapshot's
graph, history and indexes. Pure.
-}

import Array
import Dict exposing (Dict)
import Kg.Graph as G exposing (Edge, Graph, Node, NodeKind(..))
import Kg.History as History exposing (History)
import Kg.Search.Bm25 as Bm25
import Kg.Search.Chunks exposing (Chunk)
import Kg.Search.Tokens as Tokens
import Kg.Stages as Stages
import Set exposing (Set)


dependencyKinds : List String
dependencyKinds =
    G.dependencyKinds



-- RESOLVING NODE ARGUMENTS


type Resolution
    = Found Node
    | Candidates (List Node)


{-| A node argument, in order: an exact id; an exact label; a module whose name
ends with the argument after a `.`, if only one does; a file path, or the end
of one; otherwise up to ten candidates by keyword search on labels.
-}
resolve : Graph -> Bm25.Index -> Array.Array Chunk -> String -> Resolution
resolve g bm25 chunks arg0 =
    let
        arg =
            String.trim arg0

        byLabel =
            G.nodes g |> List.filter (\n -> n.label == arg)

        preferred ns =
            -- a module or component over a definition or a section with the same label
            case List.filter (\n -> n.kind == Module || n.kind == Component || n.kind == Stage || n.kind == Plan) ns of
                [ one ] ->
                    Just one

                _ ->
                    case ns of
                        [ one ] ->
                            Just one

                        _ ->
                            Nothing

        bySuffix =
            G.nodes g
                |> List.filter (\n -> (n.kind == Module || n.kind == Component) && (String.endsWith ("." ++ arg) n.id || String.endsWith ("." ++ arg) n.label || String.endsWith (":" ++ arg) n.id))

        byPath =
            case Dict.get arg g.fileNode of
                Just id ->
                    G.node id g

                Nothing ->
                    case List.filter (\p -> String.endsWith ("/" ++ arg) p) (Dict.keys g.fileNode) of
                        [ p ] ->
                            Dict.get p g.fileNode |> Maybe.andThen (\id -> G.node id g)

                        _ ->
                            Nothing

        qualifiedDef =
            -- Module.value or Module#value
            case List.reverse (String.split "." (String.replace "#" "." arg)) of
                value :: modRev ->
                    if modRev /= [] && (String.uncons value |> Maybe.map (Tuple.first >> Char.isLower) |> Maybe.withDefault False) then
                        let
                            modName =
                                String.join "." (List.reverse modRev)

                            mods =
                                if Dict.member modName g.nodes then
                                    [ modName ]

                                else
                                    G.nodes g |> List.filter (\n -> n.kind == Module && String.endsWith ("." ++ modName) n.id) |> List.map .id
                        in
                        case mods |> List.map (\m -> m ++ "#" ++ value) |> List.filterMap (\id -> G.node id g) of
                            [ one ] ->
                                Just one

                            _ ->
                                Nothing

                    else
                        Nothing

                [] ->
                    Nothing
    in
    case G.node arg g of
        Just n ->
            Found n

        Nothing ->
            case preferred byLabel of
                Just n ->
                    Found n

                Nothing ->
                    case bySuffix of
                        [ n ] ->
                            Found n

                        _ ->
                            case ( byPath, qualifiedDef ) of
                                ( Just n, _ ) ->
                                    Found n

                                ( _, Just n ) ->
                                    Found n

                                _ ->
                                    Candidates
                                        (if List.length byLabel > 1 then
                                            List.take 10 byLabel

                                         else if List.length bySuffix > 1 then
                                            List.take 10 bySuffix

                                         else
                                            searchNodes g bm25 chunks arg 10
                                        )


searchNodes : Graph -> Bm25.Index -> Array.Array Chunk -> String -> Int -> List Node
searchNodes g bm25 chunks text limit =
    Bm25.search bm25 (\_ -> True) 50 (Tokens.tokenize text)
        |> List.filterMap (\( id, _ ) -> Array.get id chunks |> Maybe.map .node)
        |> dedupe
        |> List.filterMap (\id -> G.node id g)
        |> List.take limit


dedupe : List comparable -> List comparable
dedupe xs =
    List.foldl
        (\x ( seen, acc ) ->
            if Set.member x seen then
                ( seen, acc )

            else
                ( Set.insert x seen, x :: acc )
        )
        ( Set.empty, [] )
        xs
        |> Tuple.second
        |> List.reverse



-- NEIGHBOURS


type alias Neighbour =
    { edge : Edge, direction : String, depth : Int, other : String }


{-| Edges out of, into, or both, a node, up to `depth` steps away, filtered by
edge kind. Each node is reached once, at its least depth.
-}
neighbours : Graph -> String -> String -> Int -> List String -> List Neighbour
neighbours g start direction depth kinds =
    let
        keep e =
            List.isEmpty kinds || List.member e.kind kinds

        stepFrom id =
            (if direction == "out" || direction == "both" then
                G.outgoing id g |> List.filter keep |> List.map (\e -> ( e, "out", e.to ))

             else
                []
            )
                ++ (if direction == "in" || direction == "both" then
                        G.incoming id g |> List.filter keep |> List.map (\e -> ( e, "in", e.from ))

                    else
                        []
                   )

        go d frontier seen acc =
            if d > depth || List.isEmpty frontier then
                List.reverse acc

            else
                let
                    found =
                        frontier |> List.concatMap stepFrom

                    fresh =
                        List.foldl
                            (\(( _, _, o ) as x) ( taken, acc2 ) ->
                                if Set.member o seen || Set.member o taken then
                                    ( taken, acc2 )

                                else
                                    ( Set.insert o taken, x :: acc2 )
                            )
                            ( Set.empty, [] )
                            found
                            |> Tuple.second
                            |> List.reverse

                    nextSeen =
                        List.foldl (\( _, _, o ) s -> Set.insert o s) seen fresh

                    newAcc =
                        List.foldl (\( e, dir, o ) a -> { edge = e, direction = dir, depth = d, other = o } :: a) acc fresh
                in
                go (d + 1) (dedupe (List.map (\( _, _, o ) -> o) fresh)) nextSeen newAcc
    in
    go 1 [ start ] (Set.singleton start) []



-- PATHS


{-| Up to three shortest paths from one node to another along outgoing edges
of the given kinds, of at most eight steps, by breadth-first search.
-}
paths : Graph -> String -> String -> List String -> List (List Edge)
paths g from to via =
    let
        keep e =
            List.member e.kind via

        -- distances from `from`, and every edge on a shortest path into each node
        bfs frontier dist preds d =
            if List.isEmpty frontier || d >= 8 || Dict.member to dist then
                ( dist, preds )

            else
                let
                    edges =
                        frontier |> List.concatMap (\id -> G.outgoing id g |> List.filter keep)

                    ( dist2, preds2, next ) =
                        List.foldl
                            (\e ( ds, ps, nx ) ->
                                case Dict.get e.to ds of
                                    Nothing ->
                                        ( Dict.insert e.to (d + 1) ds, Dict.insert e.to [ e ] ps, e.to :: nx )

                                    Just dd ->
                                        if dd == d + 1 then
                                            ( ds, Dict.update e.to (Maybe.map (\l -> l ++ [ e ])) ps, nx )

                                        else
                                            ( ds, ps, nx )
                            )
                            ( dist, preds, [] )
                            edges
                in
                bfs (List.reverse next) dist2 preds2 (d + 1)

        ( distances, predecessors ) =
            bfs [ from ] (Dict.singleton from 0) Dict.empty 0

        back id =
            if id == from then
                [ [] ]

            else
                Dict.get id predecessors
                    |> Maybe.withDefault []
                    |> List.take 3
                    |> List.concatMap (\e -> back e.from |> List.take 3 |> List.map (\p -> p ++ [ e ]))
    in
    if not (Dict.member to distances) || from == to then
        []

    else
        back to |> List.take 3



-- HISTORY


type alias HistorySummary =
    { first : Maybe ( Int, History.CommitInfo )
    , last : Maybe ( Int, History.CommitInfo )
    , alive : Bool
    , renames : List ( History.CommitInfo, String )
    , editCount : Int
    , recent : List History.CommitInfo
    , partners : List ( String, Int )
    }


historyOf : History -> String -> Int -> HistorySummary
historyOf h id limit =
    let
        commit i =
            Array.get i h.commits

        lives =
            Dict.get id h.lives |> Maybe.withDefault []

        edits =
            Dict.get id h.edits |> Maybe.withDefault []

        firstIndex =
            List.minimum (lives ++ edits)

        lastIndex =
            List.maximum edits
    in
    { first = firstIndex |> Maybe.andThen (\i -> commit i |> Maybe.map (Tuple.pair i))
    , last = lastIndex |> Maybe.andThen (\i -> commit i |> Maybe.map (Tuple.pair i))
    , alive = modBy 2 (List.length lives) == 1 || List.isEmpty lives
    , renames = Dict.get id h.renames |> Maybe.withDefault [] |> List.filterMap (\( i, old ) -> commit i |> Maybe.map (\c -> ( c, old )))
    , editCount = List.length edits
    , recent = edits |> List.reverse |> List.take limit |> List.filterMap commit
    , partners = History.partners id h |> List.take 10
    }



-- LAYERING


type alias LayerGroup =
    { name : String, count : Int, edges : List Edge }


{-| The dependency edges between stages, grouped by direction. -}
layering : Graph -> Maybe String -> List LayerGroup
layering g only =
    let
        stageOf id =
            G.node id g |> Maybe.andThen .stage

        order s =
            Stages.stageIndex s

        moduleKinds =
            [ "imports", "includes", "uses_symbol", "kernel", "links", "member" ]

        edges =
            G.nodes g
                |> List.filter (\n -> n.kind == Module || n.kind == Component)
                |> List.concatMap (\n -> G.outgoing n.id g)
                |> List.filter (\e -> List.member e.kind moduleKinds)

        classify e =
            case ( stageOf e.from, stageOf e.to ) of
                ( Just a, Just b ) ->
                    if a == b then
                        Nothing

                    else if only /= Nothing && only /= Just a && only /= Just b then
                        Nothing

                    else if a == "foundation" || a == "cppfound" then
                        Just "foundation → stage"

                    else if b == "foundation" || b == "cppfound" then
                        Just "stage → foundation"

                    else if b == "driver" then
                        Just "stage → driver"

                    else if a == "driver" then
                        Just "driver → stage"

                    else if order a < order b then
                        Just "earlier → later stage"

                    else
                        Just "later → earlier stage"

                _ ->
                    Nothing

        groups =
            List.foldl
                (\e acc ->
                    case classify e of
                        Just k ->
                            Dict.update k (\v -> Just (e :: Maybe.withDefault [] v)) acc

                        Nothing ->
                            acc
                )
                Dict.empty
                edges
    in
    [ "later → earlier stage", "earlier → later stage", "foundation → stage", "stage → driver", "driver → stage", "stage → foundation" ]
        |> List.filterMap
            (\name ->
                Dict.get name groups
                    |> Maybe.map (\es -> { name = name, count = List.length es, edges = List.reverse es })
            )



-- LOCATE


type alias Hit =
    { node : Node, score : Float, chunk : Maybe Chunk, via : Maybe String }


type alias LocateOptions =
    { kinds : List String, stage : Maybe String, limit : Int, includeSuperseded : Bool }


{-| Reciprocal rank fusion of ranked lists of chunk ids. -}
rrf : List (List Int) -> List ( Int, Float )
rrf lists =
    lists
        |> List.foldl
            (\l acc ->
                List.indexedMap Tuple.pair l
                    |> List.foldl (\( rank, id ) a -> Dict.update id (\v -> Just (Maybe.withDefault 0 v + 1 / (60 + toFloat (rank + 1)))) a) acc
            )
            Dict.empty
        |> Dict.toList
        |> List.sortBy (\( id, s ) -> ( -s, id ))


{-| Ranks nodes for a query (§13.6): keyword and vector results fused, lifted
to nodes (a node scores its best chunk), expanded to the nodes prose mentions
and to flags' gated code at 0.3 of the score, filtered, and cut to `limit`.
`vectorRanks` is the vector search's ranked chunk ids, empty when there is
no embedding server.
-}
locate : Graph -> Bm25.Index -> Array.Array Chunk -> List Int -> String -> LocateOptions -> List Hit
locate g bm25 chunks vectorRanks query opts =
    let
        keyword =
            Bm25.search bm25 (\_ -> True) 50 (Tokens.tokenize query) |> List.map Tuple.first

        fused =
            if List.isEmpty vectorRanks then
                rrf [ keyword ]

            else
                rrf [ keyword, List.take 50 vectorRanks ]

        lifted : Dict String ( Float, Int )
        lifted =
            List.foldl
                (\( cid, s ) acc ->
                    case Array.get cid chunks of
                        Just c ->
                            case Dict.get c.node acc of
                                Just ( best, _ ) ->
                                    if s > best then
                                        Dict.insert c.node ( s, cid ) acc

                                    else
                                        acc

                                Nothing ->
                                    Dict.insert c.node ( s, cid ) acc

                        Nothing ->
                            acc
                )
                Dict.empty
                fused

        expanded : Dict String ( Float, Maybe Int, Maybe String )
        expanded =
            Dict.foldl
                (\id ( s, cid ) acc ->
                    let
                        withSelf =
                            Dict.update id
                                (\v ->
                                    case v of
                                        Just ( old, oc, ov ) ->
                                            if s > old then
                                                Just ( s, Just cid, Nothing )

                                            else
                                                Just ( old, oc, ov )

                                        Nothing ->
                                            Just ( s, Just cid, Nothing )
                                )
                                acc

                        extra =
                            case G.node id g |> Maybe.map .kind of
                                Just Plan ->
                                    G.outgoing id g |> List.filter (\e -> e.kind == "mentions") |> List.map .to

                                Just DocSection ->
                                    G.outgoing id g |> List.filter (\e -> e.kind == "mentions") |> List.map .to

                                Just Invariant ->
                                    G.outgoing id g |> List.filter (\e -> e.kind == "mentions") |> List.map .to

                                Just Module ->
                                    G.incoming id g |> List.filter (\e -> e.kind == "gates") |> List.map .from

                                Just Flag ->
                                    G.outgoing id g |> List.filter (\e -> e.kind == "gates") |> List.map .to

                                Just Concept ->
                                    G.outgoing id g |> List.map .to

                                _ ->
                                    []
                    in
                    List.foldl
                        (\other a ->
                            let
                                es =
                                    0.3 * s
                            in
                            Dict.update other
                                (\v ->
                                    case v of
                                        Just ( old, oc, ov ) ->
                                            if es > old then
                                                Just ( es, Nothing, Just id )

                                            else
                                                Just ( old, oc, ov )

                                        Nothing ->
                                            Just ( es, Nothing, Just id )
                                )
                                a
                        )
                        withSelf
                        extra
                )
                Dict.empty
                lifted

        -- a concept whose name or alias the query is, or contains, goes
        -- first, and brings the code it links at half its score
        -- lower case, punctuation as spaces, and a plural `s` dropped, so
        -- "lambda-set member id" matches the alias "member ids"
        normalised t =
            String.toLower t
                |> String.map
                    (\c ->
                        if Char.isAlphaNum c then
                            c

                        else
                            ' '
                    )
                |> String.words
                |> List.map
                    (\w ->
                        if String.length w > 3 && String.endsWith "s" w && not (String.endsWith "ss" w) then
                            String.dropRight 1 w

                        else
                            w
                    )
                |> String.join " "

        q =
            normalised query

        conceptMatch n =
            n.kind == Concept
                && (n.label
                        :: (Dict.get "aliases" n.props |> Maybe.withDefault "" |> String.split ", ")
                        |> List.map normalised
                        |> List.any (\a -> String.length a >= 3 && (a == q || String.contains a q || String.contains q a))
                   )

        top =
            Dict.values expanded |> List.map (\( sc, _, _ ) -> sc) |> List.maximum |> Maybe.withDefault 1

        boosted =
            G.nodes g
                |> List.filter conceptMatch
                |> List.foldl
                    (\c acc ->
                        let
                            score =
                                top * 1.2
                        in
                        G.outgoing c.id g
                            |> List.foldl
                                (\e a ->
                                    Dict.update e.to
                                        (\v ->
                                            case v of
                                                Just ( old, oc, ov ) ->
                                                    if 0.5 * score > old then
                                                        Just ( 0.5 * score, Nothing, Just c.id )

                                                    else
                                                        Just ( old, oc, ov )

                                                Nothing ->
                                                    Just ( 0.5 * score, Nothing, Just c.id )
                                        )
                                        a
                                )
                                (Dict.insert c.id ( score, Dict.get c.id acc |> Maybe.andThen (\( _, ch, _ ) -> ch), Nothing ) acc)
                    )
                    expanded

        passes n =
            let
                status =
                    Dict.get "status" n.props |> Maybe.withDefault ""

                kindOk =
                    List.isEmpty opts.kinds || List.member (kindFilterName n.kind) opts.kinds

                stageOk =
                    case opts.stage of
                        Just st ->
                            n.stage == Just st

                        Nothing ->
                            True

                statusOk =
                    opts.includeSuperseded || not (n.kind == Plan && List.member status [ "superseded", "abandoned" ])
            in
            kindOk && stageOk && statusOk
    in
    Dict.toList boosted
        |> List.filterMap
            (\( id, ( s, cid, via ) ) ->
                G.node id g
                    |> Maybe.andThen
                        (\n ->
                            if passes n then
                                Just { node = n, score = s, chunk = cid |> Maybe.andThen (\c -> Array.get c chunks), via = via }

                            else
                                Nothing
                        )
            )
        |> List.sortBy (\h -> ( -h.score, h.node.id ))
        |> List.take opts.limit


kindFilterName : NodeKind -> String
kindFilterName k =
    case k of
        Plan ->
            "plan"

        DocSection ->
            "doc"

        Invariant ->
            "invariant"

        Flag ->
            "flag"

        Concept ->
            "concept"

        _ ->
            "code"



-- CONTEXT HELPERS


{-| The plans that mention a node, or a definition in it. -}
plansFor : Graph -> String -> List Node
plansFor g id =
    mentionersOf g id |> List.filter (\n -> n.kind == Plan)


invariantsFor : Graph -> String -> List Node
invariantsFor g id =
    mentionersOf g id |> List.filter (\n -> n.kind == Invariant)


mentionersOf : Graph -> String -> List Node
mentionersOf g id =
    let
        targets =
            id :: (G.outgoing id g |> List.filter (\e -> e.kind == "defines") |> List.map .to)
    in
    targets
        |> List.concatMap (\t -> G.incoming t g |> List.filter (\e -> e.kind == "mentions") |> List.map .from)
        |> dedupe
        |> List.filterMap (\x -> G.node x g)


{-| The flags gating a node or its definitions. -}
gatedBy : Graph -> String -> List ( String, String )
gatedBy g id =
    let
        targets =
            id :: (G.outgoing id g |> List.filter (\e -> e.kind == "defines") |> List.map .to)
    in
    targets
        |> List.concatMap (\t -> G.incoming t g |> List.filter (\e -> e.kind == "gates") |> List.map (\e -> ( e.from, t )))
        |> dedupe



{-| The plans that mention the code of a stage, with how many of its nodes
(and their definitions) each mentions, open plans first.
-}
plansForStage : Graph -> String -> List ( Node, Int )
plansForStage g stageId =
    let
        members =
            G.incoming stageId g |> List.filter (\e -> e.kind == "in_stage") |> List.map .from

        targets =
            members ++ List.concatMap (\m -> G.outgoing m g |> List.filter (\e -> e.kind == "defines") |> List.map .to) members

        counts =
            targets
                |> List.concatMap (\t -> G.incoming t g |> List.filter (\e -> e.kind == "mentions") |> List.map .from)
                |> List.filter (String.startsWith "plan:")
                |> List.foldl (\p d -> Dict.update p (\v -> Just (Maybe.withDefault 0 v + 1)) d) Dict.empty

        isOpen n =
            List.member (Dict.get "status" n.props |> Maybe.withDefault "") [ "partial", "not-started" ]
    in
    Dict.toList counts
        |> List.filterMap (\( p, c ) -> G.node p g |> Maybe.map (\n -> ( n, c )))
        |> List.sortBy
            (\( n, c ) ->
                ( if isOpen n then
                    0

                  else
                    1
                , -c
                , n.id
                )
            )
