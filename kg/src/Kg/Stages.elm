module Kg.Stages exposing
    ( Stage, stages, stageKeys, branchFrom, branchTo
    , elmStage, cppNodeFor, CppNode
    , cppFound, cppFoundSlot, roots
    , elmJsons, logPaths, sourcePaths, cppDirs, cmakes, twinDir, libraries, relevant, isCppPath
    , stageIndex, stageTitle
    , isConfigPath, configModule
    , KernelLibrary, kernelLibraries, kernelLibraryOf
    )

{-| The pipeline stages and the rules that put each file in one: a port of
`STAGES`, `elm_stage`, `cpp_node_for`, `CPP_FOUND`, `ROOTS`, `PATHS`,
`CPP_DIRS`, `CMAKES`, `TWIN_DIR` and `LIBRARIES` from `script/atlas-graph.py` (deleted once kg matched its output; see git history)
(§9.2 of the plan).

`entry` is new: the module where each stage starts, curated by hand and
checked by `kg check`.

-}

import Dict exposing (Dict)
import Kg.Re as Re
import Set exposing (Set)


type alias Stage =
    { key : String, title : String, blurb : String, lang : String, row : Int, entry : Maybe String }


stages : List Stage
stages =
    [ Stage "driver" "Driver" "Command line, build plan, per-module compile" "elm" 0 (Just "Terminal.Main")
    , Stage "parse" "Parse" "Source text to AST" "elm" 0 (Just "Compiler.Parse.Module")
    , Stage "canon" "Canonicalize" "Resolve names and imports" "elm" 0 (Just "Compiler.Canonicalize.Module")
    , Stage "type" "Type check" "Constraints, solving, typed AST" "elm" 0 (Just "Compiler.Type.Solve")
    , Stage "local" "Local optimize" "Pattern checks, decision trees" "elm" 0 (Just "Compiler.LocalOpt.Typed.Module")
    , Stage "genjs" "Generate JavaScript" "Erased path: .js and .html output" "elm" 0 Nothing
    , Stage "premono" "Pre-mono" "Typed path: entry, eta, inline before specializing" "elm" 1 (Just "Compiler.PreMono.EntryPrep")
    , Stage "mono" "Monomorphize" "Link and specialize" "elm" 1 (Just "Compiler.Monomorphize.Subst.Monomorphize")
    , Stage "global" "Mono optimize" "Inline, CSE, borrow, staging" "elm" 1 (Just "Compiler.MonoOpt.GlobalOptimize")
    , Stage "genmlir" "Generate MLIR" "eco-dialect MLIR bytecode" "elm" 1 (Just "Compiler.GenerateMlir.Backend")
    , Stage "backend" "MLIR lowering" "eco dialect to LLVM dialect" "cpp" 1 Nothing
    , Stage "native" "LLVM & link" "Driver, JIT, AOT, embedding" "cpp" 1 Nothing
    , Stage "runtime" "Runtime" "Collector and scheduler" "cpp" 1 Nothing
    , Stage "kernels" "Kernels" "C++ built-in functions" "cpp" 1 Nothing
    ]


branchFrom : String
branchFrom =
    "local"


branchTo : String
branchTo =
    "premono"


{-| The stage keys in order, then the two foundations, then the kernel sources. -}
stageKeys : List String
stageKeys =
    List.map .key stages ++ [ "foundation", "cppfound", "kernelsrc" ]


stageIndex : String -> Int
stageIndex key =
    indexOf key stageKeys |> Maybe.withDefault (List.length stageKeys)


stageTitle : String -> String
stageTitle key =
    case List.filter (\s -> s.key == key) stages of
        s :: _ ->
            s.title

        [] ->
            if key == "foundation" then
                "Elm foundation"

            else if key == "cppfound" then
                "C++ foundation"

            else if key == "kernelsrc" then
                "Kernel sources"

            else
                key


indexOf : a -> List a -> Maybe Int
indexOf x xs =
    let
        go i ys =
            case ys of
                y :: rest ->
                    if y == x then
                        Just i

                    else
                        go (i + 1) rest

                [] ->
                    Nothing
    in
    go 0 xs


startsWithAny : List String -> String -> Bool
startsWithAny prefixes s =
    List.any (\p -> String.startsWith p s) prefixes


elmStage : String -> String
elmStage m =
    let
        p0 =
            String.split "." m |> List.head |> Maybe.withDefault ""

        under prefixes =
            startsWithAny prefixes m
    in
    -- Both the old names (before the one-folder-per-pass reorganization,
    -- eco-compiler e2647035) and the new ones, so that every commit in the
    -- replay places its modules.
    if List.member p0 [ "Terminal", "API", "Builder" ] || List.member m [ "Compiler.Compile", "Compiler.Error" ] || under [ "Compiler.Pipeline." ] then
        "driver"

    else if under [ "Compiler.Parse." ] then
        "parse"

    else if under [ "Compiler.Canonicalize." ] then
        "canon"

    else if under [ "Compiler.Type.", "Compiler.TypedCanonical." ] then
        "type"

    else if under [ "Compiler.Nitpick.", "Compiler.LocalOpt." ] then
        "local"

    else if under [ "Compiler.PreMono.", "Compiler.GlobalOpt.PreMono." ] || List.member m [ "Compiler.GlobalOpt.InlineSimplify", "Compiler.Monomorphize.AssignMVarIds", "Compiler.Monomorphize.EntryPrep" ] then
        "premono"

    else if under [ "Compiler.Monomorphize.", "Compiler.MonoSolver." ] then
        "mono"

    else if under [ "Compiler.MonoOpt.", "Compiler.GlobalOpt." ] then
        "global"

    else if under [ "Compiler.GenerateMlir.", "Compiler.Generate.MLIR" ] || p0 == "Mlir" then
        "genmlir"

    else if m == "Compiler.Generate.Mode" then
        "foundation"

    else if m == "Compiler.GenerateJs" || under [ "Compiler.GenerateJs.", "Compiler.Generate." ] then
        "genjs"

    else
        "foundation"


type alias CppNode =
    { id : String, label : String, stage : String, group : String }


stem : String -> String
stem rel =
    let
        last =
            String.split "/" rel |> List.reverse |> List.head |> Maybe.withDefault rel
    in
    Re.replace (Re.unsafe "\\.(cpp|hpp|h|td)$") "" last


{-| Maps a C++ file path to its node, or Nothing. -}
cppNodeFor : String -> Maybe CppNode
cppNodeFor rel =
    let
        parts =
            String.split "/" rel

        part i =
            List.drop i parts |> List.head |> Maybe.withDefault ""

        n =
            List.length parts

        s =
            stem rel
    in
    if String.startsWith "runtime/src/codegen/" rel then
        let
            sub =
                if n > 4 then
                    part 3

                else
                    ""
        in
        if sub == "Passes" then
            Just (CppNode ("cpp:pass:" ++ s) s "backend" "Passes")

        else if sub == "BF" then
            Just (CppNode "cpp:bf" "BF dialect" "backend" "BF")

        else if s == "Ops" then
            Just (CppNode "cpp:cg:Ops" "Ops.td" "backend" "codegen")

        else if List.member s [ "EcoDialect", "EcoOps", "Passes", "LoweringStats", "EcoSplit", "EcoPipeline" ] then
            Just (CppNode ("cpp:cg:" ++ s) s "backend" "codegen")

        else
            Just (CppNode ("cpp:cg:" ++ s) s "native" "codegen")

    else if String.startsWith "runtime/src/jit/" rel || String.startsWith "runtime/src/embed/" rel then
        Just (CppNode ("cpp:" ++ part 2 ++ ":" ++ s) s "native" (part 2))

    else if String.startsWith "runtime/src/platform/" rel then
        Just (CppNode ("cpp:plat:" ++ s) s "runtime" "platform")

    else if rel == "runtime/src/ecogen.cpp" || rel == "runtime/src/main.cpp" then
        Just (CppNode ("cpp:rt:" ++ s) s "native" "runtime")

    else if startsWithAny [ "runtime/src/", "runtime/include/" ] rel then
        let
            s2 =
                Re.replace (Re.unsafe "_(posix|win32)$") "" s
        in
        Just (CppNode ("cpp:alloc:" ++ s2) s2 "runtime" "allocator")

    else if String.startsWith "elm-kernel-cpp/src/" rel then
        if n > 3 then
            Just (CppNode ("cpp:ek:" ++ part 2) ("elm/" ++ part 2) "kernels" "elm-kernel-cpp")

        else
            Just (CppNode ("cpp:ek:" ++ s) ("elm/" ++ s) "kernels" "elm-kernel-cpp")

    else if String.startsWith "eco-kernel-cpp/src/" rel then
        let
            s2 =
                if s /= "KernelExports" then
                    orSelf s (Re.replace (Re.unsafe "Exports$") "" s)

                else
                    s
        in
        Just (CppNode ("cpp:eco:" ++ s2) ("Eco." ++ s2) "kernels" "eco-kernel-cpp")

    else if String.startsWith "system-kernel-cpp/src/" rel then
        if n > 4 then
            Just (CppNode ("cpp:sys:" ++ part 3) ("System." ++ part 3) "kernels" "system-kernel-cpp")

        else
            let
                s2 =
                    orSelf s (Re.replace (Re.unsafe "Exports$") "" s)
            in
            Just (CppNode ("cpp:sys:" ++ s2) ("System." ++ s2) "kernels" "system-kernel-cpp")

    else
        Nothing


orSelf : String -> String -> String
orSelf self s =
    if s == "" then
        self

    else
        s


{-| What every C++ stage stands on: the heap value model and the operations on
values, and the C ABI that generated code, kernels and runtime share.
-}
cppFound : List ( String, String, List String )
cppFound =
    [ ( "values"
      , "Heap and values"
      , [ "cpp:alloc:Heap", "cpp:alloc:CharValue", "cpp:alloc:TypeInfo", "cpp:alloc:HeapHelpers"
        , "cpp:alloc:RootedSlots", "cpp:alloc:StringOps", "cpp:alloc:ListOps", "cpp:alloc:BytesOps"
        , "cpp:alloc:ElmBytesRuntime", "cpp:alloc:Utf8", "cpp:alloc:CaseMap", "cpp:alloc:CaseMapTables"
        ]
      )
    , ( "abi"
      , "Runtime ABI"
      , [ "cpp:alloc:RuntimeExports", "cpp:ek:KernelExports", "cpp:eco:KernelExports"
        , "cpp:ek:ExportHelpers", "cpp:eco:ExportHelpers", "cpp:plat:TaskBinding", "cpp:eco:TaskBinding"
        ]
      )
    ]


{-| Node id → (section, index in section). -}
cppFoundSlot : Dict String ( Int, Int )
cppFoundSlot =
    cppFound
        |> List.indexedMap (\s ( _, _, ids ) -> List.indexedMap (\k i -> ( i, ( s, k ) )) ids)
        |> List.concat
        |> Dict.fromList


roots : Set String
roots =
    Set.fromList [ "Terminal.Main", "API.Main", "cpp:embed:eco_node_addon", "cpp:cg:EcoRunner" ]


elmJsons : List String
elmJsons =
    [ "compiler/elm.json", "compiler/build-xhr/elm.json" ]


{-| The paths the module graph reads. -}
sourcePaths : List String
sourcePaths =
    [ "compiler/src", "compiler/src-xhr", "compiler/src-version" ]
        ++ elmJsons
        ++ [ "runtime/src", "runtime/include", "elm-kernel-cpp", "eco-kernel-cpp", "system-kernel-cpp/src", "system-kernel-cpp/CMakeLists.txt" ]


{-| The paths git is asked about: the module graph's, and the prose. -}
logPaths : List String
logPaths =
    sourcePaths ++ [ "plans", "design_docs", "THEORY.md" ]


cppDirs : List String
cppDirs =
    [ "runtime/src/", "runtime/include/", "elm-kernel-cpp/src/", "eco-kernel-cpp/src/", "system-kernel-cpp/src/" ]


cmakes : Set String
cmakes =
    Set.fromList [ "runtime/src/codegen/CMakeLists.txt", "elm-kernel-cpp/CMakeLists.txt", "eco-kernel-cpp/CMakeLists.txt", "system-kernel-cpp/CMakeLists.txt" ]


twinDir : String
twinDir =
    "eco-kernel-cpp/src/"


{-| Lowest first. -}
libraries : List String
libraries =
    [ "runtime", "elm-kernel-cpp", "eco-kernel-cpp", "system-kernel-cpp" ]


isCppPath : String -> Bool
isCppPath path =
    List.any (\e -> String.endsWith e path) [ ".cpp", ".hpp", ".h", ".td" ] && startsWithAny cppDirs path


{-| Whether a path is part of the module graph. -}
relevant : String -> Bool
relevant path =
    if List.member path elmJsons || Set.member path cmakes then
        True

    else if String.endsWith ".elm" path then
        startsWithAny ([ "compiler/", twinDir ] ++ List.map .dir kernelLibraries) path

    else if isCppPath path then
        let
            dirs =
                String.split "/" path |> List.reverse |> List.drop 1
        in
        not (List.any (\d -> List.member d [ "third_party", "vendor", "tests", "test" ]) dirs)

    else
        False


{-| Whether a path is the compiler's config module, which defines the flags:
`Compiler/Config.elm` since the one-folder-per-pass reorganization
(eco-compiler e2647035), `Compiler/Eco/Config.elm` before it.
-}
isConfigPath : String -> Bool
isConfigPath path =
    String.endsWith "compiler/src/Compiler/Config.elm" path || String.endsWith "Compiler/Eco/Config.elm" path


{-| Whether a module name is the compiler's config module, old or new. -}
configModule : String -> Bool
configModule name =
    name == "Compiler.Config" || name == "Compiler.Eco.Config"


{-| A kernel library whose sources the atlas lists in full, in the kernel
sources band, as well as grouped in the Kernels stage: its source folder, the
prefix of its group nodes' ids, and the name its sections go by.
-}
type alias KernelLibrary =
    { dir : String, groupPrefix : String, name : String, title : String }


{-| In the order of their bands, each of which has a section per kernel. -}
kernelLibraries : List KernelLibrary
kernelLibraries =
    [ { dir = "elm-kernel-cpp/src/", groupPrefix = "cpp:ek:", name = "elm", title = "elm/* kernels" }
    , { dir = "eco-kernel-cpp/src/", groupPrefix = "cpp:eco:", name = "Eco", title = "eco/kernel" }
    , { dir = "system-kernel-cpp/src/", groupPrefix = "cpp:sys:", name = "System", title = "eco/system" }
    ]


{-| The library a path is in, with its index in `kernelLibraries`. -}
kernelLibraryOf : String -> Maybe ( Int, KernelLibrary )
kernelLibraryOf path =
    kernelLibraries
        |> List.indexedMap Tuple.pair
        |> List.filter (\( _, l ) -> String.startsWith l.dir path)
        |> List.head
