module Run exposing (main)

{-| kg's tests: `bin/kg-test [filter]` runs those whose names contain the filter. -}

import Array
import Bytes.Encode
import ChildProcess
import FileSystem
import Path
import Dict
import Json.Decode as D
import Json.Encode as E
import Kg.Args as Args
import Kg.Assemble as Assemble
import Kg.Codec as Codec
import Kg.Extract as Extract
import Kg.Extract.Cpp as Cpp
import Kg.Extract.Elm as ElmX
import Kg.Extract.Prose as Prose
import Kg.Facts as Facts exposing (FileFacts(..))
import Kg.Fs as Fs
import Kg.Git as Git
import Kg.Graph as G
import Kg.History as History
import Kg.Link as Link
import Kg.Query as Q
import Kg.Re as Re
import Kg.Render as R
import Kg.Search.Bm25 as Bm25
import Kg.Search.Chunks as Chunks
import Kg.Search.Tokens as Tokens
import Kg.Search.Vectors as Vectors
import Kg.Sha256 as Sha256
import Kg.Tools as Tools
import Mcp.Protocol as P
import Regex
import Set
import System
import Task exposing (Task)
import Test.Runner as T exposing (Test)
import Time


main : Platform.Program System.Environment () ()
main =
    System.simpleProgram (\env -> T.run env (List.drop 1 env.args |> List.head |> Maybe.withDefault "") tests)


tests : List Test
tests =
    ecoTests ++ cppTests ++ elmTests ++ proseTests ++ linkTests ++ codecTests ++ searchTests ++ mcpTests ++ renderTests ++ queryTests ++ gitTests ++ vectorTests



-- ECO


ecoTests : List Test
ecoTests =
    [ T.pure "eco: regex lookbehind" <|
        \_ ->
            case Regex.fromString "(?<!:):(?!:)" of
                Nothing ->
                    Err "does not compile"

                Just re ->
                    T.equal [ "a", "b::c" ] (Regex.split re "a:b::c")
    , T.pure "eco: regex backreference" <|
        \_ ->
            case Re.compile "(?<![\\w])R\"([^(\\s]{0,16})\\([\\s\\S]*?\\)\\1\"" of
                Nothing ->
                    Err "does not compile"

                Just re ->
                    T.equal [ "R\"x(a)\" b)x\"" ] (Re.matches re "R\"x(a)\" b)x\" tail")
    , T.pure "re: replaceWith and indices past non-ASCII" <|
        \_ ->
            T.equal "x[é]y[é]" (Re.replaceWith (Re.unsafe "é") (\m -> "[" ++ m.match ++ "]") "xéyé")
    , T.pure "re: index counts like String.slice" <|
        \_ ->
            T.equal [ "b" ] (List.map (\m -> String.slice m.index (m.index + 1) "a😀b") (Re.findAll (Re.unsafe "b") "a😀b"))
    , T.pure "eco: sha256 vectors" <|
        \_ ->
            T.equal
                [ "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
                , "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
                , "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1"
                ]
                (List.map Sha256.sha256 [ "", "abc", "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq" ])
    , T.task "eco: sha256 of 8 MB in 2,000-character pieces under 4 s" <|
        (Time.now
            |> Task.andThen
                (\t0 ->
                    let
                        pieces =
                            List.range 1 4000 |> List.map (\i -> String.repeat 100 ("abcdefghijklmnopqrs" ++ String.fromInt (modBy 10 i)))

                        hs =
                            List.map Sha256.sha256 pieces
                    in
                    Time.now
                        |> Task.andThen
                            (\t1 ->
                                if List.length hs == 4000 && Time.posixToMillis t1 - Time.posixToMillis t0 < 4000 then
                                    Task.succeed ()

                                else
                                    Task.fail ("took " ++ String.fromInt (Time.posixToMillis t1 - Time.posixToMillis t0) ++ " ms")
                            )
                )
        )
    , T.task "eco: sha256 of 1 MB under 1 s" <|
        (Time.now
            |> Task.andThen
                (\t0 ->
                    let
                        h =
                            Sha256.sha256 (String.repeat (1024 * 1024 // 16) "0123456789abcdef")
                    in
                    Time.now
                        |> Task.andThen
                            (\t1 ->
                                let
                                    ms =
                                        Time.posixToMillis t1 - Time.posixToMillis t0
                                in
                                if String.length h == 64 && ms < 1000 then
                                    Task.succeed ()

                                else
                                    Task.fail ("took " ++ String.fromInt ms ++ " ms")
                            )
                )
        )
    ]



-- C++


cppTests : List Test
cppTests =
    [ T.pure "cpp: literals and comments are blanked, offsets kept" <|
        \_ ->
            let
                text =
                    "int a = 1; // x { y\nconst char* s = \"{ }\"; char c = '{';\n/* { */ int b;"

                out =
                    Cpp.stripCpp text
            in
            Result.map2 (\_ _ -> ())
                (T.equal (String.length text) (String.length out))
                (T.expect (not (String.contains "{" out)) ("braces survived: " ++ out))
    , T.pure "cpp: extern \"C\" after literal stripping" <|
        \_ ->
            let
                f =
                    Cpp.extract "x.cpp" "extern \"C\" {\nvoid Eco_Kernel_File_read(int x) { }\n}\n"
            in
            T.equal [ ( "", "Eco_Kernel_File_read" ) ] f.defs
    , T.pure "cpp: a member definition keeps its class in the namespace" <|
        \_ ->
            let
                f =
                    Cpp.extract "x.cpp" "namespace Elm {\nvoid NurserySpace::MinorEnv::run(int n) { }\n}\n"
            in
            T.equal [ ( "Elm::NurserySpace::MinorEnv", "run" ) ] f.defs
    , T.pure "cpp: braces inside a macro's argument are skipped" <|
        \_ ->
            let
                f =
                    Cpp.extract "x.cpp" "TEST_CASE(foo, { int x; }) \nint bar() { return 1; }\n"
            in
            T.equal [ ( "", "bar" ) ] f.defs
    , T.pure "cpp: /alternatename directives define their names" <|
        \_ ->
            let
                f =
                    Cpp.extract "x.cpp" "#pragma comment(linker, \"/alternatename:Foo_weak=Foo_default\")\n"
            in
            T.equal [ ( "", "Foo_weak" ) ] f.defs
    , T.pure "cpp: static functions and anonymous namespaces define nothing" <|
        \_ ->
            T.equal [] (Cpp.extract "x.cpp" "static int f() { return 0; }\nnamespace { int g() { return 1; } }\n").defs
    , T.pure "cpp: uses with qualifiers, and declarations" <|
        \_ ->
            let
                f =
                    Cpp.extract "x.cpp" "void foo(int);\nvoid g() { Elm::foo(1); foo(2); obj.foo(3); }\n"
            in
            T.equal (Just { quals = [ "", "Elm" ], declares = True }) (Dict.get "foo" f.uses)
    , T.pure "cpp: includes, quoted and TableGen" <|
        \_ ->
            T.equal [ "a.h", "b.td" ] (Cpp.extract "x.td" "#include \"a.h\"\ninclude \"b.td\"\n").includes
    , T.pure "cpp: classes and opened namespaces" <|
        \_ ->
            let
                f =
                    Cpp.extract "x.hpp" "namespace a { namespace b { class Heap final : public Base { }; } }\nusing namespace std;\n"
            in
            T.equal ( [ "Heap" ], [ "a", "a::b", "std" ] ) ( f.classes, f.opened )
    ]



-- ELM


elmSource : String
elmSource =
    String.join "\n"
        [ "module Foo.Bar exposing (run, Thing)"
        , ""
        , "{-| The module doc. -}"
        , ""
        , "import Compiler.Eco.Config as Config"
        , "import Dict exposing (Dict)"
        , ""
        , ""
        , "{-| A thing. -}"
        , "type alias Thing ="
        , "    { size : Int }"
        , ""
        , ""
        , "{-| Runs. -}"
        , "run : Config.EcoConfig -> Dict String Int -> Int"
        , "run config d ="
        , "    if config.aggPromote then"
        , "        Dict.size d"
        , ""
        , "    else"
        , "        helper 1"
        , ""
        , ""
        , "helper : Int -> Int"
        , "helper n ="
        , "    n"
        ]


elmTests : List Test
elmTests =
    [ T.pure "elm: imports, docs, declarations" <|
        \_ ->
            let
                f =
                    ElmX.extract "src/Foo/Bar.elm" elmSource
            in
            T.equal
                ( ( "Foo.Bar", [ "Compiler.Eco.Config", "Dict" ], Just "The module doc." )
                , List.map (\d -> ( d.name, d.exposed, d.doc /= Nothing )) f.decls
                , f.parseError
                )
                ( ( f.moduleName, List.map .name f.imports, f.moduleDoc )
                , [ ( "run", True, True ), ( "helper", False, False ), ( "Thing", True, True ) ]
                , Nothing
                )
    , T.pure "elm: signatures are source text" <|
        \_ ->
            T.equal (Just "Config.EcoConfig -> Dict String Int -> Int")
                (ElmX.extract "x.elm" elmSource |> .decls |> List.filter (\d -> d.name == "run") |> List.head |> Maybe.andThen .signature)
    , T.pure "elm: references and field reads" <|
        \_ ->
            let
                f =
                    ElmX.extract "x.elm" elmSource
            in
            Result.map2 (\_ _ -> ())
                (T.expect (List.any (\r -> r.from == "run" && r.qualifier == "Dict" && r.name == "size") f.references) "Dict.size not found")
                (T.expect (List.any (\r -> r.from == "run" && r.field == "aggPromote") f.fieldReads) "config.aggPromote not found")
    , T.pure "elm: a file the parser rejects falls back to the import regex" <|
        \_ ->
            let
                f =
                    ElmX.extract "x.elm" "module X exposing (..)\nimport A.B\nimport C\nthis is not elm ="
            in
            T.equal ( [ "A.B", "C" ], True ) ( List.map .name f.imports, f.parseError /= Nothing )
    , T.pure "elm: a module with a GLSL shader parses, with no crash" <|
        \_ ->
            let
                f =
                    ElmX.extract "x.elm" "module A exposing (s)\n\nimport B\n\n\ns =\n    [glsl|\nuniform mat4 m;\nvoid main () {\n    gl_Position = m * vec4(1.0);\n}\n|]\n"
            in
            T.equal ( Nothing, [ "B" ] ) ( f.parseError, List.map .name f.imports )
    , T.pure "elm: an import inside a string is not an import" <|
        \_ ->
            T.equal [ "B" ] (ElmX.extract "x.elm" "module A exposing (x)\n\nimport B\n\n\nx =\n    \"\"\"\nimport C\n\"\"\"\n" |> .imports |> List.map .name)
    ]



-- PROSE


proseTests : List Test
proseTests =
    [ T.pure "prose: front matter, quoted values and continuations" <|
        \_ ->
            T.equal
                (Dict.fromList [ ( "status", "partial" ), ( "superseded_by", "plans/b.md and more" ), ( "title", "A \"b\"" ) ])
                (Prose.frontMatter "---\nstatus: partial\nsuperseded_by: plans/b.md\n  and more\ntitle: \"A \\\"b\\\"\"\n---\n# T\n" |> Tuple.first)
    , T.pure "prose: sections split at headings outside fences" <|
        \_ ->
            let
                md =
                    Prose.markdown "plans/x.md" "# Title\nintro\n## A\ntext\n```\n# not a heading\n```\n### B\nmore\n"
            in
            T.equal [ [ "Title" ], [ "Title", "A" ], [ "Title", "A", "B" ] ] (List.map .path md.sections)
    , T.pure "prose: mentions of modules, values and paths" <|
        \_ ->
            let
                md =
                    Prose.markdown "plans/x.md" "# T\nSee `Compiler.Type.Solve`, `Prune.pruneAfterInline` and compiler/src/A.elm:12, not `foo bar`.\n"
            in
            T.equal [ "Compiler.Type.Solve", "Prune.pruneAfterInline", "compiler/src/A.elm:12" ] (List.map .target md.mentions)
    , T.pure "prose: invariants with ; in descriptions" <|
        \_ ->
            T.equal [ ( "CGEN_001", "a; b; c", "src/X.elm" ) ]
                (Prose.invariants "id;phase;category;status;description;source\n# comment\n\nCGEN_001;p;cat;documented;a; b; c;src/X.elm\n" |> List.map (\i -> ( i.id, i.description, i.source )))
    ]



-- LINK


fixtureRoot : String
fixtureRoot =
    "Fixtures/tiny"


linkTests : List Test
linkTests =
    [ T.task "link: the tiny fixture's module edges" <|
        (Task.map2 Tuple.pair (listFiles fixtureRoot "") (Fs.readText (fixtureRoot ++ "/expected-edges.txt"))
            |> Task.andThen
                (\( paths, expectedText ) ->
                    paths
                        |> List.filter (\p -> p /= "expected-edges.txt")
                        |> List.map (\p -> Fs.readText (fixtureRoot ++ "/" ++ p) |> Task.map (\t -> ( p, Extract.extract p t )))
                        |> Task.sequence
                        |> Task.andThen
                            (\facts ->
                                let
                                    files =
                                        Dict.fromList facts

                                    cpp =
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

                                    g =
                                        Link.modules { files = files, cpp = cpp, packages = Dict.empty }

                                    got =
                                        Set.toList g.edges |> List.map (\( k, a, b ) -> k ++ " " ++ a ++ " " ++ b)

                                    expected =
                                        String.lines expectedText |> List.filter ((/=) "")
                                in
                                case T.equal expected got of
                                    Ok () ->
                                        Task.succeed ()

                                    Err e ->
                                        Task.fail e
                            )
                )
        )
    , T.pure "assemble: mentions resolve to modules, definitions, paths and plans" <|
        \_ ->
            let
                g =
                    List.foldl G.addNode G.empty
                        [ node "Compiler.Monomorphize.Prune" G.Module
                        , node "Compiler.Monomorphize.Prune#pruneAfterInline" G.Definition
                        , node "plan:foo" G.Plan
                        , node "inv:CGEN_001" G.Invariant
                        ]

                index =
                    Assemble.mentionIndex { g | fileNode = Dict.fromList [ ( "compiler/src/Compiler/Monomorphize/Prune.elm", "Compiler.Monomorphize.Prune" ) ] }
            in
            T.equal
                [ Just "Compiler.Monomorphize.Prune", Just "Compiler.Monomorphize.Prune#pruneAfterInline", Just "Compiler.Monomorphize.Prune", Just "plan:foo", Just "inv:CGEN_001", Nothing ]
                (List.map (Assemble.resolveMention index) [ "Monomorphize.Prune", "Prune.pruneAfterInline", "Monomorphize/Prune.elm:20", "plans/foo.md", "CGEN_001", "Prune" ])
    ]


withDoc : String -> G.Node -> G.Node
withDoc d n =
    { n | doc = Just d }


node : String -> G.NodeKind -> G.Node
node id kind =
    { id = id, kind = kind, label = id, stage = Just "mono", paths = [], line = Nothing, doc = Nothing, props = Dict.empty }


listFiles : String -> String -> Task String (List String)
listFiles root rel =
    Fs.listDir (if rel == "" then root else root ++ "/" ++ rel)
        |> Task.andThen
            (\entries ->
                entries
                    |> List.map
                        (\e ->
                            let
                                p =
                                    if rel == "" then
                                        e.name

                                    else
                                        rel ++ "/" ++ e.name
                            in
                            if e.isDir then
                                listFiles root p

                            else
                                Task.succeed [ p ]
                        )
                    |> Task.sequence
                    |> Task.map List.concat
            )



-- CODECS


roundTrip : String -> Codec.Codec a -> a -> Test
roundTrip name c value =
    T.pure ("codec: " ++ name) (\_ -> T.equal (Just value) (Codec.decode c (Codec.encode c value)))


codecTests : List Test
codecTests =
    [ roundTrip "ints, including negative and 64-bit" (Codec.list Codec.int) [ 0, -1, 1, 4294967296, -4294967297, 1762156800 ]
    , roundTrip "strings with non-ASCII" (Codec.list Codec.string) [ "", "héllo", "😀", "a\nb" ]
    , roundTrip "C++ facts" Facts.codec (CppFile (Cpp.extract "x.cpp" "namespace a { int f(int x) { return x; } }\n"))
    , roundTrip "Elm facts" Facts.codec (ElmFile (ElmX.extract "x.elm" elmSource))
    , roundTrip "Markdown facts" Facts.codec (Markdown (Prose.markdown "plans/x.md" "---\nstatus: done\n---\n# T\n`A.B`\n"))
    , roundTrip "invariants" Facts.codec (Invariants (Prose.invariants "X_1;p;c;s;d;src\n"))
    , roundTrip "graph" G.codec
        (List.foldl G.addEdge
            (List.foldl G.addNode G.empty [ node "A" G.Module, node "B" G.Module ])
            [ { kind = "imports", from = "A", to = "B", weight = 1, line = Just 3 } ]
            |> G.finish
        )
    , roundTrip "history" History.codec
        { commits = Array.fromList [ { hash = "abc", time = 1, subject = "s" } ], lives = Dict.fromList [ ( "A", [ 0 ] ) ], renames = Dict.empty, edits = Dict.fromList [ ( "A", [ 0 ] ) ], coChange = Dict.fromList [ ( ( "A", "B" ), 2 ) ], lastIndexed = "abc" }
    , roundTrip "BM25 index" Bm25.codec (Bm25.build [ ( 0, [ "a", "b" ] ), ( 1, [ "b" ] ) ])
    , T.pure "codec: a wrong header does not decode" <|
        \_ ->
            T.equal Nothing (Codec.decode Facts.codec (Bytes.Encode.encode (Bytes.Encode.string "XXXXXX")))
    ]



-- SEARCH


searchTests : List Test
searchTests =
    [ T.pure "tokens: camelCase and digits split, whole kept" <|
        \_ ->
            T.equal [ "aggpromote", "agg", "promote", "utf8decode", "utf", "decode", "http", "server" ] (Tokens.tokenize "aggPromote utf8Decode the HTTP server")
    , T.pure "bm25: ranks the closer document first" <|
        \_ ->
            let
                docs =
                    [ ( 0, Tokens.tokenize "escape analysis of closures and escape routes" )
                    , ( 1, Tokens.tokenize "aggregate promotion for values that do not escape" )
                    , ( 2, Tokens.tokenize "the garbage collector and its nursery" )
                    ]

                index =
                    Bm25.build docs
            in
            T.equal [ 0, 1 ] (Bm25.search index (\_ -> True) 10 (Tokens.tokenize "escape analysis") |> List.map Tuple.first)
    , T.pure "rrf: a hand-computed example" <|
        \_ ->
            -- 7: 1/61 + 1/62; 9: 1/61; 3: 1/62
            T.equal [ 7, 9, 3 ] (Q.rrf [ [ 7, 3 ], [ 9, 7 ] ] |> List.map Tuple.first)
    , T.pure "chunks: long text splits at paragraphs and repeats the header" <|
        \_ ->
            let
                g =
                    G.addNode (withDoc (String.join "\n\n" (List.repeat 80 (String.repeat 9 "word "))) (node "inv:X_1" G.Invariant)) G.empty

                cs =
                    Chunks.build g Dict.empty
            in
            Result.map2 (\_ _ -> ())
                (T.expect (List.length cs > 1) "not split")
                (T.expect (List.all (\c -> String.startsWith "invariant inv:X_1" c.text && String.length c.text <= Chunks.maxChars) cs) "a piece lacks the header or is too long")
    ]



-- MCP


mcpInfo : P.ServerInfo
mcpInfo =
    { name = "eco-kg", version = "0.1.0", instructions = "hi" }


reply : String -> String
reply line =
    case P.handle mcpInfo Tools.tools (P.decode line) of
        P.Reply text ->
            text

        P.NoReply ->
            "none"

        P.CallTool c ->
            "call " ++ c.name


errorCode : String -> Maybe Int
errorCode text =
    D.decodeString (D.at [ "error", "code" ] D.int) text |> Result.toMaybe


mcpTests : List Test
mcpTests =
    [ T.pure "mcp: initialize answers 2025-11-25 with instructions" <|
        \_ ->
            T.equal (Ok ( "2025-11-25", "hi" ))
                (D.decodeString (D.map2 Tuple.pair (D.at [ "result", "protocolVersion" ] D.string) (D.at [ "result", "instructions" ] D.string))
                    (reply "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{\"protocolVersion\":\"2026-07-28\"}}")
                    |> Result.mapError (\_ -> "")
                )
    , T.pure "mcp: server/discover gets -32601" <|
        \_ -> T.equal (Just -32601) (errorCode (reply "{\"jsonrpc\":\"2.0\",\"id\":0,\"method\":\"server/discover\"}"))
    , T.pure "mcp: ping answers {}" <|
        \_ -> T.equal (Ok []) (D.decodeString (D.field "result" (D.keyValuePairs D.value)) (reply "{\"jsonrpc\":\"2.0\",\"id\":5,\"method\":\"ping\"}") |> Result.map (List.map Tuple.first) |> Result.mapError (\_ -> ()))
    , T.pure "mcp: notifications get no answer" <|
        \_ -> T.equal "none" (reply "{\"jsonrpc\":\"2.0\",\"method\":\"notifications/initialized\"}")
    , T.pure "mcp: a line that is not JSON gets -32700" <|
        \_ -> T.equal (Just -32700) (errorCode (reply "not json"))
    , T.pure "mcp: an unknown tool gets -32602" <|
        \_ -> T.equal (Just -32602) (errorCode (reply "{\"jsonrpc\":\"2.0\",\"id\":4,\"method\":\"tools/call\",\"params\":{\"name\":\"nope\"}}"))
    , T.pure "mcp: a known tool is handed over" <|
        \_ -> T.equal "call locate" (reply "{\"jsonrpc\":\"2.0\",\"id\":4,\"method\":\"tools/call\",\"params\":{\"name\":\"locate\",\"arguments\":{\"query\":\"x\"}}}")
    , T.pure "mcp: bad arguments are a result with isError" <|
        \_ ->
            let
                r =
                    Tools.call emptyView [] "neighbours" (E.object [ ( "node", E.string "A" ), ( "depth", E.int 9 ) ])
            in
            T.equal ( True, "`depth` must be from 1 to 3" ) ( r.isError, r.text )
    , T.pure "mcp: unknown arguments are named" <|
        \_ ->
            T.expect (String.contains "`colour`" (Tools.call emptyView [] "context" (E.object [ ( "node", E.string "A" ), ( "colour", E.string "x" ) ])).text) "not named"
    , T.pure "mcp: every tool schema is an object without extra properties" <|
        \_ ->
            T.expect
                (List.all (\t -> D.decodeValue (D.map2 Tuple.pair (D.field "type" D.string) (D.field "additionalProperties" D.bool)) t.inputSchema == Ok ( "object", False )) Tools.tools)
                "a schema is not a closed object"
    ]


emptyView : Tools.View
emptyView =
    { graph = List.foldl G.addNode G.empty [ node "A" G.Module ], history = History.empty, chunks = Array.empty, bm25 = Bm25.build [], freshness = "graph at test" }



-- RENDER


renderTests : List Test
renderTests =
    [ T.pure "render: cutLines keeps within the budget and counts the rest" <|
        \_ ->
            let
                out =
                    R.cutLines 100 (List.repeat 50 "0123456789")
            in
            Result.map2 (\_ _ -> ())
                (T.expect (String.length out <= 100 + 30) ("too long: " ++ String.fromInt (String.length out)))
                (T.expect (String.contains "more (raise limit)" out) "no marker")
    , T.pure "render: clip never exceeds the hard maximum" <|
        \_ -> T.expect (String.length (R.clip (String.repeat 30000 "x")) <= R.hardMax) "too long"
    , T.pure "render: the instructions stay within 4,000 characters" <|
        \_ ->
            let
                n =
                    String.length (Tools.instructions G.empty)
            in
            T.expect (n <= 4000) (String.fromInt n ++ " characters")
    ]



-- QUERIES


queryGraph : G.Graph
queryGraph =
    List.foldl G.addEdge
        (List.foldl G.addNode G.empty (List.map (\i -> node i G.Module) [ "A", "B", "C", "D" ]))
        [ { kind = "imports", from = "A", to = "B", weight = 1, line = Nothing }
        , { kind = "imports", from = "B", to = "D", weight = 1, line = Nothing }
        , { kind = "imports", from = "A", to = "C", weight = 1, line = Nothing }
        , { kind = "imports", from = "C", to = "D", weight = 1, line = Nothing }
        , { kind = "mentions", from = "D", to = "A", weight = 1, line = Nothing }
        ]
        |> G.finish


queryTests : List Test
queryTests =
    [ T.pure "locate: a concept named by the query comes first, with its links" <|
        \_ ->
            let
                concept =
                    { id = "concept:esc", kind = G.Concept, label = "Escape analysis", stage = Nothing, paths = [], line = Nothing, doc = Just "Values that do not escape.", props = Dict.fromList [ ( "aliases", "escape analysis, stack promotion" ) ] }

                g =
                    List.foldl G.addEdge
                        (List.foldl G.addNode G.empty [ concept, withDoc "Escape analysis and escape routes, discussed at length." (node "doc:x#y" G.DocSection), node "M#walkPromo" G.Definition ])
                        [ { kind = "implements", from = "concept:esc", to = "M#walkPromo", weight = 1, line = Nothing } ]
                        |> G.finish

                chunks =
                    Chunks.build g Dict.empty

                index =
                    Bm25.build (List.map (\c -> ( c.id, Tokens.tokenize c.text )) chunks)

                hits =
                    Q.locate g index (Array.fromList chunks) [] "escape analysis" { kinds = [], stage = Nothing, limit = 5, includeSuperseded = False }
            in
            T.equal ( Just "concept:esc", True ) ( List.head (List.map (\h -> h.node.id) hits), List.any (\h -> h.node.id == "M#walkPromo") hits )
    , T.pure "history: co-change comes from edits, skipping prose and bulk commits" <|
        \_ ->
            let
                edits =
                    Dict.fromList
                        [ ( "A", [ 0, 1, 2 ] ), ( "B", [ 0, 2 ] ), ( "C", [ 1 ] ), ( "plan:x", [ 0, 1, 2 ] ) ]
            in
            T.equal (Dict.fromList [ ( ( "A", "B" ), 2 ), ( ( "A", "C" ), 1 ) ]) (History.coChangeFrom edits)
    , T.pure "history: truncating drops later commits and recomputes co-change" <|
        \_ ->
            let
                h =
                    { commits = Array.fromList (List.map (\i -> { hash = "c" ++ String.fromInt i, time = i, subject = "" }) [ 0, 1, 2 ])
                    , lives = Dict.fromList [ ( "A", [ 0 ] ), ( "B", [ 0, 2 ] ) ]
                    , renames = Dict.fromList [ ( "B", [ ( 2, "Z" ) ] ) ]
                    , edits = Dict.fromList [ ( "A", [ 0, 2 ] ), ( "B", [ 0, 2 ] ) ]
                    , coChange = Dict.fromList [ ( ( "A", "B" ), 2 ) ]
                    , lastIndexed = "c2"
                    }

                t =
                    History.truncateTo 2 h
            in
            T.equal ( ( "c1", Dict.fromList [ ( ( "A", "B" ), 1 ) ] ), ( Dict.get "B" t.lives, Dict.get "B" t.renames ) )
                ( ( t.lastIndexed, t.coChange ), ( Just [ 0 ], Nothing ) )
    , T.pure "query: paths finds both shortest paths" <|
        \_ ->
            T.equal [ [ "A", "B", "D" ], [ "A", "C", "D" ] ]
                (Q.paths queryGraph "A" "D" [ "imports" ] |> List.map (\p -> "A" :: List.map .to p))
    , T.pure "query: paths follows only the kinds asked for" <|
        \_ -> T.equal [] (Q.paths queryGraph "D" "A" [ "imports" ])
    , T.pure "query: neighbours at depth 2, each node once" <|
        \_ ->
            T.equal [ ( "B", 1 ), ( "C", 1 ), ( "D", 2 ) ]
                (Q.neighbours queryGraph "A" "out" 2 [ "imports" ] |> List.map (\n -> ( n.other, n.depth )))
    ]



-- GIT


gitTests : List Test
gitTests =
    [ T.task "git: cat-file batches against a fixture repository" <|
        (FileSystem.makeTempDirectory "kg-test-"
            |> Task.map Path.toPosixString
            |> Task.mapError FileSystem.errorToString
            |> Task.andThen
                (\dir ->
                    let
                        sh script =
                            ChildProcess.run "sh" [ "-c", script, "sh", dir ] { shell = ChildProcess.NoShell, workingDirectory = ChildProcess.InheritWorkingDirectory, environmentVariables = ChildProcess.InheritEnvironmentVariables, maximumBytesWrittenToStreams = 1000000, runDuration = ChildProcess.NoLimit }
                                |> Task.mapError (\_ -> "sh failed: " ++ script)
                    in
                    sh "cd \"$1\" && git init -q && printf 'one\\n' > a.txt && printf 'two\\nlines\\n' > b.txt && git add . && git -c user.name=t -c user.email=t@t commit -qm first"
                        |> Task.andThen (\_ -> Git.lsTree dir "HEAD" [ "." ])
                        |> Task.andThen (\tree -> Git.catFiles dir dir (Dict.values tree ++ [ "0000000000000000000000000000000000000000" ]) |> Task.map (\blobs -> ( tree, blobs )))
                        |> Task.andThen
                            (\( tree, blobs ) ->
                                let
                                    textOf p =
                                        Dict.get p tree |> Maybe.andThen (\b -> Dict.get b blobs) |> Maybe.andThen Fs.bytesToString
                                in
                                case T.equal ( Just "one\n", Just "two\nlines\n", 2 ) ( textOf "a.txt", textOf "b.txt", Dict.size blobs ) of
                                    Ok () ->
                                        Git.log dir "" [ "." ]
                                            |> Task.andThen
                                                (\commits ->
                                                    case commits of
                                                        [ c ] ->
                                                            if c.subject == "first" && List.length c.changes == 2 then
                                                                Task.succeed ()

                                                            else
                                                                Task.fail "the log is wrong"

                                                        _ ->
                                                            Task.fail "expected one commit"
                                                )

                                    Err e ->
                                        Task.fail e
                            )
                        |> Task.andThen (\_ -> Fs.remove dir)
                )
        )
    , T.pure "git: status -z with a rename" <|
        \_ ->
            T.equal [ { xy = "R ", path = "new.elm", from = Just "old.elm" }, { xy = "??", path = "x.md", from = Nothing } ]
                (Git.parseStatus "R  new.elm\u{0000}old.elm\u{0000}?? x.md\u{0000}")
    ]



-- VECTORS


vectorTests : List Test
vectorTests =
    [ T.pure "vectors: top-k agrees with brute force" <|
        \_ ->
            let
                d =
                    8

                vecs =
                    List.range 0 199 |> List.map (\i -> List.range 0 (d - 1) |> List.map (\j -> sin (toFloat (i * 7 + j * 3))) |> Vectors.normalise)

                store =
                    Vectors.fromList d (List.indexedMap (\i v -> ( i, v )) vecs) 200

                q =
                    Vectors.normalise (List.range 0 (d - 1) |> List.map (\j -> cos (toFloat j)))

                brute =
                    vecs
                        |> List.indexedMap (\i v -> ( i, List.sum (List.map2 (*) q v) ))
                        |> List.sortBy (\( i, s ) -> ( -s, i ))
                        |> List.take 10
                        |> List.map Tuple.first
            in
            Result.map2 (\_ _ -> ())
                (T.expect (List.length (List.filter (\i -> List.member i brute) (Vectors.search store (\_ -> True) 10 q |> List.map Tuple.first)) >= 9) "the int8 scan's top 10 differs from brute force in more than one place")
                (T.equal brute (Vectors.searchBytes store (\_ -> True) 10 q |> List.map Tuple.first))
    ]
