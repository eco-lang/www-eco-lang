module Kg.Context exposing (Context, resolve, packageKernels)

{-| Where kg is working: the worktree, its repository, the cache, and the
settings from the environment (§15 of the plan).

The worktree is `CLAUDE_PROJECT_DIR` when set (Claude Code sets it to the
project root), else `--worktree`, else the working directory. It must be inside
an eco-compiler worktree: one with `compiler/src`.

-}

import Dict exposing (Dict)
import FileSystem
import Kg.Fs as Fs exposing (Paths)
import Kg.Git as Git
import Kg.Link exposing (PackageKernels)
import Kg.Re as Re
import Path
import Set exposing (Set)
import System
import Task exposing (Task)


type alias Context =
    { worktree : String
    , commonDir : String
    , paths : Paths
    , vars : Dict String String
    , elmHome : String
    , ollama : String
    , model : String
    , dimensions : Maybe Int
    }


resolve : Maybe String -> Task String Context
resolve flag =
    Task.map2 Tuple.pair System.environmentVariables FileSystem.currentWorkingDirectory
        |> Task.andThen
            (\( vars, cwd ) ->
                let
                    start =
                        case ( flag, Dict.get "CLAUDE_PROJECT_DIR" vars ) of
                            ( Just w, _ ) ->
                                w

                            ( Nothing, Just d ) ->
                                d

                            ( Nothing, Nothing ) ->
                                Path.toPosixString cwd
                in
                Task.map2 Tuple.pair (Git.topLevel start) (Git.commonDir start)
                    |> Task.andThen
                        (\( top, common ) ->
                            Fs.isDirectory (top ++ "/compiler/src")
                                |> Task.andThen
                                    (\ok ->
                                        if not ok then
                                            Task.fail (top ++ " is not an eco-compiler worktree: it has no compiler/src")

                                        else
                                            let
                                                home =
                                                    Dict.get "HOME" vars |> Maybe.withDefault "."
                                            in
                                            Task.succeed
                                                { worktree = top
                                                , commonDir = common
                                                , paths = Fs.paths (Fs.cacheRoot vars) common top
                                                , vars = vars
                                                , elmHome = Dict.get "ELM_HOME" vars |> Maybe.withDefault (home ++ "/.elm")
                                                , ollama = Dict.get "ECO_KG_OLLAMA" vars |> Maybe.withDefault "http://127.0.0.1:11434"
                                                , model = Dict.get "ECO_KG_MODEL" vars |> Maybe.withDefault "nomic-embed-text"
                                                , dimensions =
                                                    -- nomic's vectors are cut to 384 dimensions unless asked otherwise (phase 5)
                                                    case ( Dict.get "ECO_KG_DIMENSIONS" vars |> Maybe.andThen String.toInt, Dict.get "ECO_KG_MODEL" vars ) of
                                                        ( Just d, _ ) ->
                                                            Just d

                                                        ( Nothing, Nothing ) ->
                                                            Just 384

                                                        ( Nothing, Just _ ) ->
                                                            Nothing
                                                }
                                    )
                        )
            )


{-| The kernel modules each module of each `elm/*` and `elm-explorations/*`
package in ELM_HOME imports, read with the Python's regular expression, as
`package_kernels` did. Every version present is read.
-}
packageKernels : String -> Task String PackageKernels
packageKernels elmHome =
    let
        root =
            elmHome ++ "/0.19.1/packages"

        authors =
            [ "elm", "elm-explorations" ]

        listNames dir =
            Fs.listDir dir |> Task.onError (\_ -> Task.succeed [])

        importRe =
            Re.compileWith { caseInsensitive = False, multiline = True } "^import\\s+([A-Z][\\w.]*)" |> Maybe.withDefault (Re.unsafe "(?!)")

        elmFiles dir prefix =
            listNames dir
                |> Task.andThen
                    (\entries ->
                        entries
                            |> List.map
                                (\e ->
                                    if e.isDir then
                                        elmFiles (dir ++ "/" ++ e.name) (prefix ++ e.name ++ ".")

                                    else if String.endsWith ".elm" e.name then
                                        Fs.readTextMaybe (dir ++ "/" ++ e.name)
                                            |> Task.map
                                                (\text ->
                                                    [ ( prefix ++ String.dropRight 4 e.name
                                                      , Re.findAll importRe (Maybe.withDefault "" text)
                                                            |> List.filterMap (.groups >> List.head >> Maybe.andThen identity)
                                                            |> List.filter (String.contains ".Kernel.")
                                                            |> Set.fromList
                                                      )
                                                    ]
                                                )

                                    else
                                        Task.succeed []
                                )
                            |> Task.sequence
                            |> Task.map List.concat
                    )
    in
    authors
        |> List.map
            (\author ->
                listNames (root ++ "/" ++ author)
                    |> Task.andThen
                        (\projects ->
                            projects
                                |> List.map
                                    (\project ->
                                        listNames (root ++ "/" ++ author ++ "/" ++ project.name)
                                            |> Task.andThen
                                                (\versions ->
                                                    versions
                                                        |> List.map
                                                            (\v ->
                                                                elmFiles (root ++ "/" ++ author ++ "/" ++ project.name ++ "/" ++ v.name ++ "/src") ""
                                                                    |> Task.map (\mods -> ( ( author ++ "/" ++ project.name, v.name ), Dict.fromList mods ))
                                                            )
                                                        |> Task.sequence
                                                )
                                    )
                                |> Task.sequence
                                |> Task.map List.concat
                        )
            )
        |> Task.sequence
        |> Task.map (List.concat >> Dict.fromList)
