module Atlas.Graph exposing
    ( Graph, World, Stage, Section, Node
    , data, node, matches
    )

{-| The compiler's dependency graph, as `script/atlas-graph.py` writes it to `content/atlas/graph.json`: every Elm
module and C++ component, the stage of the pipeline it belongs to, and its place on the grid, in cells.

@docs Graph, World, Stage, Section, Node
@docs data, node, matches

-}

import Array exposing (Array)
import BackendTask exposing (BackendTask)
import BackendTask.File
import Dict exposing (Dict)
import FatalError exposing (FatalError)
import Json.Decode as Decode exposing (Decoder)


{-| The graph. `out` lists what each node imports and `inn` what imports it, both by index into `nodes` and sorted by
label. `index` finds a node by its id.
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


{-| The size of the world in cells, where its parts are, and the footprint of a node.
-}
type alias World =
    { cols : Int
    , rows : Int
    , branchFrom : String
    , branchTo : String
    , foundTop : Int
    , foundRows : Int
    , foundCols : Int
    , cppFoundCol : Int
    , cppFoundCols : Int
    , cppSections : List Section
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
    , gx : Int
    , gw : Int
    , gy : Int
    , gh : Int
    , count : Int
    }


{-| A section of the C++ foundation, and the column it starts on.
-}
type alias Section =
    { key : String
    , title : String
    , gx : Int
    }


{-| A module or C++ component.
-}
type alias Node =
    { index : Int
    , id : String
    , label : String
    , lang : String
    , stage : String
    , stageName : String
    , path : String
    , gx : Int
    , gy : Int
    }


{-| Read the graph.
-}
data : BackendTask FatalError Graph
data =
    BackendTask.File.jsonFile decoder "content/atlas/graph.json"
        |> BackendTask.allowFatal


{-| A node by index.
-}
node : Graph -> Int -> Maybe Node
node graph i =
    Array.get i graph.nodes


{-| The nodes whose labels contain a search, ignoring case.
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
        Array.toList graph.nodes |> List.filter (\n -> String.contains q (String.toLower n.label))



-- DECODING


decoder : Decoder Graph
decoder =
    Decode.map3 build
        (Decode.field "world" worldDecoder)
        (Decode.field "stages" (Decode.list stageDecoder))
        (Decode.map2 Tuple.pair
            (Decode.field "nodes" (Decode.list rawNodeDecoder))
            (Decode.field "edges" (Decode.list (Decode.map2 Tuple.pair (Decode.index 0 Decode.int) (Decode.index 1 Decode.int))))
        )


type alias RawNode =
    { label : String, lang : String, stage : String, gx : Int, gy : Int, path : String, id : String }


build : World -> List Stage -> ( List RawNode, List ( Int, Int ) ) -> Graph
build world stages ( raw, edges ) =
    let
        stageNames =
            Dict.fromList (( "foundation", "Shared foundation" ) :: List.map (\s -> ( s.key, s.title )) stages)

        stageName r =
            if r.stage == "cppfound" then
                world.cppSections
                    |> List.filter (\c -> c.gx <= r.gx)
                    |> List.reverse
                    |> List.head
                    |> Maybe.map (\c -> "C++ foundation · " ++ c.title)
                    |> Maybe.withDefault "C++ foundation"

            else
                Dict.get r.stage stageNames |> Maybe.withDefault r.stage

        nodes =
            raw
                |> List.indexedMap
                    (\i r ->
                        { index = i
                        , id = r.id
                        , label = r.label
                        , lang = r.lang
                        , stage = r.stage
                        , stageName = stageName r
                        , path = r.path
                        , gx = r.gx
                        , gy = r.gy
                        }
                    )
                |> Array.fromList

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
    , out = List.foldl add empty edges |> Array.map byLabel
    , inn = List.foldl (\( a, b ) -> add ( b, a )) empty edges |> Array.map byLabel
    , index = Array.toList nodes |> List.map (\n -> ( n.id, n.index )) |> Dict.fromList
    }


worldDecoder : Decoder World
worldDecoder =
    Decode.succeed World
        |> field "cols" Decode.int
        |> field "rows" Decode.int
        |> andMap (Decode.field "branch" (Decode.index 0 Decode.string))
        |> andMap (Decode.field "branch" (Decode.index 1 Decode.string))
        |> field "foundTop" Decode.int
        |> field "foundRows" Decode.int
        |> field "foundCols" Decode.int
        |> andMap (Decode.at [ "cppFound", "gx" ] Decode.int)
        |> andMap (Decode.at [ "cppFound", "gw" ] Decode.int)
        |> andMap
            (Decode.at [ "cppFound", "sections" ]
                (Decode.list
                    (Decode.map3 Section
                        (Decode.field "key" Decode.string)
                        (Decode.field "title" Decode.string)
                        (Decode.field "gx" Decode.int)
                    )
                )
            )
        |> field "nodeW" Decode.int
        |> field "nodeH" Decode.int


stageDecoder : Decoder Stage
stageDecoder =
    Decode.succeed Stage
        |> field "key" Decode.string
        |> field "title" Decode.string
        |> field "blurb" Decode.string
        |> field "lang" Decode.string
        |> field "row" Decode.int
        |> field "gx" Decode.int
        |> field "gw" Decode.int
        |> field "gy" Decode.int
        |> field "gh" Decode.int
        |> field "count" Decode.int


rawNodeDecoder : Decoder RawNode
rawNodeDecoder =
    Decode.succeed RawNode
        |> andMap (Decode.index 0 Decode.string)
        |> andMap (Decode.index 1 Decode.string)
        |> andMap (Decode.index 2 Decode.string)
        |> andMap (Decode.index 3 Decode.int)
        |> andMap (Decode.index 4 Decode.int)
        |> andMap (Decode.index 5 Decode.string)
        |> andMap (Decode.index 6 Decode.string)


field : String -> Decoder a -> Decoder (a -> b) -> Decoder b
field name d =
    andMap (Decode.field name d)


andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap =
    Decode.map2 (|>)
