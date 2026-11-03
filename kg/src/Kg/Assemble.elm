module Kg.Assemble exposing (assemble, ConceptSpec, resolveMention, MentionIndex, mentionIndex)

{-| The whole knowledge graph of one tree, from its module graph and its facts
(§9.1–§9.4 of the plan): the module graph's nodes and edges, the stages, the
definitions, the config flags, the plans, design doc sections and invariants,
and the curated concepts, with the edges between them.

Inferred edges (`calls`, `uses_type`, `mentions`, `gates`, `produces`,
`consumes`) come with the precision measured in phase 4, recorded in the plan.

-}

import Dict exposing (Dict)
import Kg.Facts as F exposing (ElmFacts, Exposing(..), FileFacts(..))
import Kg.Graph as G exposing (Edge, Graph, Node, NodeKind(..))
import Kg.Link exposing (ModuleGraph)
import Kg.PathUtil as P
import Kg.Re as Re
import Kg.Replay as Replay
import Kg.Stages as Stages
import Set exposing (Set)


type alias ConceptSpec =
    { slug : String, name : String, aliases : List String, summary : String, links : List { node : String, role : String } }


newNode : String -> NodeKind -> String -> Node
newNode id kind label =
    { id = id, kind = kind, label = label, stage = Nothing, paths = [], line = Nothing, doc = Nothing, props = Dict.empty }


foundationNode : String -> String -> String -> Node
foundationNode key title blurb =
    let
        n =
            newNode ("stage:" ++ key) Stage title
    in
    { n | stage = Just key, doc = Just blurb, props = Dict.fromList [ ( "order", String.fromInt (Stages.stageIndex key) ) ] }


edge : String -> String -> String -> Maybe Int -> Edge
edge kind from to line =
    { kind = kind, from = from, to = to, weight = 1, line = line }


assemble : ModuleGraph -> Dict String FileFacts -> List ConceptSpec -> Graph
assemble mg files concepts =
    let
        elmFacts : String -> Maybe ElmFacts
        elmFacts path =
            case Dict.get path files of
                Just (ElmFile f) ->
                    Just f

                _ ->
                    Nothing

        -- stages
        stageNodes =
            (Stages.stages
                |> List.map
                    (\s ->
                        let
                            n =
                                newNode ("stage:" ++ s.key) Stage s.title
                        in
                        { n
                            | stage = Just s.key
                            , doc = Just s.blurb
                            , props =
                                Dict.fromList
                                    ([ ( "lang", s.lang ), ( "row", String.fromInt s.row ), ( "order", String.fromInt (Stages.stageIndex s.key) ) ]
                                        ++ (s.entry |> Maybe.map (\e -> [ ( "entry", e ) ]) |> Maybe.withDefault [])
                                    )
                        }
                    )
            )
                ++ [ foundationNode "foundation" "Elm foundation" "Elm modules every stage uses"
                   , foundationNode "cppfound" "C++ foundation" "Heap and values, and the runtime ABI"
                   ]

        -- modules and components
        moduleNodes =
            Dict.values mg.nodes
                |> List.map
                    (\m ->
                        let
                            doc =
                                if m.lang == "elm" then
                                    m.files |> List.filterMap elmFacts |> List.filterMap .moduleDoc |> List.head

                                else
                                    m.files
                                        |> List.filterMap
                                            (\p ->
                                                case Dict.get p files of
                                                    Just (CppFile c) ->
                                                        List.head c.comments |> Maybe.map .text

                                                    _ ->
                                                        Nothing
                                            )
                                        |> List.head
                        in
                        { id = m.id
                        , kind =
                            if m.lang == "elm" then
                                Module

                            else
                                Component
                        , label = m.label
                        , stage = Just m.stage
                        , paths = m.files
                        , line = Nothing
                        , doc = doc
                        , props = Dict.fromList [ ( "group", m.group ), ( "lang", m.lang ) ]
                        }
                    )

        moduleEdges =
            Set.toList mg.edges |> List.map (\( k, a, b ) -> edge k a b Nothing)

        inStage =
            Dict.values mg.nodes |> List.map (\m -> edge "in_stage" m.id ("stage:" ++ m.stage) Nothing)

        -- Elm definitions
        elmModules =
            Dict.values mg.nodes |> List.filter (\m -> m.lang == "elm")

        declsOf : Dict String (List ( String, F.Decl ))
        declsOf =
            elmModules
                |> List.map
                    (\m ->
                        ( m.id
                        , m.files
                            |> List.concatMap (\p -> elmFacts p |> Maybe.map (\f -> List.map (\d -> ( p, d )) f.decls) |> Maybe.withDefault [])
                        )
                    )
                |> Dict.fromList

        defNodes =
            Dict.toList declsOf
                |> List.concatMap
                    (\( mid, decls ) ->
                        let
                            stage =
                                Dict.get mid mg.nodes |> Maybe.map .stage
                        in
                        decls
                            |> List.map
                                (\( p, d ) ->
                                    { id = mid ++ "#" ++ d.name
                                    , kind = Definition
                                    , label = d.name
                                    , stage = stage
                                    , paths = [ p ]
                                    , line = Just d.line
                                    , doc = d.doc
                                    , props =
                                        Dict.fromList
                                            ([ ( "declKind", declKindName d.kind ), ( "module", mid ), ( "exposed", boolText d.exposed ) ]
                                                ++ (d.signature |> Maybe.map (\s -> [ ( "signature", s ) ]) |> Maybe.withDefault [])
                                            )
                                    }
                                )
                    )

        defIds =
            List.map .id defNodes |> Set.fromList

        defineEdges =
            List.map (\d -> edge "defines" (Dict.get "module" d.props |> Maybe.withDefault "") d.id d.line) defNodes

        -- C++ definitions
        cppDefNodes =
            Dict.values mg.nodes
                |> List.filter (\m -> m.lang == "cpp")
                |> List.concatMap
                    (\m ->
                        m.files
                            |> List.concatMap
                                (\p ->
                                    case Dict.get p files of
                                        Just (CppFile c) ->
                                            c.defs
                                                |> List.map
                                                    (\( ns, name ) ->
                                                        let
                                                            q =
                                                                if ns == "" then
                                                                    name

                                                                else
                                                                    ns ++ "::" ++ name
                                                        in
                                                        { id = m.id ++ "#" ++ q, kind = Definition, label = q, stage = Just m.stage, paths = [ p ], line = Nothing, doc = Nothing, props = Dict.fromList [ ( "declKind", "c++" ), ( "module", m.id ) ] }
                                                    )

                                        _ ->
                                            []
                                )
                    )
                |> dedupeBy .id

        -- calls and uses_type
        refEdges =
            elmModules |> List.concatMap (referenceEdges mg declsOf defIds elmFacts)

        -- config flags
        configFacts =
            Dict.toList files
                |> List.filterMap
                    (\( p, f ) ->
                        case f of
                            ElmFile e ->
                                if String.endsWith "Compiler/Eco/Config.elm" p && not (List.isEmpty e.config) then
                                    Just ( p, e.config )

                                else
                                    Nothing

                            _ ->
                                Nothing
                    )
                |> List.head

        flags =
            configFacts |> Maybe.map Tuple.second |> Maybe.withDefault []

        configModule =
            configFacts |> Maybe.andThen (\( p, _ ) -> Dict.get p mg.fileNode)

        flagNodes =
            flags
                |> List.map
                    (\c ->
                        let
                            path =
                                String.join "." c.path
                        in
                        { id = "flag:" ++ path
                        , kind = Flag
                        , label = path
                        , stage = Nothing
                        , paths = configFacts |> Maybe.map (\( p, _ ) -> [ p ]) |> Maybe.withDefault []
                        , line = Nothing
                        , doc =
                            if c.doc == "" then
                                Nothing

                            else
                                Just c.doc
                        , props = Dict.fromList [ ( "default", c.default ), ( "type", c.typeName ) ]
                        }
                    )

        flagDefines =
            case configModule of
                Just cm ->
                    List.map (\f -> edge "defines" cm f.id Nothing) flagNodes

                Nothing ->
                    []

        gateEdges =
            gates mg flags elmFacts defIds

        -- prose
        proseFiles =
            Dict.toList files
                |> List.filter (\( p, _ ) -> Replay.proseNodeId p /= Nothing)

        planNodes =
            proseFiles
                |> List.filterMap
                    (\( p, f ) ->
                        case ( f, Replay.proseNodeId p ) of
                            ( Markdown md, Just id ) ->
                                if String.startsWith "plan:" id then
                                    Just ( p, md, planNode id p md )

                                else
                                    Nothing

                            _ ->
                                Nothing
                    )

        docNodes =
            proseFiles
                |> List.concatMap
                    (\( p, f ) ->
                        case ( f, Replay.proseNodeId p ) of
                            ( Markdown md, Just id ) ->
                                if String.startsWith "doc:" id then
                                    md.sections
                                        |> List.map
                                            (\s ->
                                                { id = sectionId p s.path
                                                , kind = DocSection
                                                , label =
                                                    if List.isEmpty s.path then
                                                        md.title

                                                    else
                                                        String.join " › " s.path
                                                , stage = Nothing
                                                , paths = [ p ]
                                                , line = Just s.startLine
                                                , doc = Just (String.left 4000 s.text)
                                                , props = Dict.fromList [ ( "title", md.title ), ( "file", p ) ]
                                                }
                                            )
                                        |> dedupeBy .id

                                else
                                    []

                            _ ->
                                []
                    )

        invariantNodes =
            proseFiles
                |> List.concatMap
                    (\( p, f ) ->
                        case f of
                            Invariants is ->
                                is
                                    |> List.map
                                        (\i ->
                                            { id = "inv:" ++ i.id
                                            , kind = Invariant
                                            , label = i.id
                                            , stage = Nothing
                                            , paths = [ p ]
                                            , line = Just i.line
                                            , doc = Just i.description
                                            , props = Dict.fromList [ ( "phase", i.phase ), ( "category", i.category ), ( "status", i.status ), ( "source", i.source ) ]
                                            }
                                        )
                                    |> dedupeBy .id

                            _ ->
                                []
                    )

        conceptNodes =
            concepts
                |> List.map
                    (\c ->
                        { id = "concept:" ++ c.slug
                        , kind = Concept
                        , label = c.name
                        , stage = Nothing
                        , paths = [ "kg/knowledge/concepts.json" ]
                        , line = Nothing
                        , doc = Just c.summary
                        , props = Dict.fromList [ ( "aliases", String.join ", " c.aliases ) ]
                        }
                    )

        -- the graph so far, for resolving mentions
        g1 =
            List.foldl G.addNode G.empty
                (stageNodes ++ moduleNodes ++ defNodes ++ cppDefNodes ++ flagNodes ++ List.map (\( _, _, n ) -> n) planNodes ++ docNodes ++ invariantNodes ++ conceptNodes)

        fileNode =
            Dict.union mg.fileNode
                (Dict.fromList
                    (List.map (\( p, _, n ) -> ( p, n.id )) planNodes
                        ++ List.filterMap (\n -> List.head n.paths |> Maybe.map (\p -> ( p, n.id ))) (List.reverse docNodes)
                        ++ (case List.head invariantNodes of
                                Just i ->
                                    [ ( "design_docs/invariants.csv", i.id ) ]

                                Nothing ->
                                    []
                           )
                    )
                )

        index =
            mentionIndex { g1 | fileNode = fileNode }

        mentionEdges =
            (planNodes
                |> List.concatMap
                    (\( _, md, n ) -> md.mentions |> List.filterMap (\m -> resolveMention index m.target |> Maybe.map (\t -> edge "mentions" n.id t (Just m.line))))
            )
                ++ (proseFiles
                        |> List.concatMap
                            (\( p, f ) ->
                                case ( f, Replay.proseNodeId p ) of
                                    ( Markdown md, Just id ) ->
                                        if String.startsWith "doc:" id then
                                            md.mentions
                                                |> List.filterMap
                                                    (\m ->
                                                        resolveMention index m.target
                                                            |> Maybe.map (\t -> edge "mentions" (sectionAt p md m.line) t (Just m.line))
                                                    )

                                        else
                                            []

                                    _ ->
                                        []
                            )
                   )
                ++ (invariantNodes
                        |> List.concatMap
                            (\n ->
                                sourceTokens (Dict.get "source" n.props |> Maybe.withDefault "")
                                    |> List.filterMap (\tok -> resolveMention index tok |> Maybe.map (\t -> edge "mentions" n.id t Nothing))
                            )
                   )
                ++ (concepts
                        |> List.concatMap
                            (\c -> c.links |> List.map (\l -> edge l.role ("concept:" ++ c.slug) l.node Nothing))
                   )

        supersedeEdges =
            planNodes
                |> List.concatMap
                    (\( _, md, n ) ->
                        Dict.get "superseded_by" md.frontMatter
                            |> Maybe.map
                                (\text ->
                                    Re.findAll (Re.unsafe "(?:plans/)?([\\w.-]+)\\.md") text
                                        |> List.filterMap (.groups >> List.head >> Maybe.andThen identity)
                                        |> List.map (\name -> edge "supersedes" ("plan:" ++ name) n.id Nothing)
                                )
                            |> Maybe.withDefault []
                    )

        flowEdges =
            producesConsumes g1 declsOf elmFacts mg

        allEdges =
            moduleEdges ++ inStage ++ defineEdges ++ refEdges ++ flagDefines ++ gateEdges ++ mentionEdges ++ supersedeEdges ++ flowEdges ++ cppDefineEdges cppDefNodes
    in
    List.foldl G.addEdge { g1 | fileNode = fileNode } allEdges
        |> G.finish


cppDefineEdges : List Node -> List Edge
cppDefineEdges defs =
    List.map (\d -> edge "defines" (Dict.get "module" d.props |> Maybe.withDefault "") d.id Nothing) defs


declKindName : F.DeclKind -> String
declKindName k =
    case k of
        F.Value ->
            "value"

        F.Union ->
            "type"

        F.Alias ->
            "alias"

        F.Port ->
            "port"


boolText : Bool -> String
boolText b =
    if b then
        "true"

    else
        "false"


dedupeBy : (a -> comparable) -> List a -> List a
dedupeBy key xs =
    List.foldl
        (\x ( seen, acc ) ->
            if Set.member (key x) seen then
                ( seen, acc )

            else
                ( Set.insert (key x) seen, x :: acc )
        )
        ( Set.empty, [] )
        xs
        |> Tuple.second
        |> List.reverse


planNode : String -> String -> F.MarkdownFacts -> Node
planNode id path md =
    let
        firstText =
            md.sections |> List.map .text |> List.filter (\t -> String.trim t /= "") |> List.head |> Maybe.withDefault ""

        fm =
            md.frontMatter
    in
    { id = id
    , kind = Plan
    , label = md.title
    , stage = Nothing
    , paths = [ path ]
    , line = Nothing
    , doc = Just (String.left 1500 firstText)
    , props =
        Dict.fromList
            (List.filterMap (\k -> Dict.get k fm |> Maybe.map (\v -> ( k, v ))) [ "status", "updated", "remaining", "superseded_by" ])
    }


sectionId : String -> List String -> String
sectionId path sectionPath =
    "doc:" ++ path ++ "#" ++ String.join "/" sectionPath


{-| The id of the section a line of a doc falls in. -}
sectionAt : String -> F.MarkdownFacts -> Int -> String
sectionAt path md line =
    md.sections
        |> List.filter (\s -> s.startLine <= line)
        |> List.reverse
        |> List.head
        |> Maybe.map (\s -> sectionId path s.path)
        |> Maybe.withDefault (sectionId path [])


sourceTokens : String -> List String
sourceTokens source =
    Re.split (Re.unsafe "[,|\\s]+") source |> List.map String.trim |> List.filter ((/=) "")



-- REFERENCES


{-| `calls` and `uses_type` from one module's definitions, each reference
resolved through the module's imports: an alias or module name for a qualified
name, the module itself or an `exposing` list for a bare one. References that
resolve to nothing in the compiler are dropped.
-}
referenceEdges : ModuleGraph -> Dict String (List ( String, F.Decl )) -> Set String -> (String -> Maybe ElmFacts) -> Kg.Link.ModuleNode -> List Edge
referenceEdges mg declsOf defIds elmFacts m =
    m.files
        |> List.filterMap elmFacts
        |> List.concatMap
            (\f ->
                let
                    qualified : Dict String (List String)
                    qualified =
                        f.imports
                            |> List.foldl
                                (\i acc ->
                                    let
                                        withName =
                                            Dict.update i.name (\v -> Just (i.name :: Maybe.withDefault [] v)) acc
                                    in
                                    case i.asName of
                                        Just a ->
                                            Dict.update a (\v -> Just (i.name :: Maybe.withDefault [] v)) withName

                                        Nothing ->
                                            withName
                                )
                                Dict.empty

                    exposedFrom name =
                        f.imports
                            |> List.filter
                                (\i ->
                                    case i.exposes of
                                        ExposeAll ->
                                            Set.member (i.name ++ "#" ++ name) defIds

                                        ExposeList names ->
                                            List.member name names
                                )
                            |> List.map .name

                    resolve r =
                        if r.qualifier /= "" then
                            Dict.get r.qualifier qualified
                                |> Maybe.withDefault []
                                |> List.map (\mod -> mod ++ "#" ++ r.name)
                                |> List.filter (\id -> Set.member id defIds)
                                |> List.head

                        else if Set.member (m.id ++ "#" ++ r.name) defIds then
                            Just (m.id ++ "#" ++ r.name)

                        else
                            exposedFrom r.name |> List.map (\mod -> mod ++ "#" ++ r.name) |> List.filter (\id -> Set.member id defIds) |> List.head
                in
                f.references
                    |> List.filterMap
                        (\r ->
                            resolve r
                                |> Maybe.map
                                    (\target ->
                                        edge
                                            (if r.isType then
                                                "uses_type"

                                             else
                                                "calls"
                                            )
                                            (m.id ++ "#" ++ r.from)
                                            target
                                            (Just r.line)
                                    )
                        )
            )



-- GATES


{-| `gates`: flag → the definition that reads it. A read of field `f` counts
for the flag whose path ends in `f` when no other flag's does and the module
imports the config, or when the line also names the flag's parent (`lss` for
`mono.lss.enabled`).
-}
gates : ModuleGraph -> List F.ConfigFlag -> (String -> Maybe ElmFacts) -> Set String -> List Edge
gates mg flags elmFacts defIds =
    let
        lastSeg c =
            List.reverse c.path |> List.head |> Maybe.withDefault ""

        parentSeg c =
            List.reverse c.path |> List.drop 1 |> List.head

        byLast : Dict String (List F.ConfigFlag)
        byLast =
            List.foldl (\c acc -> Dict.update (lastSeg c) (\v -> Just (c :: Maybe.withDefault [] v)) acc) Dict.empty flags
    in
    Dict.values mg.nodes
        |> List.filter (\m -> m.lang == "elm" && not (List.member m.id configModules))
        |> List.concatMap
            (\m ->
                m.files
                    |> List.filterMap elmFacts
                    |> List.concatMap
                        (\f ->
                            let
                                importsConfig =
                                    List.any (\i -> i.name == "Compiler.Eco.Config") f.imports
                            in
                            f.fieldReads
                                |> List.concatMap
                                    (\r ->
                                        let
                                            candidates =
                                                Dict.get r.field byLast |> Maybe.withDefault []

                                            byParent =
                                                List.filter
                                                    (\c ->
                                                        case parentSeg c of
                                                            Just p ->
                                                                String.contains ("." ++ p ++ ".") (" " ++ r.text) || String.contains (p ++ "." ++ r.field) r.text

                                                            Nothing ->
                                                                False
                                                    )
                                                    candidates

                                            chosen =
                                                case byParent of
                                                    [ one ] ->
                                                        [ one ]

                                                    _ ->
                                                        case candidates of
                                                            [ only ] ->
                                                                if importsConfig || mentionsConfig r.text then
                                                                    [ only ]

                                                                else
                                                                    []

                                                            _ ->
                                                                []

                                            from =
                                                m.id ++ "#" ++ r.from
                                        in
                                        if Set.member from defIds then
                                            List.map (\c -> edge "gates" ("flag:" ++ String.join "." c.path) from (Just r.line)) chosen

                                        else
                                            []
                                    )
                        )
            )


{-| The modules that define, decode and hash the settings: they read every
flag, and are gated by none.
-}
configModules : List String
configModules =
    [ "Compiler.Eco.Config", "Builder.Eco.Config" ]


mentionsConfig : String -> Bool
mentionsConfig text =
    let
        lower =
            String.toLower text
    in
    String.contains "config" lower || String.contains "cfg" lower



-- PRODUCES AND CONSUMES


{-| For each stage with an entry module, the types in its exposed values'
signatures: argument types are consumed, result types produced.
-}
producesConsumes : Graph -> Dict String (List ( String, F.Decl )) -> (String -> Maybe ElmFacts) -> ModuleGraph -> List Edge
producesConsumes g declsOf elmFacts mg =
    Stages.stages
        |> List.concatMap
            (\s ->
                case s.entry of
                    Nothing ->
                        []

                    Just entry ->
                        let
                            facts =
                                Dict.get entry mg.nodes |> Maybe.map .files |> Maybe.withDefault [] |> List.filterMap elmFacts |> List.head

                            aliases =
                                facts |> Maybe.map .imports |> Maybe.withDefault [] |> List.concatMap (\i -> ( i.name, i.name ) :: (i.asName |> Maybe.map (\a -> [ ( a, i.name ) ]) |> Maybe.withDefault [])) |> Dict.fromList

                            exposingAll =
                                facts |> Maybe.map .imports |> Maybe.withDefault [] |> List.filterMap (\i -> case i.exposes of
                                    ExposeList names -> Just ( i.name, names )
                                    ExposeAll -> Just ( i.name, [] )
                                )

                            resolveType name =
                                case List.reverse (String.split "." name) of
                                    [ single ] ->
                                        if Dict.member (entry ++ "#" ++ single) g.nodes then
                                            Just (entry ++ "#" ++ single)

                                        else
                                            exposingAll |> List.filter (\( _, ns ) -> List.member single ns) |> List.map (\( mod, _ ) -> mod ++ "#" ++ single) |> List.filter (\id -> Dict.member id g.nodes) |> List.head

                                    last :: qualRev ->
                                        Dict.get (String.join "." (List.reverse qualRev)) aliases
                                            |> Maybe.map (\mod -> mod ++ "#" ++ last)
                                            |> Maybe.andThen (\id -> if Dict.member id g.nodes then Just id else Nothing)

                                    [] ->
                                        Nothing

                            sigs =
                                Dict.get entry declsOf |> Maybe.withDefault [] |> List.filter (\( _, d ) -> d.exposed && d.kind == F.Value) |> List.filterMap (\( _, d ) -> d.signature)
                        in
                        sigs
                            |> List.concatMap
                                (\sig ->
                                    let
                                        parts =
                                            splitArrows sig

                                        ( args, result ) =
                                            ( List.take (List.length parts - 1) parts, List.drop (List.length parts - 1) parts )

                                        typesIn text =
                                            Re.matches (Re.unsafe "[A-Z][A-Za-z0-9_]*(?:\\.[A-Z][A-Za-z0-9_]*)*") text |> List.filterMap resolveType
                                    in
                                    List.map (\t -> edge "consumes" ("stage:" ++ s.key) t Nothing) (List.concatMap typesIn args)
                                        ++ List.map (\t -> edge "produces" ("stage:" ++ s.key) t Nothing) (List.concatMap typesIn result)
                                )
            )


{-| Splits a type at its top-level arrows. -}
splitArrows : String -> List String
splitArrows sig =
    let
        go chars depth cur acc =
            case chars of
                '-' :: '>' :: rest ->
                    if depth == 0 then
                        go rest depth [] (String.fromList (List.reverse cur) :: acc)

                    else
                        go rest depth ('>' :: '-' :: cur) acc

                c :: rest ->
                    let
                        d =
                            if c == '(' || c == '{' then
                                depth + 1

                            else if c == ')' || c == '}' then
                                depth - 1

                            else
                                depth
                    in
                    go rest d (c :: cur) acc

                [] ->
                    List.reverse (String.fromList (List.reverse cur) :: acc)
    in
    go (String.toList sig) 0 [] [] |> List.map String.trim



-- MENTIONS


{-| The modules of elm/core and the other common packages: a one-word
qualifier naming one of them is the package's, not a compiler module's.
-}
coreModules : List String
coreModules =
    [ "Basics", "List", "Maybe", "Result", "String", "Char", "Tuple", "Debug", "Platform", "Cmd", "Sub", "Dict", "Set", "Array", "Bitwise", "Task", "Process", "Json", "Bytes", "Regex", "Time", "Http", "Url", "Parser" ]


type alias MentionIndex =
    { ids : Set String
    , bySuffix : Dict String (List String)
    , paths : Dict String String
    , pathSuffix : Dict String (List String)
    }


mentionIndex : Graph -> MentionIndex
mentionIndex g =
    let
        modules =
            G.nodes g |> List.filter (\n -> n.kind == Module || n.kind == Component) |> List.map .id

        suffixes id =
            let
                parts =
                    String.split "." id
            in
            List.range 1 (List.length parts - 1) |> List.map (\k -> String.join "." (List.drop k parts))

        bySuffix =
            List.foldl (\id acc -> List.foldl (\s a -> Dict.update s (\v -> Just (id :: Maybe.withDefault [] v)) a) acc (suffixes id)) Dict.empty modules

        pathSuffixes p =
            let
                parts =
                    String.split "/" p
            in
            List.range 1 (List.length parts - 1) |> List.map (\k -> String.join "/" (List.drop k parts))

        pathSuffix =
            Dict.keys g.fileNode |> List.foldl (\p acc -> List.foldl (\s a -> Dict.update s (\v -> Just (p :: Maybe.withDefault [] v)) a) acc (pathSuffixes p)) Dict.empty
    in
    { ids = Set.fromList (Dict.keys g.nodes), bySuffix = bySuffix, paths = g.fileNode, pathSuffix = pathSuffix }


{-| Resolves a mention: an exact module or definition id; a unique module
suffix (at least two segments); a path, or a unique path suffix; a plan
file. Otherwise nothing.
-}
resolveMention : MentionIndex -> String -> Maybe String
resolveMention index target0 =
    let
        target =
            target0 |> String.trim

        noLine =
            case Re.firstMatch (Re.unsafe "^(.*?)(?::\\d+)?$") target of
                Just m ->
                    m.groups |> List.head |> Maybe.andThen identity |> Maybe.withDefault target

                Nothing ->
                    target

        moduleFor name =
            if Set.member name index.ids then
                Just name

            else if String.contains "." name then
                case Dict.get name index.bySuffix of
                    Just [ only ] ->
                        Just only

                    _ ->
                        Nothing

            else
                Nothing

        -- a value's module may be named by its last segment alone: the value narrows it;
        -- but `Set.size` in prose is elm/core's, not the compiler's Data.Set
        moduleForValue name =
            case moduleFor name of
                Just m ->
                    Just m

                Nothing ->
                    if List.member name coreModules then
                        Nothing

                    else
                        case Dict.get name index.bySuffix of
                            Just [ only ] ->
                                Just only

                            _ ->
                                Nothing
    in
    if Set.member target index.ids then
        Just target

    else if String.startsWith "inv:" target || Re.contains (Re.unsafe "^[A-Z][A-Z0-9]*_[A-Z0-9_]+$") target then
        let
            id =
                if String.startsWith "inv:" target then
                    target

                else
                    "inv:" ++ target
        in
        if Set.member id index.ids then
            Just id

        else
            Nothing

    else if Re.contains (Re.unsafe "\\.(elm|cpp|hpp|h|td|md)$") noLine then
        case Dict.get noLine index.paths of
            Just n ->
                Just n

            Nothing ->
                if String.startsWith "plans/" noLine || (not (String.contains "/" noLine) && String.endsWith ".md" noLine && Set.member ("plan:" ++ String.dropRight 3 noLine) index.ids) then
                    let
                        id =
                            "plan:" ++ String.dropRight 3 (P.basename noLine)
                    in
                    if Set.member id index.ids then
                        Just id

                    else
                        Nothing

                else
                    case Dict.get noLine index.pathSuffix of
                        Just [ only ] ->
                            Dict.get only index.paths

                        _ ->
                            Nothing

    else
        case moduleFor target of
            Just m ->
                Just m

            Nothing ->
                -- a qualified value: Module.value
                case List.reverse (String.split "." target) of
                    value :: modRev ->
                        if String.uncons value |> Maybe.map (Tuple.first >> Char.isAlpha) |> Maybe.withDefault False then
                            moduleForValue (String.join "." (List.reverse modRev))
                                |> Maybe.map (\m -> m ++ "#" ++ value)
                                |> Maybe.andThen
                                    (\id ->
                                        if Set.member id index.ids then
                                            Just id

                                        else
                                            Nothing
                                    )

                        else
                            Nothing

                    [] ->
                        Nothing
