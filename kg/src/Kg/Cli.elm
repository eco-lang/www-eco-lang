module Kg.Cli exposing (Command(..), Options, parse, usage)

{-| The command line: `kg <command> [--worktree <path>] [options]`. -}

import Dict exposing (Dict)


type Command
    = Serve
    | Build
    | Update
    | Query String String
    | Summary
    | Check
    | Export
    | Embed
    | Eval String
    | Parse (List String)
    | Facts (List String)
    | Edges String
    | BenchVectors
    | BenchEmbed


type alias Options =
    { worktree : Maybe String
    , flags : Dict String String
    }


usage : String
usage =
    String.join "\n"
        [ "usage: kg <command> [--worktree <path>] [options]"
        , ""
        , "  serve                          the MCP server, on standard input and output"
        , "  build                          full replay and link, writing the snapshot"
        , "  update                         bring the snapshot up to date, with the overlay"
        , "  query <tool> <json args>       run one tool and print its text"
        , "  summary                        write out/compiler-map.md and print the instructions' length"
        , "  check [--determinism N] [--atlas-parity <history.json>]"
        , "  export --atlas <file> | --neo4j <dir>"
        , "  embed [--max-minutes M]        run the embedding in the foreground"
        , "  eval <questions.json> [--arms with,without] [--runs R] [--only id,id]"
        , "  parse <file.elm>...            parse Elm files with the compiler's parser"
        , "  facts [--root <dir>] <path>... print the facts of files, as JSON lines (for debugging)"
        , "  edges <kind> [--sample N]      print edges of one kind with their source lines (for precision checks)"
        , "  bench-vectors                  time the vector scans (for the phase 5 measurements)"
        , "  bench-embed [--model M] [--cpu] [--n N]  time embedding N chunks, uncached"
        ]


{-| Splits `--name value` options from the positional arguments. A flag with no
value (the next word starts with `--`, or there is none) gets the value "true".
-}
parse : List String -> Result String ( Command, Options )
parse args =
    let
        ( positional, flags ) =
            split args [] Dict.empty

        options =
            { worktree = Dict.get "worktree" flags, flags = Dict.remove "worktree" flags }
    in
    case positional of
        [ "serve" ] ->
            Ok ( Serve, options )

        [ "build" ] ->
            Ok ( Build, options )

        [ "update" ] ->
            Ok ( Update, options )

        [ "query", tool, json ] ->
            Ok ( Query tool json, options )

        [ "query", tool ] ->
            Ok ( Query tool "{}", options )

        [ "summary" ] ->
            Ok ( Summary, options )

        [ "check" ] ->
            Ok ( Check, options )

        [ "export" ] ->
            Ok ( Export, options )

        [ "embed" ] ->
            Ok ( Embed, options )

        [ "eval", questions ] ->
            Ok ( Eval questions, options )

        "parse" :: files ->
            Ok ( Parse files, options )

        "facts" :: files ->
            Ok ( Facts files, options )

        [ "bench-vectors" ] ->
            Ok ( BenchVectors, options )

        [ "bench-embed" ] ->
            Ok ( BenchEmbed, options )

        [ "edges", kind ] ->
            Ok ( Edges kind, options )

        _ ->
            Err usage


split : List String -> List String -> Dict String String -> ( List String, Dict String String )
split args positional flags =
    case args of
        a :: rest ->
            if String.startsWith "--" a then
                let
                    name =
                        String.dropLeft 2 a
                in
                case rest of
                    v :: more ->
                        if String.startsWith "--" v then
                            split rest positional (Dict.insert name "true" flags)

                        else
                            split more positional (Dict.insert name v flags)

                    [] ->
                        split rest positional (Dict.insert name "true" flags)

            else
                split rest (a :: positional) flags

        [] ->
            ( List.reverse positional, flags )
