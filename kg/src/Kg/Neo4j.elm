module Kg.Neo4j exposing (nodesCsv, edgesCsv)

{-| The graph as the two CSV files `neo4j-admin database import full` reads
(phase 7 of the plan): `nodes.csv` with `id:ID,:LABEL,label,stage,paths:string[]`
and `edges.csv` with `:START_ID,:END_ID,:TYPE,weight:float`.
-}

import Dict
import Kg.Graph as G exposing (Graph)


field : String -> String
field s =
    if String.any (\c -> c == ',' || c == '"' || c == '\n' || c == '\u{000D}' || c == ';') s then
        "\"" ++ String.replace "\"" "\"\"" s ++ "\""

    else
        s


label : G.NodeKind -> String
label k =
    case G.kindName k of
        "module" ->
            "Module"

        "component" ->
            "Component"

        "definition" ->
            "Definition"

        "stage" ->
            "Stage"

        "plan" ->
            "Plan"

        "doc" ->
            "DocSection"

        "invariant" ->
            "Invariant"

        "flag" ->
            "Flag"

        _ ->
            "Concept"


nodesCsv : Graph -> String
nodesCsv g =
    ("id:ID,:LABEL,label,stage,paths:string[]"
        :: (G.nodes g
                |> List.map
                    (\n ->
                        String.join ","
                            [ field n.id
                            , label n.kind
                            , field n.label
                            , field (Maybe.withDefault "" n.stage)
                            , field (String.join ";" n.paths)
                            ]
                    )
           )
    )
        |> String.join "\n"


edgesCsv : Graph -> String
edgesCsv g =
    (":START_ID,:END_ID,:TYPE,weight:float"
        :: (Dict.values g.out
                |> List.concat
                |> List.map (\e -> String.join "," [ field e.from, field e.to, String.toUpper e.kind, String.fromFloat e.weight ])
           )
    )
        |> String.join "\n"
