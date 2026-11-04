module Kg.Link exposing
    ( ModuleNode, ModuleGraph, Prepared, prepare, PackageKernels
    , modules, pairs
    , KernelSources, emptyKernelSources, kernelPairs
    )

{-| Facts → the module graph of one tree: a port of `extract` from
`script/atlas-graph.py` (deleted once kg matched its output; see git history) (§9.3 of the plan).

The nodes are the compiler's Elm modules and the C++ components; the edges
come from Elm imports, C++ includes, C++ names used in one file and defined in
another, kernel calls from Elm to C++, members defined outside their class's
component, and the libraries CMake has eco-boot link into programs.

Each edge keeps its kind: `imports`, `includes`, `uses_symbol`, `member`,
`kernel` or `links`. The atlas only needs the pairs.

`kernelSources` is for the atlas only: every Elm module and C++ file of the
kernel libraries in `Stages.kernelLibraries`, one node each, for the kernel
sources band. Each kernel's node in the Kernels stage `contains` its files.
The knowledge graph does not read it.

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
    , kernelSources : KernelSources
    }


{-| The kernel libraries' files, one node each, in the stage `kernelsrc`. A
node's `group` is its section of the band, written `library|kind|title` so
that it sorts: kind 0 is a kernel, 1 the headers no kernel owns, 2 the Elm
modules that call no kernel.
-}
type alias KernelSources =
    { nodes : Dict String ModuleNode
    , edges : Set ( String, String, String )
    , fileNode : Dict String String
    }


emptyKernelSources : KernelSources
emptyKernelSources =
    { nodes = Dict.empty, edges = Set.empty, fileNode = Dict.empty }


{-| The (from, to) pairs of the kernel sources' edges. -}
kernelPairs : ModuleGraph -> Set ( String, String )
kernelPairs g =
    Set.foldl (\( _, a, b ) acc -> Set.insert ( a, b ) acc) Set.empty g.kernelSources.edges


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

        -- the edges between C++ files' nodes, given the node of each file:
        -- includes, members defined outside their class's node, and names
        -- used in one node and defined in another
        passes nodeAt =
            let
                -- includes
                s2 =
                    List.foldl
                        (\p acc ->
                            let
                                nid =
                                    nodeAt p
                            in
                            List.foldl
                                (\inc a ->
                                    case resolve p inc of
                                        Just f ->
                                            let
                                                tgt =
                                                    nodeAt f
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
                        { included = Dict.empty, edges = Set.empty }
                        cppFiles

                included =
                    s2.included

                classHome : Dict String (Set String)
                classHome =
                    List.foldl
                        (\p acc ->
                            List.foldl (\c a -> Dict.update c (\v -> Just (Set.insert (nodeAt p) (Maybe.withDefault Set.empty v))) a)
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
                                        nodeAt p
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
                                                nodeAt p

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
            in
            { edges = s4, included = included, free = free, programs = programs }

        grouped =
            passes nodeOf

        -- each kernel library file as its own node, for the kernel sources
        fine =
            passes
                (\p ->
                    if isKernelSource p then
                        kernelSourceId p

                    else
                        nodeOf p
                )

        withCpp =
            Set.union elm.edges grouped.edges

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
                grouped.free

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
                withCpp
                elm.kernelImports

        -- the libraries eco-boot links programs against: their source files
        linked : List String
        linked =
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
                    |> List.concatMap
                        (\( var, prefix ) ->
                            Dict.get var variables
                                |> Maybe.withDefault []
                                |> List.concatMap (\mod -> Dict.get (prefix ++ mod) libs |> Maybe.withDefault [])
                        )
                    |> List.filter (\src -> Dict.member src fileNode && Dict.get src fileNode /= Just "cpp:cg:EcoBootConfig")

            else
                []

        s6 =
            List.foldl (\src e -> Set.insert ( "links", "cpp:cg:EcoBootConfig", nodeOf src ) e) s5 linked

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
    { nodes = withPaths
    , edges = s6
    , fileNode = fileNode
    , programs = grouped.programs
    , kernelSources =
        kernelSourcesOf input
            cppFiles
            fileNode
            s1.nodes
            (Set.union fine.edges
                (Set.fromList (List.filter isKernelSource linked |> List.map (\src -> ( "links", "cpp:cg:EcoBootConfig", kernelSourceId src ))))
            )
            elm.kernelImports
    }


{-| Whether a C++ file is listed in full in the kernel sources band. -}
isKernelSource : String -> Bool
isKernelSource p =
    Stages.kernelLibraryOf p /= Nothing


kernelSourceId : String -> String
kernelSourceId p =
    "cpp:src:" ++ P.stripExtension p


{-| `fileEdges` are the C++ edges with each kernel library file as its own
node; `kernelImports` the kernel modules each compiler module calls.
-}
kernelSourcesOf : Input -> List String -> Dict String String -> Dict String ModuleNode -> Set ( String, String, String ) -> Dict String (Set String) -> KernelSources
kernelSourcesOf input cppFiles fileNode groups fileEdges kernelImports =
    let
        cppId =
            kernelSourceId

        elmId p =
            "src:" ++ p

        stemOf p =
            P.stripExtension (P.basename p)

        sectionKey li kind title =
            String.fromInt li ++ "|" ++ String.fromInt kind ++ "|" ++ title

        -- the C++ files, with their library and kernel group
        cpps : List { path : String, li : Int, lib : Stages.KernelLibrary, group : String }
        cpps =
            cppFiles
                |> List.filterMap
                    (\p ->
                        case ( Stages.kernelLibraryOf p, Dict.get p fileNode ) of
                            ( Just ( li, lib ), Just g ) ->
                                Just { path = p, li = li, lib = lib, group = g }

                            _ ->
                                Nothing
                    )

        cppSet =
            Set.fromList (List.map .path cpps)

        -- the files that define each kernel prefix, such as Eco_Kernel_Socket
        definers : Dict String (Set String)
        definers =
            List.foldl
                (\c acc ->
                    Dict.get c.path input.cpp
                        |> Maybe.map (.facts >> .defs)
                        |> Maybe.withDefault []
                        |> List.foldl
                            (\( _, name ) a ->
                                case Re.firstMatch kernelPrefixRe name |> Maybe.andThen (.groups >> List.head >> Maybe.andThen identity) of
                                    Just prefix ->
                                        Dict.update prefix (\v -> Just (Set.insert c.path (Maybe.withDefault Set.empty v))) a

                                    Nothing ->
                                        a
                            )
                            acc
                )
                Dict.empty
                cpps

        -- the Elm modules
        elms : List { path : String, li : Int, lib : Stages.KernelLibrary, name : String, imports : List String, calls : List String }
        elms =
            Dict.toList input.files
                |> List.filterMap
                    (\( p, f ) ->
                        case ( f, Stages.kernelLibraryOf p ) of
                            ( ElmFile e, Just ( li, lib ) ) ->
                                if String.endsWith ".elm" p then
                                    let
                                        imports =
                                            List.map .name e.imports
                                    in
                                    Just
                                        { path = p
                                        , li = li
                                        , lib = lib
                                        , name = String.dropLeft (String.length lib.dir) p |> String.dropRight 4 |> String.replace "/" "."
                                        , imports = imports
                                        , calls =
                                            imports
                                                |> List.filter (String.contains ".Kernel.")
                                                |> List.concatMap (\km -> Dict.get (String.replace "." "_" km) definers |> Maybe.map Set.toList |> Maybe.withDefault [])
                                                |> List.filter (\c -> Set.member c cppSet)
                                        }

                                else
                                    Nothing

                            _ ->
                                Nothing
                    )

        elmByName =
            List.foldl (\m acc -> Dict.insert ( m.li, m.name ) m.path acc) Dict.empty elms

        -- the kernel an Elm module belongs to: the one it calls, or else the
        -- one its name says
        elmGroup m =
            case m.calls |> List.filterMap (\c -> Dict.get c fileNode) |> List.sort |> List.head of
                Just g ->
                    Just g

                Nothing ->
                    let
                        segment =
                            String.split "." m.name
                                |> List.drop
                                    (if String.startsWith (m.lib.name ++ ".") m.name then
                                        1

                                     else
                                        0
                                    )
                                |> List.head
                                |> Maybe.withDefault ""

                        g =
                            m.lib.groupPrefix ++ segment
                    in
                    if Dict.member g groups then
                        Just g

                    else
                        Nothing

        -- a module with no kernel of its own goes with its parent:
        -- Http.Server.Internal with Http.Server
        elmGroupOrParent m =
            case elmGroup m of
                Just g ->
                    Just g

                Nothing ->
                    let
                        parent =
                            String.split "." m.name |> List.reverse |> List.drop 1 |> List.reverse |> String.join "."
                    in
                    elms
                        |> List.filter (\o -> o.li == m.li && o.name == parent)
                        |> List.head
                        |> Maybe.andThen elmGroupOrParent

        elmGroups =
            List.map (\m -> ( m, elmGroupOrParent m )) elms

        -- the groups that are one shared file and no kernel, such as
        -- KernelExports.h or EffectManagerRegistry.cpp, share a section: a
        -- header, or a file at the top of the library
        lone : Set String
        lone =
            let
                byGroup =
                    List.foldl (\c acc -> Dict.update c.group (\v -> Just (c :: Maybe.withDefault [] v)) acc) Dict.empty cpps

                withElm =
                    List.filterMap Tuple.second elmGroups |> Set.fromList

                shared c =
                    List.any (\e -> String.endsWith e c.path) [ ".h", ".hpp" ] || P.dirname c.path ++ "/" == c.lib.dir
            in
            byGroup
                |> Dict.filter
                    (\g cs ->
                        (Set.size (Set.fromList (List.map (.path >> cppId) cs)) == 1)
                            && not (Set.member g withElm)
                            && List.all shared cs
                    )
                |> Dict.keys
                |> Set.fromList

        groupSection li lib g =
            if Set.member g lone then
                sectionKey li 1 "Shared"

            else
                sectionKey li 0 (Dict.get g groups |> Maybe.map .label |> Maybe.withDefault g)

        cppNodes =
            List.foldl
                (\c acc ->
                    let
                        id =
                            cppId c.path
                    in
                    Dict.update id
                        (\v ->
                            case v of
                                Just n ->
                                    Just { n | files = n.files ++ [ c.path ], path = n.path ++ ", " ++ c.path }

                                Nothing ->
                                    Just
                                        { id = id
                                        , label = stemOf c.path
                                        , lang = "cpp"
                                        , stage = "kernelsrc"
                                        , path = c.path
                                        , group = groupSection c.li c.lib c.group
                                        , files = [ c.path ]
                                        }
                        )
                        acc
                )
                Dict.empty
                cpps

        nodes =
            List.foldl
                (\( m, g ) acc ->
                    Dict.insert (elmId m.path)
                        { id = elmId m.path
                        , label = m.name
                        , lang = "elm"
                        , stage = "kernelsrc"
                        , path = m.path
                        , group =
                            case g of
                                Just k ->
                                    groupSection m.li m.lib k

                                Nothing ->
                                    sectionKey m.li 2 "Elm only"
                        , files = [ m.path ]
                        }
                        acc
                )
                cppNodes
                elmGroups

        contains =
            List.map (\c -> ( "contains", c.group, cppId c.path )) cpps
                ++ List.filterMap (\( m, g ) -> Maybe.map (\k -> ( "contains", k, elmId m.path )) g) elmGroups

        -- every C++ edge with a kernel library file at either end
        cppEdges =
            fileEdges
                |> Set.toList
                |> List.filter (\( _, a, b ) -> a /= b && (String.startsWith "cpp:src:" a || String.startsWith "cpp:src:" b))

        -- the compiler's calls into the kernels, to the files that define them
        compilerCalls =
            Dict.toList kernelImports
                |> List.concatMap
                    (\( mod, kms ) ->
                        Set.toList kms
                            |> List.concatMap (\km -> Dict.get (String.replace "." "_" km) definers |> Maybe.map Set.toList |> Maybe.withDefault [])
                            |> List.map (\f -> ( "kernel", mod, cppId f ))
                    )

        elmEdges =
            elms
                |> List.concatMap
                    (\m ->
                        List.filterMap (\i -> Dict.get ( m.li, i ) elmByName |> Maybe.map (\p -> ( "imports", elmId m.path, elmId p ))) m.imports
                            ++ List.map (\c -> ( "kernel", elmId m.path, cppId c )) m.calls
                    )
    in
    { nodes = nodes
    , edges = Set.fromList (contains ++ cppEdges ++ compilerCalls ++ elmEdges)
    , fileNode =
        Dict.fromList (List.map (\c -> ( c.path, cppId c.path )) cpps ++ List.map (\m -> ( m.path, elmId m.path )) elms)
    }


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
