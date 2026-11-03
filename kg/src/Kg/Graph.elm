module Kg.Graph exposing
    ( Graph, Node, Edge, NodeKind(..)
    , empty, addNode, addEdge, finish
    , node, outgoing, incoming, nodes, edgeCount
    , kindName, kindFromName, dependencyKinds
    , codec, nodeCodec
    )

{-| The knowledge graph of one tree (§9.1 of the plan).

Nodes are keyed by id; edges are kept by source and by target, each list sorted
by (kind, other end), so a graph built from the same facts is the same value.
That is what the determinism check compares.

-}

import Dict exposing (Dict)
import Kg.Codec as C exposing (Codec)


type NodeKind
    = Module
    | Component
    | Definition
    | Stage
    | Plan
    | DocSection
    | Invariant
    | Flag
    | Concept


type alias Node =
    { id : String
    , kind : NodeKind
    , label : String
    , stage : Maybe String
    , paths : List String
    , line : Maybe Int
    , doc : Maybe String
    , props : Dict String String
    }


type alias Edge =
    { kind : String, from : String, to : String, weight : Float, line : Maybe Int }


type alias Graph =
    { nodes : Dict String Node
    , out : Dict String (List Edge)
    , inn : Dict String (List Edge)
    , fileNode : Dict String String
    }


empty : Graph
empty =
    { nodes = Dict.empty, out = Dict.empty, inn = Dict.empty, fileNode = Dict.empty }


addNode : Node -> Graph -> Graph
addNode n g =
    { g | nodes = Dict.insert n.id n g.nodes }


{-| Adds an edge between two nodes that exist. A second edge of the same kind
between the same nodes adds its weight to the first, and keeps the first line.
-}
addEdge : Edge -> Graph -> Graph
addEdge e g =
    if e.from == e.to || not (Dict.member e.from g.nodes) || not (Dict.member e.to g.nodes) then
        g

    else
        let
            merge list =
                case List.partition (\x -> x.kind == e.kind && x.from == e.from && x.to == e.to) list of
                    ( x :: _, rest ) ->
                        { x | weight = x.weight + e.weight } :: rest

                    ( [], rest ) ->
                        e :: rest
        in
        { g
            | out = Dict.update e.from (\l -> Just (merge (Maybe.withDefault [] l))) g.out
            , inn = Dict.update e.to (\l -> Just (merge (Maybe.withDefault [] l))) g.inn
        }


{-| Sorts every edge list; call once after the last `addEdge`. -}
finish : Graph -> Graph
finish g =
    { g
        | out = Dict.map (\_ l -> List.sortBy (\e -> ( e.kind, e.to )) l) g.out
        , inn = Dict.map (\_ l -> List.sortBy (\e -> ( e.kind, e.from )) l) g.inn
    }


node : String -> Graph -> Maybe Node
node id g =
    Dict.get id g.nodes


outgoing : String -> Graph -> List Edge
outgoing id g =
    Dict.get id g.out |> Maybe.withDefault []


incoming : String -> Graph -> List Edge
incoming id g =
    Dict.get id g.inn |> Maybe.withDefault []


nodes : Graph -> List Node
nodes g =
    Dict.values g.nodes


edgeCount : Graph -> Int
edgeCount g =
    Dict.foldl (\_ l n -> n + List.length l) 0 g.out


{-| The edge kinds that are dependencies, the default for `path`. -}
dependencyKinds : List String
dependencyKinds =
    [ "imports", "includes", "uses_symbol", "kernel", "calls", "uses_type" ]


kindName : NodeKind -> String
kindName k =
    case k of
        Module ->
            "module"

        Component ->
            "component"

        Definition ->
            "definition"

        Stage ->
            "stage"

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


kindFromName : String -> Maybe NodeKind
kindFromName s =
    List.filter (\k -> kindName k == s) allKinds |> List.head


allKinds : List NodeKind
allKinds =
    [ Module, Component, Definition, Stage, Plan, DocSection, Invariant, Flag, Concept ]



-- CODEC


kindCodec : Codec NodeKind
kindCodec =
    C.map
        (\i -> List.drop i allKinds |> List.head |> Maybe.withDefault Module)
        (\k -> List.length (takeUntil k allKinds))
        C.int


takeUntil : a -> List a -> List a
takeUntil x xs =
    case xs of
        y :: rest ->
            if y == x then
                []

            else
                y :: takeUntil x rest

        [] ->
            []


nodeCodec : Codec Node
nodeCodec =
    C.record Node
        |> C.field .id C.string
        |> C.field .kind kindCodec
        |> C.field .label C.string
        |> C.field .stage (C.maybe C.string)
        |> C.field .paths (C.list C.string)
        |> C.field .line (C.maybe C.int)
        |> C.field .doc (C.maybe C.string)
        |> C.field .props (C.dict C.string C.string)
        |> C.finish


edgeCodec : Codec Edge
edgeCodec =
    C.record Edge
        |> C.field .kind C.string
        |> C.field .from C.string
        |> C.field .to C.string
        |> C.field .weight C.float
        |> C.field .line (C.maybe C.int)
        |> C.finish


{-| Only the nodes and the outgoing edges are written; the incoming lists are
rebuilt on decode.
-}
codec : Codec Graph
codec =
    C.map
        (\( ns, outs, fileNode ) ->
            let
                inn =
                    Dict.foldl
                        (\_ es acc -> List.foldl (\e a -> Dict.update e.to (\l -> Just (e :: Maybe.withDefault [] l)) a) acc es)
                        Dict.empty
                        outs
            in
            { nodes = ns, out = outs, inn = Dict.map (\_ l -> List.sortBy (\e -> ( e.kind, e.from )) l) inn, fileNode = fileNode }
        )
        (\g -> ( g.nodes, g.out, g.fileNode ))
        (C.triple (C.dict C.string nodeCodec) (C.dict C.string (C.list edgeCodec)) (C.dict C.string C.string))
