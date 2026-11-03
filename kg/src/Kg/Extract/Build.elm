module Kg.Extract.Build exposing (elmJson, cmake)

{-| `elm.json` and `CMakeLists.txt` facts (§8.3 of the plan), a port of
`cmake_libraries` and the CMake reading in `extract`.
-}

import Dict exposing (Dict)
import Json.Decode as D
import Kg.Facts exposing (CMakeFacts, FileFacts(..), TableGen(..))
import Kg.PathUtil as P
import Kg.Re as Re exposing (Regex)


elmJson : String -> FileFacts
elmJson text =
    let
        deps =
            D.oneOf [ D.keyValuePairs D.string, D.succeed [] ]

        decoder =
            D.map3 (\dirs direct indirect -> { sourceDirectories = dirs, dependencies = direct ++ indirect })
                (D.oneOf [ D.field "source-directories" (D.list D.string), D.succeed [] ])
                (D.oneOf [ D.at [ "dependencies", "direct" ] deps, D.succeed [] ])
                (D.oneOf [ D.at [ "dependencies", "indirect" ] deps, D.succeed [] ])
    in
    case D.decodeString decoder text of
        Ok facts ->
            ElmJson facts

        Err _ ->
            Unparsed "invalid JSON"


setRe : Regex
setRe =
    Re.unsafe "set\\((\\w+)\\s+([^)]*)\\)"


addLibraryRe : Regex
addLibraryRe =
    Re.unsafe "add_library\\(\\s*(\\w+)\\s+STATIC\\s+([^)]*)\\)"


systemModuleRe : Regex
systemModuleRe =
    Re.unsafe "eco_system_module\\(\\s*(\\w+)\\s+([^)]*)\\)"


varRefRe : Regex
varRefRe =
    Re.unsafe "^\\$\\{(\\w+)\\}$"


tablegenRe : Regex
tablegenRe =
    Re.unsafe "set\\(LLVM_TARGET_DEFINITIONS\\s+(\\S+)\\)|mlir_tablegen\\(\\S*?([\\w.]+\\.inc)\\s"


modsVariables : List String
modsVariables =
    [ "ECO_ELM_KERNEL_MODS", "ECO_KERNEL_MODS", "ECO_SYSTEM_MODS" ]


groups2 : Re.Match -> ( String, String )
groups2 m =
    case m.groups of
        [ a, b ] ->
            ( Maybe.withDefault "" a, Maybe.withDefault "" b )

        _ ->
            ( "", "" )


cmake : String -> String -> CMakeFacts
cmake path text =
    let
        base =
            P.dirname path

        vars : Dict String (List String)
        vars =
            Re.findAll setRe text
                |> List.foldl (\m d -> groups2 m |> (\( k, v ) -> Dict.insert k (String.words v) d)) Dict.empty

        sources depth words =
            words
                |> List.concatMap
                    (\w ->
                        case Re.fullMatch varRefRe w |> Maybe.andThen (.groups >> List.head >> Maybe.andThen identity) of
                            Just v ->
                                if depth > 8 then
                                    []

                                else
                                    sources (depth + 1) (Dict.get v vars |> Maybe.withDefault [])

                            Nothing ->
                                [ w ]
                    )

        cppSources words =
            sources 0 words
                |> List.filter (String.endsWith ".cpp")
                |> List.map (\w -> P.normpath (P.join base w))

        libraries =
            (Re.findAll addLibraryRe text |> List.map (groups2 >> (\( n, ws ) -> ( n, cppSources (String.words ws) ))))
                ++ (Re.findAll systemModuleRe text |> List.map (groups2 >> (\( n, ws ) -> ( "EcoSystem_" ++ n, cppSources (String.words ws) ))))

        tablegen =
            Re.findAll tablegenRe text
                |> List.filterMap
                    (\m ->
                        case m.groups of
                            [ Just td, _ ] ->
                                Just (TableGenDefinitions (P.normpath (P.join base td)))

                            [ _, Just inc ] ->
                                Just (TableGenInc inc)

                            _ ->
                                Nothing
                    )

        variables =
            modsVariables
                |> List.filterMap
                    (\v ->
                        Re.firstMatch (Re.unsafe ("set\\(" ++ v ++ "\\s+([\\s\\S]*?)\\s+CACHE")) text
                            |> Maybe.andThen (.groups >> List.head >> Maybe.andThen identity)
                            |> Maybe.map (\mods -> ( v, String.words mods ))
                    )
    in
    { libraries = libraries, tablegen = tablegen, variables = variables }
