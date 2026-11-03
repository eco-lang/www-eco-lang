module Kg.Link exposing
    ( ModuleNode, ModuleGraph, Prepared, prepare, PackageKernels
    , modules, pairs
    )

{-| Facts → the module graph of one tree: a port of `extract` from
`script/atlas-graph.py` (deleted once kg matched its output; see git history) (§9.3 of the plan).

The nodes are the compiler's Elm modules and the C++ components; the edges
come from Elm imports, C++ includes, C++ names used in one file and defined in
another, kernel calls from Elm to C++, members defined outside their class's
component, and the libraries CMake has eco-boot link into programs.

Each edge keeps its kind: `imports`, `includes`, `uses_symbol`, `member`,
`kernel` or `links`. The atlas only needs the pairs.

-}

import Dict exposing (Dict)
import Kg.Facts as F exposing (CppFacts, FileFacts(..), TableGen(..))
import Kg.PathUtil as P
import Kg.Re as Re
import Kg.Stages as Stages
import Set exposing (Set)


type alias ModuleNode =
    { id : String, label : String, lang : String, stage : String, path : String, group : String, files : List String }


type alias ModuleGraph =
    { nodes : Dict String ModuleNode
    , edges : Set ( String, String, String )
    , fileNode : Dict String String
    , programs : Set String
    }


{-| A C++ file's facts with its tokens as a set, made once per blob. -}
type alias Prepared =
    { facts : CppFacts, tokenSet : Set String }


prepare : CppFacts -> Prepared
prepare facts =
    { facts = facts, tokenSet = Set.fromList facts.tokens }


{-| Package → module → the kernel modules it imports, for the packages that
may have kernel code (`elm/*`, `elm-explorations/*`), read from ELM_HOME.
-}
type alias PackageKernels =
    Dict ( String, String ) (Dict String (Set String))


{-| The (from, to) pairs of the edges, whatever their kind. -}
pairs : ModuleGraph -> Set ( String, String )
pairs g =
    Set.foldl (\( _, a, b ) acc -> Set.insert ( a, b ) acc) Set.empty g.edges


type alias Input =
    { files : Dict String FileFacts
    , cpp : Dict String Prepared
    , packages : PackageKernels
    }


modules : Input -> ModuleGraph
modules input =
    let
        elm =
            elmPart input

        cppg =
            cppPart input elm
    in
    cppg


elmJsonFound : Dict String FileFacts -> Maybe ( F.ElmJsonFacts, String )
elmJsonFound files =
    Stages.elmJsons
        |> List.filterMap
            (\p ->
                case Dict.get p files of
                    Just (ElmJson j) ->
                        Just ( j, P.dirname p )

                    _ ->
                        Nothing
            )
        |> List.head


type alias ElmPart =
    { nodes : Dict String ModuleNode
    , edges : Set ( String, String, String )
    , fileNode : Dict String String
    , kernelImports : Dict String (Set String)
    }


elmPart : Input -> ElmPart
elmPart input =
    case elmJsonFound input.files of
        Nothing ->
            { nodes = Dict.empty, edges = Set.empty, fileNode = Dict.empty, kernelImports = Dict.empty }

        Just ( json, home ) ->
            let
                dirs =
                    List.map (\d -> P.normpath (P.join home d) ++ "/") json.sourceDirectories

                elmPaths =
                    Dict.keys input.files |> List.filter (String.endsWith ".elm")

                moduleOf prefix p =
                    String.dropLeft (String.length prefix) p |> String.dropRight 4 |> String.replace "/" "."

                fromDirs : Dict String (List String)
                fromDirs =
                    List.foldl
                        (\p acc ->
                            List.foldl
                                (\d a ->
                                    if String.startsWith d p then
                                        Dict.update (moduleOf d p) (\v -> Just (Maybe.withDefault [] v ++ [ p ])) a

                                    else
                                        a
                                )
                                acc
                                dirs
                        )
                        Dict.empty
                        elmPaths

                elmFiles =
                    List.foldl
                        (\p acc ->
                            if String.startsWith Stages.twinDir p then
                                let
                                    m =
                                        moduleOf Stages.twinDir p
                                in
                                if Dict.member m acc then
                                    Dict.update m (Maybe.map (\v -> v ++ [ p ])) acc

                                else
                                    acc

                            else
                                acc
                        )
                        fromDirs
                        elmPaths

                pkgKernels : Dict String (Set String)
                pkgKernels =
                    json.dependencies
                        |> List.filter (\( pkg, _ ) -> List.member (String.split "/" pkg |> List.head |> Maybe.withDefault "") [ "elm", "elm-explorations" ])
                        |> List.foldl (\key acc -> Dict.union (Dict.get key input.packages |> Maybe.withDefault Dict.empty) acc) Dict.empty

                importsOf p =
                    case Dict.get p input.files of
                        Just (ElmFile f) ->
                            List.map .name f.imports

                        _ ->
                            []

                step mod paths acc =
                    let
                        node =
                            { id = mod
                            , label =
                                if String.startsWith "Compiler." mod then
                                    String.dropLeft 9 mod

                                else
                                    mod
                            , lang = "elm"
                            , stage = Stages.elmStage mod
                            , path = String.join ", " paths
                            , group = String.split "." mod |> List.take 3 |> String.join "."
                            , files = paths
                            }

                        withFiles =
                            List.foldl (\p a -> { a | fileNode = Dict.insert p mod a.fileNode }) { acc | nodes = Dict.insert mod node acc.nodes } paths
                    in
                    List.foldl
                        (\m a ->
                            if Dict.member m elmFiles then
                                if m /= mod then
                                    { a | edges = Set.insert ( "imports", mod, m ) a.edges }

                                else
                                    a

                            else if String.contains ".Kernel." m then
                                { a | kernelImports = Dict.update mod (\s -> Just (Set.insert m (Maybe.withDefault Set.empty s))) a.kernelImports }

                            else
                                case Dict.get m pkgKernels of
                                    Just ks ->
                                        { a | kernelImports = Dict.update mod (\s -> Just (Set.union ks (Maybe.withDefault Set.empty s))) a.kernelImports }

                                    Nothing ->
                                        a
                        )
                        withFiles
                        (List.concatMap importsOf paths)
            in
            Dict.foldl step { nodes = Dict.empty, edges = Set.empty, fileNode = Dict.empty, kernelImports = Dict.empty } elmFiles


kernelPrefixRe : Re.Regex
kernelPrefixRe =
    Re.unsafe "^([A-Z][a-z]+_Kernel_[A-Za-z0-9]+)_"


cppPart : Input -> ElmPart -> ModuleGraph
cppPart input elm =
    let
        cppPaths =
            Dict.keys input.files |> List.filter Stages.isCppPath

        -- nodes, the file map and the basenames
        step1 p acc =
            case Stages.cppNodeFor p of
                Nothing ->
                    acc

                Just n ->
                    let
                        node =
                            case Dict.get n.id acc.nodes of
                                Just existing ->
                                    { existing | files = existing.files ++ [ p ] }

                                Nothing ->
                                    { id = n.id
                                    , label = n.label
                                    , lang = "cpp"
                                    , stage =
                                        if Dict.member n.id Stages.cppFoundSlot then
                                            "cppfound"

                                        else
                                            n.stage
                                    , path = ""
                                    , group = n.group
                                    , files = [ p ]
                                    }
                    in
                    { acc
                        | nodes = Dict.insert n.id node acc.nodes
                        , fileNode = Dict.insert p n.id acc.fileNode
                        , byBase = Dict.update (P.basename p) (\v -> Just (Maybe.withDefault [] v ++ [ n.id ])) acc.byBase
                        , cppFiles = p :: acc.cppFiles
                    }

        s1 =
            List.foldl step1 { nodes = elm.nodes, fileNode = elm.fileNode, byBase = Dict.empty, cppFiles = [] } cppPaths

        cppFiles =
            List.reverse s1.cppFiles

        fileNode =
            s1.fileNode

        nodeOf p =
            Dict.get p fileNode |> Maybe.withDefault ""

        factsOf p =
            Dict.get p input.cpp |> Maybe.map .facts

        -- headers the build writes: TableGen's .inc files, and EcoBootConfig.h
        codegenCMake =
            case Dict.get "runtime/src/codegen/CMakeLists.txt" input.files of
                Just (CMake c) ->
                    Just c

                _ ->
                    Nothing

        byBase =
            let
                withInc =
                    codegenCMake
                        |> Maybe.map .tablegen
                        |> Maybe.withDefault []
                        |> List.foldl
                            (\t ( td, acc ) ->
                                case t of
                                    TableGenDefinitions path ->
                                        ( Dict.get path fileNode, acc )

                                    TableGenInc inc ->
                                        case td of
                                            Just tdNode ->
                                                ( td, Dict.update inc (\v -> Just (Maybe.withDefault [] v ++ [ tdNode ])) acc )

                                            Nothing ->
                                                ( td, acc )
                            )
                            ( Nothing, s1.byBase )
                        |> Tuple.second
            in
            if Dict.member "cpp:cg:EcoBootConfig" s1.nodes then
                Dict.update "EcoBootConfig.h" (\v -> Just (Maybe.withDefault [] v ++ [ "cpp:cg:EcoBootConfig" ])) withInc

            else
                withInc

        filesByBase : Dict String (List String)
        filesByBase =
            List.foldl (\p acc -> Dict.update (P.basename p) (\v -> Just (Maybe.withDefault [] v ++ [ p ])) acc) Dict.empty cppFiles

        libraryIndex top =
            indexOf top Stages.libraries |> Maybe.withDefault 99

        resolve p inc =
            let
                near =
                    P.normpath (P.join (P.dirname p) inc)
            in
            if Dict.member near fileNode then
                Just near

            else
                let
                    suffix =
                        "/" ++ dropLeadingDotSlash inc

                    cands =
                        Dict.get (P.basename inc) filesByBase |> Maybe.withDefault [] |> List.filter (String.endsWith suffix)

                    top =
                        String.split "/" p |> List.head |> Maybe.withDefault ""

                    key f =
                        let
                            ftop =
                                String.split "/" f |> List.head |> Maybe.withDefault ""
                        in
                        ( if ftop /= top then
                            1

                          else
                            0
                        , libraryIndex ftop
                        , ( -(P.commonpathLength f p), f )
                        )
                in
                cands |> List.sortBy key |> List.head

        -- includes
        s2 =
            List.foldl
                (\p acc ->
                    let
                        nid =
                            nodeOf p
                    in
                    List.foldl
                        (\inc a ->
                            case resolve p inc of
                                Just f ->
                                    let
                                        tgt =
                                            nodeOf f
                                    in
                                    { a
                                        | included = Dict.update p (\v -> Just (Set.insert f (Maybe.withDefault Set.empty v))) a.included
                                        , edges =
                                            if tgt /= nid then
                                                Set.insert ( "includes", nid, tgt ) a.edges

                                            else
                                                a.edges
                                    }

                                Nothing ->
                                    let
                                        base =
                                            P.basename inc
                                    in
                                    case Dict.get base byBase of
                                        Just (tgt :: _) ->
                                            if not (Dict.member base filesByBase) && tgt /= nid then
                                                { a | edges = Set.insert ( "includes", nid, tgt ) a.edges }

                                            else
                                                a

                                        _ ->
                                            a
                        )
                        acc
                        (factsOf p |> Maybe.map .includes |> Maybe.withDefault [])
                )
                { included = Dict.empty, edges = elm.edges }
                cppFiles

        included =
            s2.included

        classHome : Dict String (Set String)
        classHome =
            List.foldl
                (\p acc ->
                    List.foldl (\c a -> Dict.update c (\v -> Just (Set.insert (nodeOf p) (Maybe.withDefault Set.empty v))) a)
                        acc
                        (factsOf p |> Maybe.map .classes |> Maybe.withDefault [])
                )
                Dict.empty
                cppFiles

        -- members defined outside their class's node, and the free definitions
        s3 =
            List.foldl
                (\p acc ->
                    if not (String.endsWith ".cpp" p) then
                        acc

                    else
                        let
                            nid =
                                nodeOf p
                        in
                        List.foldl
                            (\( ns, name ) a ->
                                let
                                    ownerClass =
                                        if ns == "" then
                                            ""

                                        else
                                            String.split "::" ns |> List.reverse |> List.head |> Maybe.withDefault ""
                                in
                                case Dict.get ownerClass classHome of
                                    Just homesAll ->
                                        let
                                            homes =
                                                Set.remove nid homesAll
                                        in
                                        if Set.size homesAll == 1 && not (Set.isEmpty homes) then
                                            { a | edges = Set.insert ( "member", Set.toList homes |> List.head |> Maybe.withDefault "", nid ) a.edges }

                                        else
                                            a

                                    Nothing ->
                                        { a | free = Dict.update name (\v -> Just (Set.insert ( ns, nid ) (Maybe.withDefault Set.empty v))) a.free }
                            )
                            acc
                            (factsOf p |> Maybe.map .defs |> Maybe.withDefault [])
                )
                { edges = s2.edges, free = Dict.empty }
                cppFiles

        free =
            s3.free

        programs =
            Dict.get "main" free |> Maybe.withDefault Set.empty |> Set.map Tuple.second

        closure p =
            let
                go todo seen =
                    case todo of
                        f :: rest ->
                            let
                                next =
                                    Dict.get f included |> Maybe.withDefault Set.empty |> Set.filter (\x -> not (Set.member x seen))
                            in
                            go (Set.toList next ++ rest) (Set.union next seen)

                        [] ->
                            seen
            in
            go [ p ] Set.empty

        -- uses of names defined elsewhere
        s4 =
            List.foldl
                (\p edges ->
                    case Dict.get p input.cpp of
                        Nothing ->
                            edges

                        Just prepared ->
                            let
                                info =
                                    prepared.facts

                                names =
                                    info.tokens |> List.filter (\n -> n /= "main" && Dict.member n free)
                            in
                            if List.isEmpty names then
                                edges

                            else
                                let
                                    nid =
                                        nodeOf p

                                    visible =
                                        closure p |> Set.toList |> List.filterMap (\f -> Dict.get f input.cpp)

                                    opened =
                                        info.opened
                                in
                                List.foldl
                                    (\name es ->
                                        case Dict.get name info.uses of
                                            Nothing ->
                                                es

                                            Just u ->
                                                if not u.declares && not (List.any (\v -> Set.member name v.tokenSet) visible) then
                                                    es

                                                else
                                                    List.foldl
                                                        (\q es2 ->
                                                            let
                                                                owners =
                                                                    Dict.get name free
                                                                        |> Maybe.withDefault Set.empty
                                                                        |> Set.filter (\( ns, _ ) -> reaches ns q opened)
                                                                        |> Set.map Tuple.second
                                                                        |> Set.remove nid
                                                                        |> (\s -> Set.diff s programs)
                                                            in
                                                            if Set.size owners > 0 && Set.size owners <= 3 then
                                                                Set.foldl (\o e -> Set.insert ( "uses_symbol", nid, o ) e) es2 owners

                                                            else
                                                                es2
                                                        )
                                                        es
                                                        u.quals
                                    )
                                    edges
                                    names
                )
                s3.edges
                cppFiles

        -- Elm to C++ kernels
        definers : Dict String (Set String)
        definers =
            Dict.foldl
                (\name owners acc ->
                    case Re.firstMatch kernelPrefixRe name |> Maybe.andThen (.groups >> List.head >> Maybe.andThen identity) of
                        Just prefix ->
                            Dict.update prefix (\v -> Just (Set.union (Set.map Tuple.second owners) (Maybe.withDefault Set.empty v))) acc

                        Nothing ->
                            acc
                )
                Dict.empty
                free

        s5 =
            Dict.foldl
                (\mod kms edges ->
                    Set.foldl
                        (\km es ->
                            Set.foldl (\o e -> Set.insert ( "kernel", mod, o ) e) es (Dict.get (String.replace "." "_" km) definers |> Maybe.withDefault Set.empty)
                        )
                        edges
                        kms
                )
                s4
                elm.kernelImports

        -- the libraries eco-boot links programs against
        s6 =
            if Dict.member "cpp:cg:EcoBootConfig" s1.nodes then
                let
                    libs : Dict String (List String)
                    libs =
                        Set.toList (Set.remove "runtime/src/codegen/CMakeLists.txt" Stages.cmakes)
                            |> List.foldl
                                (\cm acc ->
                                    case Dict.get cm input.files of
                                        Just (CMake c) ->
                                            List.foldl (\( k, v ) a -> Dict.insert k v a) acc c.libraries

                                        _ ->
                                            acc
                                )
                                Dict.empty

                    variables =
                        codegenCMake |> Maybe.map .variables |> Maybe.withDefault [] |> Dict.fromList
                in
                [ ( "ECO_ELM_KERNEL_MODS", "ElmKernel_" ), ( "ECO_KERNEL_MODS", "EcoKernel_" ), ( "ECO_SYSTEM_MODS", "EcoSystem_" ) ]
                    |> List.foldl
                        (\( var, prefix ) edges ->
                            Dict.get var variables
                                |> Maybe.withDefault []
                                |> List.foldl
                                    (\mod es ->
                                        Dict.get (prefix ++ mod) libs
                                            |> Maybe.withDefault []
                                            |> List.foldl
                                                (\src e ->
                                                    case Dict.get src fileNode of
                                                        Just n ->
                                                            if n /= "cpp:cg:EcoBootConfig" then
                                                                Set.insert ( "links", "cpp:cg:EcoBootConfig", n ) e

                                                            else
                                                                e

                                                        Nothing ->
                                                            e
                                                )
                                                es
                                    )
                                    edges
                        )
                        s5

            else
                s5

        withPaths =
            Dict.map
                (\_ n ->
                    if n.lang == "cpp" then
                        let
                            fs =
                                List.sort n.files
                        in
                        { n
                            | files = fs
                            , path =
                                if List.length fs > 2 then
                                    P.dirname (List.head fs |> Maybe.withDefault "") ++ "/"

                                else
                                    String.join ", " fs
                        }

                    else
                        n
                )
                s1.nodes
    in
    { nodes = withPaths, edges = s6, fileNode = fileNode, programs = programs }


dropLeadingDotSlash : String -> String
dropLeadingDotSlash s =
    if String.startsWith "." s || String.startsWith "/" s then
        dropLeadingDotSlash (String.dropLeft 1 s)

    else
        s


{-| Whether a use of a name, qualified by `qualifier` ("" for none) in a file
that opens the namespaces `opened`, can find it in namespace `ns`.
-}
reaches : String -> String -> List String -> Bool
reaches ns qualifier opened =
    if ns == "" then
        qualifier == ""

    else if qualifier /= "" then
        let
            prefixes o =
                let
                    parts =
                        String.split "::" o
                in
                List.range 1 (List.length parts) |> List.map (\k -> String.join "::" (List.take k parts))

            scopes =
                "" :: List.concatMap prefixes opened
        in
        List.any
            (\sc ->
                ns
                    == (if sc /= "" then
                            sc ++ "::" ++ qualifier

                        else
                            qualifier
                       )
            )
            scopes

    else
        List.any (\o -> o == ns || String.startsWith (ns ++ "::") o) opened


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
