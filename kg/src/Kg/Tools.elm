module Kg.Tools exposing (View, tools, call, instructions, overview, inactiveInstructions, isoDate)

{-| The MCP tools (§14.2 of the plan): their schemas, and what each returns,
as Markdown within its budget. Pure.
-}

import Array exposing (Array)
import Dict exposing (Dict)
import Json.Encode as E
import Kg.Args as Args exposing (Args)
import Kg.Graph as G exposing (Edge, Graph, Node, NodeKind(..))
import Kg.History exposing (History)
import Kg.Query as Q
import Kg.Render as R
import Kg.Search.Bm25 as Bm25
import Kg.Search.Chunks exposing (Chunk)
import Kg.Stages as Stages
import Mcp.Protocol as P
import Time


type alias View =
    { graph : Graph
    , history : History
    , chunks : Array Chunk
    , bm25 : Bm25.Index
    , freshness : String
    }



-- SCHEMAS


obj : List ( String, E.Value ) -> List String -> E.Value
obj props required =
    E.object
        [ ( "type", E.string "object" )
        , ( "properties", E.object props )
        , ( "required", E.list E.string required )
        , ( "additionalProperties", E.bool False )
        ]


str : String -> E.Value
str description =
    E.object [ ( "type", E.string "string" ), ( "description", E.string description ) ]


intIn : Int -> Int -> Int -> String -> E.Value
intIn lo hi default description =
    E.object [ ( "type", E.string "integer" ), ( "minimum", E.int lo ), ( "maximum", E.int hi ), ( "default", E.int default ), ( "description", E.string description ) ]


enumOf : List String -> String -> E.Value
enumOf values description =
    E.object [ ( "type", E.string "string" ), ( "enum", E.list E.string values ), ( "description", E.string description ) ]


arrayOf : E.Value -> String -> E.Value
arrayOf item description =
    E.object [ ( "type", E.string "array" ), ( "items", item ), ( "description", E.string description ) ]


locateKinds : List String
locateKinds =
    [ "code", "plan", "doc", "invariant", "flag", "concept" ]


edgeKinds : List String
edgeKinds =
    [ "imports", "includes", "uses_symbol", "kernel", "member", "links", "calls", "uses_type", "defines", "in_stage", "mentions", "supersedes", "gates", "produces", "consumes", "implements", "measures", "configures", "consumes_facts_of" ]


nodeArg : String
nodeArg =
    "A node: an id (`Compiler.Monomorphize.EntryPrep`, `cpp:pass:EcoGCPrepare`, `plan:<file>`, `inv:<ID>`, `flag:<path>`, `stage:<key>`, `Module#name` for a definition), a module's short name, a label, or a file path."


tools : List P.Tool
tools =
    [ { name = "overview"
      , description = "The full map of the eco compiler: stages in order with their entry modules and what they consume and produce, the foundations, the config flags that gate passes, and the open plans by stage. Call it first when orienting."
      , inputSchema = obj [] []
      }
    , { name = "locate"
      , description = "Find where something is in the compiler by meaning, not exact text: modules, definitions, plans, design docs, invariants and config flags, ranked and grouped by stage. Prefer this to grep for concepts (\"escape analysis\", \"lambda set member id\")."
      , inputSchema =
            obj
                [ ( "query", str "What to look for, in words or names." )
                , ( "kinds", arrayOf (E.object [ ( "type", E.string "string" ), ( "enum", E.list E.string locateKinds ) ]) "Only these kinds of node." )
                , ( "stage", str "Only nodes in this stage (a stage key such as `mono` or `genmlir`)." )
                , ( "limit", intIn 1 30 10 "How many nodes." )
                , ( "includeSuperseded", E.object [ ( "type", E.string "boolean" ), ( "description", E.string "Include superseded and abandoned plans." ) ] )
                ]
                [ "query" ]
      }
    , { name = "context"
      , description = "Everything about one node: its stage and files, signature and doc, what it depends on and what uses it, the flags gating it, the plans and invariants about it, what it changes with, and its history in one line."
      , inputSchema = obj [ ( "node", str nodeArg ) ] [ "node" ]
      }
    , { name = "neighbours"
      , description = "The edges around a node, grouped by kind and direction, up to three steps away: imports, includes, symbol uses, kernel calls, calls, mentions, gates and more."
      , inputSchema =
            obj
                [ ( "node", str nodeArg )
                , ( "direction", enumOf [ "out", "in", "both" ] "Edges out of the node (what it uses), into it (what uses it), or both. Default both." )
                , ( "depth", intIn 1 3 1 "How many steps." )
                , ( "kinds", arrayOf (E.object [ ( "type", E.string "string" ), ( "enum", E.list E.string edgeKinds ) ]) "Only these edge kinds." )
                , ( "limit", intIn 1 200 50 "How many edges." )
                ]
                [ "node" ]
      }
    , { name = "path"
      , description = "How one node reaches another: up to three shortest dependency paths (imports, includes, symbol uses, kernel calls, calls, type uses), at most eight steps."
      , inputSchema =
            obj
                [ ( "from", str nodeArg )
                , ( "to", str nodeArg )
                , ( "via", arrayOf (E.object [ ( "type", E.string "string" ), ( "enum", E.list E.string edgeKinds ) ]) "Edge kinds to follow; default the dependency kinds." )
                ]
                [ "from", "to" ]
      }
    , { name = "history"
      , description = "How a node got the way it is: when it appeared and was last changed, its renames, how often it changes, the most recent commits touching it, and what changes with it most."
      , inputSchema = obj [ ( "node", str nodeArg ), ( "limit", intIn 1 50 15 "How many recent commits." ) ] [ "node" ]
      }
    , { name = "layering"
      , description = "The dependency edges between pipeline stages, grouped by direction (later stage on earlier, earlier on later, foundation on a stage, a stage on the driver), with counts and examples. It reports; it does not judge."
      , inputSchema = obj [ ( "stage", str "Only edges into or out of this stage." ) ] []
      }
    ]



-- INSTRUCTIONS


stageLine : Graph -> Stages.Stage -> String
stageLine g s =
    "- `" ++ s.key ++ "` " ++ s.title ++ (case s.entry of
        Just e ->
            if Dict.member e g.nodes || Dict.isEmpty g.nodes then
                ", entry `" ++ e ++ "`"

            else
                ""

        Nothing ->
            ""
    ) ++ ": " ++ s.blurb


{-| The short form, sent with `initialize`; at most 4,000 characters. -}
instructions : Graph -> String
instructions g =
    String.join "\n"
        [ "eco-kg answers questions about the eco compiler's structure, history and documentation."
        , ""
        , "Call it before Grep, Glob or Read when a question is about the compiler's structure, where something is, how parts connect, which plans, design docs or invariants cover something, which config flags gate it, or what changed:"
        , "- A question names a module, definition, file, plan or flag: call `context` on it first. One call gives its stage, files (path:line), signature, doc, what it depends on and what uses it, the flags gating it, the plans and invariants about it, what it changes with, and its history."
        , "- A question uses a concept or a word, not a name (\"escape analysis\", \"flags decoder\", \"lambda-set member id\"): call `locate`; it searches code docs, plans, design docs, invariants and flags at once, where grep finds only the exact word."
        , "- The plans about a part of the pipeline (\"open plans on the runtime\"): `context` on `stage:<key>` lists the plans that mention its code, open ones first."
        , "- How two parts connect: `path`; what is around a node: `neighbours`; how it got that way and what changes with it: `history`; dependencies between stages: `layering`."
        , "- Design docs and plans can be older than the code: when they disagree, the code at the path:line given is right."
        , "eco-kg is built from the code itself, parsed and linked at HEAD with uncommitted edits included, so its path:line locations are exact: open those lines directly with Read rather than searching again with Grep or Glob, and read only what you need to confirm. Every path is relative to the worktree."
        , ""
        , "The pipeline, in order (row 0 is the shared front end and the JavaScript path; the typed path branches after Local optimize):"
        , Stages.stages |> List.map (stageLine g) |> String.join "\n"
        , "- `foundation`: Elm modules every stage uses; `cppfound`: the heap value model and the runtime ABI."
        , ""
        , "Call `overview` for the full map."
        ]


inactiveInstructions : String -> String
inactiveInstructions why =
    "eco-kg is inactive here: " ++ String.trim why ++ ". It only works inside an eco-compiler worktree; every tool call returns an error."



-- OVERVIEW


{-| The full form of the map: the stages with their jobs, what they consume and
produce, the foundations, the gating flags and the open plans by stage.
-}
overview : View -> String
overview v =
    let
        g =
            v.graph

        labelOf id =
            G.node id g |> Maybe.map .label |> Maybe.withDefault id

        flowOf key kind =
            G.outgoing ("stage:" ++ key) g |> List.filter (\e -> e.kind == kind) |> List.map (\e -> "`" ++ shortDef e.to ++ "`") |> List.take 8

        stageBlock s =
            let
                modules =
                    G.incoming ("stage:" ++ s.key) g |> List.filter (\e -> e.kind == "in_stage") |> List.length

                consumes =
                    flowOf s.key "consumes"

                produces =
                    flowOf s.key "produces"
            in
            "### " ++ s.title ++ " (`" ++ s.key ++ "`, " ++ String.fromInt modules ++ " nodes)\n"
                ++ s.blurb
                ++ (case s.entry of
                        Just e ->
                            ". Entry: `" ++ e ++ "`" ++ (G.node e g |> Maybe.andThen (\n -> List.head n.paths) |> Maybe.map (\p -> " (" ++ p ++ ")") |> Maybe.withDefault "")

                        Nothing ->
                            ""
                   )
                ++ (if List.isEmpty consumes then
                        ""

                    else
                        "\n- consumes " ++ String.join ", " consumes
                   )
                ++ (if List.isEmpty produces then
                        ""

                    else
                        "\n- produces " ++ String.join ", " produces
                   )

        foundationGroups =
            G.incoming "stage:foundation" g
                |> List.filterMap (\e -> G.node e.from g)
                |> List.map (\n -> Dict.get "group" n.props |> Maybe.withDefault n.label)
                |> countBy
                |> List.sortBy (\( _, n ) -> -n)
                |> List.take 12
                |> List.map (\( grp, n ) -> grp ++ " (" ++ String.fromInt n ++ ")")

        gatingFlags =
            G.nodes g
                |> List.filter (\n -> n.kind == Flag)
                |> List.map (\n -> ( n, G.outgoing n.id g |> List.filter (\e -> e.kind == "gates") |> List.length ))
                |> List.filter (\( _, c ) -> c > 0)
                |> List.sortBy (\( n, c ) -> ( -c, n.id ))
                |> List.take 20
                |> List.map (\( n, c ) -> "`" ++ n.label ++ "` = " ++ (Dict.get "default" n.props |> Maybe.withDefault "?") ++ " (" ++ String.fromInt c ++ " reads)")

        openPlans =
            G.nodes g
                |> List.filter (\n -> n.kind == Plan && List.member (Dict.get "status" n.props |> Maybe.withDefault "") [ "partial", "not-started" ])
                |> List.map
                    (\n ->
                        let
                            stage =
                                G.outgoing n.id g
                                    |> List.filter (\e -> e.kind == "mentions")
                                    |> List.filterMap (\e -> G.node e.to g |> Maybe.andThen .stage)
                                    |> countBy
                                    |> List.sortBy (\( _, c ) -> -c)
                                    |> List.head
                                    |> Maybe.map Tuple.first
                                    |> Maybe.withDefault "unplaced"
                        in
                        ( stage, n )
                    )

        plansByStage =
            (Stages.stageKeys ++ [ "unplaced" ])
                |> List.filterMap
                    (\key ->
                        case List.filter (\( s, _ ) -> s == key) openPlans of
                            [] ->
                                Nothing

                            ps ->
                                Just
                                    ("- " ++ Stages.stageTitle key ++ ": "
                                        ++ (ps |> List.map (\( _, n ) -> "`" ++ String.dropLeft 5 n.id ++ "` (" ++ (Dict.get "status" n.props |> Maybe.withDefault "") ++ ")") |> String.join ", ")
                                    )
                    )
    in
    R.clip <|
        String.join "\n\n"
            [ v.freshness
            , "# The eco compiler\n\nThe stages in pipeline order. Row 0 is the shared front end plus the erased JavaScript path; the typed path branches off after Local optimize."
            , Stages.stages |> List.map stageBlock |> String.join "\n\n"
            , "### Foundations\n- Elm foundation, by group: " ++ String.join ", " foundationGroups ++ "\n- C++ foundation: " ++ (Stages.cppFound |> List.map (\( _, t, ids ) -> t ++ " (" ++ String.join ", " (List.map labelOf ids) ++ ")") |> String.join "; ")
            , "### Config flags that gate code (Compiler/Eco/Config.elm)\n" ++ String.join "\n" (List.map (\l -> "- " ++ l) gatingFlags)
            , "### Open plans, by the stage they mention most\n" ++ R.cutLines 3000 plansByStage
            ]


shortDef : String -> String
shortDef id =
    case String.split "#" id of
        [ m, d ] ->
            (String.split "." m |> List.reverse |> List.head |> Maybe.withDefault m) ++ "." ++ d

        _ ->
            id


countBy : List comparable -> List ( comparable, Int )
countBy xs =
    List.foldl (\x d -> Dict.update x (\v -> Just (Maybe.withDefault 0 v + 1)) d) Dict.empty xs |> Dict.toList



-- CALLS


call : View -> List Int -> String -> E.Value -> P.ToolResult
call v vectorRanks name arguments =
    let
        run known f =
            case Args.parse known arguments |> Result.andThen f of
                Ok text ->
                    P.textResult (R.clip text)

                Err why ->
                    P.errorResult why
    in
    case name of
        "overview" ->
            run [] (\_ -> Ok (overview v))

        "locate" ->
            run [ "query", "kinds", "stage", "limit", "includeSuperseded" ] (locateTool v vectorRanks)

        "context" ->
            run [ "node" ] (contextTool v)

        "neighbours" ->
            run [ "node", "direction", "depth", "kinds", "limit" ] (neighboursTool v)

        "path" ->
            run [ "from", "to", "via" ] (pathTool v)

        "history" ->
            run [ "node", "limit" ] (historyTool v)

        "layering" ->
            run [ "stage" ] (layeringTool v)

        _ ->
            P.errorResult ("no tool " ++ name)


withNode : View -> String -> (Node -> Result String String) -> Result String String
withNode v arg f =
    case Q.resolve v.graph v.bm25 v.chunks arg of
        Q.Found n ->
            f n

        Q.Candidates [] ->
            Ok (v.freshness ++ "\n\nNo node matches `" ++ arg ++ "`. Try `locate`.")

        Q.Candidates cs ->
            Ok (v.freshness ++ "\n\n`" ++ arg ++ "` is not one node. Candidates:\n" ++ String.join "\n" (List.map (\n -> "- " ++ nodeLine n) cs))


location : Node -> String
location n =
    case ( List.head n.paths, n.line ) of
        ( Just p, Just l ) ->
            p ++ ":" ++ String.fromInt l

        ( Just p, Nothing ) ->
            String.join ", " (List.take 3 n.paths) ++ (if List.length n.paths > 3 then ", …" else "")

        _ ->
            ""


nodeLine : Node -> String
nodeLine n =
    "`" ++ n.id ++ "` (" ++ G.kindName n.kind ++ (n.stage |> Maybe.map (\s -> ", " ++ s) |> Maybe.withDefault "") ++ ")" ++ (if location n /= "" then " " ++ location n else "")


firstLine : String -> String
firstLine s =
    String.lines s |> List.filter (\l -> String.trim l /= "") |> List.head |> Maybe.withDefault "" |> String.left 200


locateTool : View -> List Int -> Args -> Result String String
locateTool v vectorRanks args =
    Result.map5
        (\query kinds stage limit includeSuperseded ->
            let
                hits =
                    Q.locate v.graph v.bm25 v.chunks vectorRanks query { kinds = kinds, stage = stage, limit = limit, includeSuperseded = includeSuperseded }

                stageKey h =
                    h.node.stage |> Maybe.withDefault (if h.node.kind == Plan || h.node.kind == DocSection || h.node.kind == Invariant || h.node.kind == Flag || h.node.kind == Concept then G.kindName h.node.kind else "other")

                groups =
                    hits
                        |> List.indexedMap Tuple.pair
                        |> List.foldl (\( i, h ) acc -> Dict.update (stageKey h) (\l -> Just (Maybe.withDefault [] l ++ [ ( i, h ) ])) acc) Dict.empty
                        |> Dict.toList
                        |> List.sortBy (\( _, hs ) -> List.head hs |> Maybe.map Tuple.first |> Maybe.withDefault 0)

                hitLine ( i, h ) =
                    String.fromInt (i + 1) ++ ". " ++ nodeLine h.node
                        ++ (case Dict.get "status" h.node.props of
                                Just st ->
                                    " [" ++ st ++ "]"

                                Nothing ->
                                    ""
                           )
                        ++ (case ( h.chunk, h.via ) of
                                ( Just c, _ ) ->
                                    "\n   " ++ String.left 200 (String.replace "\n" " " (dropHeader c.text))

                                ( Nothing, Just via ) ->
                                    "\n   (via `" ++ via ++ "`)"

                                _ ->
                                    ""
                           )

                body =
                    groups
                        |> List.concatMap (\( key, hs ) -> ("**" ++ Stages.stageTitle key ++ "**") :: List.map hitLine hs)
            in
            v.freshness
                ++ "\n\n"
                ++ (if List.isEmpty hits then
                        "Nothing found for \"" ++ query ++ "\"."

                    else
                        "Ranked " ++ (if List.isEmpty vectorRanks then "by keywords (the embedding server is not running)" else "by keywords and meaning") ++ " for \"" ++ query ++ "\":\n\n" ++ R.cutLines (R.budget limit 10) body
                   )
        )
        (Args.requiredString "query" args)
        (Args.enumList "kinds" locateKinds args)
        (Args.string "stage" args)
        (Args.int "limit" 1 30 10 args)
        (Args.bool "includeSuperseded" False args)


dropHeader : String -> String
dropHeader text =
    case String.split "\n" text of
        _ :: (rest :: more) ->
            String.join " " (rest :: more)

        [ only ] ->
            only

        [] ->
            ""


edgeTarget : Graph -> String -> String
edgeTarget g id =
    case G.node id g of
        Just n ->
            case n.kind of
                Definition ->
                    shortDef id

                _ ->
                    n.label

        Nothing ->
            id


groupEdges : Graph -> (Edge -> String) -> List Edge -> List String
groupEdges g other edges =
    edges
        |> List.foldl (\e acc -> Dict.update e.kind (\l -> Just (Maybe.withDefault [] l ++ [ e ])) acc) Dict.empty
        |> Dict.toList
        |> List.map
            (\( kind, es ) ->
                "- " ++ kind ++ " (" ++ String.fromInt (List.length es) ++ "): "
                    ++ (List.take 30 es |> List.map (\e -> edgeTarget g (other e)) |> String.join ", ")
                    ++ (if List.length es > 30 then
                            ", … " ++ String.fromInt (List.length es - 30) ++ " more"

                        else
                            ""
                       )
            )


contextTool : View -> Args -> Result String String
contextTool v args =
    Args.requiredString "node" args
        |> Result.andThen
            (\arg ->
                withNode v arg
                    (\n ->
                        let
                            g =
                                v.graph

                            prop k =
                                Dict.get k n.props

                            out =
                                G.outgoing n.id g |> List.filter (\e -> not (List.member e.kind [ "in_stage", "defines", "gates" ]))

                            readBy =
                                G.outgoing n.id g |> List.filter (\e -> e.kind == "gates")

                            inn =
                                G.incoming n.id g |> List.filter (\e -> not (List.member e.kind [ "in_stage", "defines" ]))

                            defines =
                                G.outgoing n.id g |> List.filter (\e -> e.kind == "defines")

                            gated =
                                Q.gatedBy g n.id

                            plans =
                                Q.plansFor g n.id

                            invariants =
                                Q.invariantsFor g n.id

                            hs =
                                Q.historyOf v.history n.id 3

                            section title body =
                                if List.isEmpty body then
                                    []

                                else
                                    ("**" ++ title ++ "**") :: body

                            date c =
                                isoDate c.time

                            historyLine =
                                if hs.editCount == 0 then
                                    []

                                else
                                    [ "**History** " ++ String.fromInt hs.editCount ++ " commits"
                                        ++ (hs.first |> Maybe.map (\( _, c ) -> "; first " ++ date c) |> Maybe.withDefault "")
                                        ++ (hs.last |> Maybe.map (\( _, c ) -> "; last " ++ date c ++ " " ++ String.left 10 c.hash ++ " " ++ c.subject) |> Maybe.withDefault "")
                                        ++ (if List.isEmpty hs.renames then "" else "; renamed from " ++ String.join ", " (List.map Tuple.second hs.renames))
                                    ]

                            parts =
                                [ [ "# " ++ n.label
                                  , G.kindName n.kind ++ (n.stage |> Maybe.map (\s -> " in " ++ Stages.stageTitle s ++ " (`" ++ s ++ "`)") |> Maybe.withDefault "") ++ " · `" ++ n.id ++ "`"
                                  , "Files: " ++ (if location n == "" then "none" else location n)
                                  ]
                                , case prop "signature" of
                                    Just s ->
                                        [ "**Signature** `" ++ s ++ "`" ]

                                    Nothing ->
                                        []
                                , n.props
                                    |> Dict.toList
                                    |> List.filter (\( k, _ ) -> List.member k [ "status", "updated", "remaining", "superseded_by", "default", "type", "category", "phase", "source", "entry", "aliases" ])
                                    |> List.map (\( k, val ) -> "- " ++ k ++ ": " ++ String.left 300 val)
                                , case n.doc of
                                    Just d ->
                                        [ "**Doc**", String.left 1500 d ++ (if String.length d > 1500 then " …" else "") ]

                                    Nothing ->
                                        []
                                , section "Defines" (if List.isEmpty defines then [] else [ (List.take 40 defines |> List.map (\e -> edgeTarget g e.to) |> String.join ", ") ++ (if List.length defines > 40 then ", … " ++ String.fromInt (List.length defines - 40) ++ " more" else "") ])
                                , section "Depends on" (groupEdges g .to out)
                                , section "Read by" (if List.isEmpty readBy then [] else [ (List.take 30 readBy |> List.map (\e -> edgeTarget g e.to ++ (e.line |> Maybe.map (\l -> " (" ++ (G.node e.to g |> Maybe.andThen (\x -> List.head x.paths) |> Maybe.withDefault "") ++ ":" ++ String.fromInt l ++ ")") |> Maybe.withDefault "")) |> String.join ", ") ++ (if List.length readBy > 30 then ", … " ++ String.fromInt (List.length readBy - 30) ++ " more" else "") ])
                                , section "Used by" (groupEdges g .from inn)
                                , section "Gated by" (List.map (\( flag, def ) -> "- `" ++ String.dropLeft 5 flag ++ "` (read in " ++ shortDef def ++ ")") (List.take 15 gated))
                                , section "Plans" (List.map (\p -> "- `" ++ String.dropLeft 5 p.id ++ "` [" ++ (Dict.get "status" p.props |> Maybe.withDefault "?") ++ "] " ++ p.label) (List.take 15 plans))
                                , if n.kind == Stage then
                                    section "Plans about this stage's code (open first; count of its nodes mentioned)"
                                        (Q.plansForStage g n.id
                                            |> List.take 40
                                            |> List.map (\( p, c ) -> "- `" ++ String.dropLeft 5 p.id ++ "` [" ++ (Dict.get "status" p.props |> Maybe.withDefault "?") ++ "] " ++ String.fromInt c ++ ": " ++ p.label)
                                        )

                                  else
                                    []
                                , section "Invariants" (List.map (\i -> "- " ++ i.label ++ " [" ++ (Dict.get "status" i.props |> Maybe.withDefault "") ++ "] " ++ String.left 120 (Maybe.withDefault "" i.doc)) (List.take 15 invariants))
                                , section "Changes with" (List.map (partnerLine g) (List.take 5 hs.partners))
                                , historyLine
                                ]
                        in
                        Ok (v.freshness ++ "\n\n" ++ R.cutLines R.defaultBudget (List.concat parts))
                    )
            )


neighboursTool : View -> Args -> Result String String
neighboursTool v args =
    Result.map5
        (\arg direction depth kinds limit -> ( arg, ( direction, depth ), ( kinds, limit ) ))
        (Args.requiredString "node" args)
        (Args.enum "direction" [ "out", "in", "both" ] "both" args)
        (Args.int "depth" 1 3 1 args)
        (Args.enumList "kinds" edgeKinds args)
        (Args.int "limit" 1 200 50 args)
        |> Result.andThen
            (\( arg, ( direction, depth ), ( kinds, limit ) ) ->
                withNode v arg
                    (\n ->
                        let
                            ns =
                                Q.neighbours v.graph n.id direction depth kinds

                            shown =
                                List.take limit ns

                            groups =
                                shown
                                    |> List.foldl (\x acc -> Dict.update ( x.direction, x.edge.kind ) (\l -> Just (Maybe.withDefault [] l ++ [ x ])) acc) Dict.empty
                                    |> Dict.toList

                            lineOf x =
                                "- " ++ (if x.depth > 1 then String.repeat (x.depth - 1) "  " ++ "↳ " else "") ++ edgeTarget v.graph x.other
                                    ++ (G.node x.other v.graph |> Maybe.map (\o -> " (" ++ G.kindName o.kind ++ (o.stage |> Maybe.map (\s -> ", " ++ s) |> Maybe.withDefault "") ++ ")" ++ (if location o /= "" then " " ++ location o else "")) |> Maybe.withDefault "")

                            body =
                                groups
                                    |> List.concatMap
                                        (\( ( dir, kind ), xs ) ->
                                            ("**" ++ kind ++ (if dir == "out" then " →" else " ←") ++ "** (" ++ String.fromInt (List.length xs) ++ ")") :: List.map lineOf xs
                                        )
                        in
                        Ok
                            (v.freshness ++ "\n\n# " ++ n.label ++ " (`" ++ n.id ++ "`): " ++ String.fromInt (List.length ns) ++ " neighbours"
                                ++ (if List.length ns > limit then " (showing " ++ String.fromInt limit ++ "; … " ++ String.fromInt (List.length ns - limit) ++ " more, raise limit)" else "")
                                ++ "\n\n" ++ R.cutLines (R.budget limit 50) body
                            )
                    )
            )


pathTool : View -> Args -> Result String String
pathTool v args =
    Result.map3 (\a b via -> ( a, b, via ))
        (Args.requiredString "from" args)
        (Args.requiredString "to" args)
        (Args.enumList "via" edgeKinds args)
        |> Result.andThen
            (\( fromArg, toArg, via ) ->
                withNode v fromArg
                    (\from ->
                        withNode v toArg
                            (\to ->
                                let
                                    kinds =
                                        if List.isEmpty via then
                                            Q.dependencyKinds

                                        else
                                            via

                                    ps =
                                        Q.paths v.graph from.id to.id kinds

                                    render p =
                                        edgeTarget v.graph from.id :: List.map (\e -> "-" ++ e.kind ++ "→ " ++ edgeTarget v.graph e.to) p |> String.join " "
                                in
                                Ok
                                    (v.freshness ++ "\n\n"
                                        ++ (if List.isEmpty ps then
                                                "No path from `" ++ from.id ++ "` to `" ++ to.id ++ "` along " ++ String.join ", " kinds ++ " within 8 steps."

                                            else
                                                String.join "\n" (List.indexedMap (\i p -> String.fromInt (i + 1) ++ ". " ++ render p) ps)
                                           )
                                    )
                            )
                    )
            )


historyTool : View -> Args -> Result String String
historyTool v args =
    Result.map2 Tuple.pair (Args.requiredString "node" args) (Args.int "limit" 1 50 15 args)
        |> Result.andThen
            (\( arg, limit ) ->
                withNode v arg
                    (\n ->
                        let
                            hs =
                                Q.historyOf v.history n.id limit

                            commitLine c =
                                "- " ++ isoDate c.time ++ " " ++ String.left 10 c.hash ++ " " ++ c.subject
                        in
                        Ok
                            (R.cutLines R.hardMax
                                ([ v.freshness, "", "# History of " ++ n.label ++ " (`" ++ n.id ++ "`)" ]
                                    ++ [ "- first seen: " ++ (hs.first |> Maybe.map (\( _, c ) -> isoDate c.time ++ " " ++ String.left 10 c.hash ++ " " ++ c.subject) |> Maybe.withDefault "never (not in the indexed history)")
                                       , "- last changed: " ++ (hs.last |> Maybe.map (\( _, c ) -> isoDate c.time ++ " " ++ String.left 10 c.hash ++ " " ++ c.subject) |> Maybe.withDefault "—")
                                       , "- commits touching it: " ++ String.fromInt hs.editCount
                                       ]
                                    ++ (if List.isEmpty hs.renames then [] else [ "- renamed: " ++ String.join "; " (List.map (\( c, old ) -> "from `" ++ old ++ "` in " ++ String.left 10 c.hash ++ " (" ++ isoDate c.time ++ ")") hs.renames) ])
                                    ++ (if List.isEmpty hs.recent then [] else "" :: "**Most recent commits**" :: List.map commitLine hs.recent)
                                    ++ (if List.isEmpty hs.partners then [] else "" :: "**Changes most with** (commits touching both; commits touching over 50 modules are not counted)" :: List.map (partnerLine v.graph) hs.partners)
                                )
                            )
                    )
            )


layeringTool : View -> Args -> Result String String
layeringTool v args =
    Args.string "stage" args
        |> Result.map
            (\stage ->
                let
                    groups =
                        Q.layering v.graph stage

                    stageOf id =
                        G.node id v.graph |> Maybe.andThen .stage |> Maybe.withDefault "?"

                    edgeLine e =
                        "  - " ++ edgeTarget v.graph e.from ++ " (" ++ stageOf e.from ++ ") -" ++ e.kind ++ "→ " ++ edgeTarget v.graph e.to ++ " (" ++ stageOf e.to ++ ")"
                in
                v.freshness ++ "\n\nDependency edges between stages" ++ (stage |> Maybe.map (\s -> ", into or out of `" ++ s ++ "`") |> Maybe.withDefault "") ++ ":\n\n"
                    ++ R.cutLines R.defaultBudget
                        (groups |> List.concatMap (\grp -> ("- **" ++ grp.name ++ "**: " ++ String.fromInt grp.count) :: List.map edgeLine (List.take 20 grp.edges)))
            )


partnerLine : Graph -> ( String, Int ) -> String
partnerLine g ( other, c ) =
    "- " ++ edgeTarget g other ++ ": " ++ String.fromInt c ++ " commits, "
        ++ (case G.node other g of
                Just n ->
                    location n

                Nothing ->
                    "`" ++ other ++ "` (no longer exists)"
           )


isoDate : Int -> String
isoDate seconds =
    let
        t =
            Time.millisToPosix (seconds * 1000)

        pad n =
            String.padLeft 2 '0' (String.fromInt n)
    in
    String.fromInt (Time.toYear Time.utc t) ++ "-" ++ pad (monthNumber (Time.toMonth Time.utc t)) ++ "-" ++ pad (Time.toDay Time.utc t)


monthNumber : Time.Month -> Int
monthNumber m =
    case m of
        Time.Jan ->
            1

        Time.Feb ->
            2

        Time.Mar ->
            3

        Time.Apr ->
            4

        Time.May ->
            5

        Time.Jun ->
            6

        Time.Jul ->
            7

        Time.Aug ->
            8

        Time.Sep ->
            9

        Time.Oct ->
            10

        Time.Nov ->
            11

        Time.Dec ->
            12
