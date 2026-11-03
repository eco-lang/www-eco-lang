module Kg.Eval exposing (run, Options)

{-| The evaluation harness (§18 of the plan).

Each question runs once per arm and run, as

    claude -p <question> --output-format stream-json --verbose
      --strict-mcp-config --mcp-config <arm>.json
      --permission-mode dontAsk --allowedTools "Read,Grep,Glob,Bash(git log:*),mcp__eco-kg__*"
      --max-turns 40

in a clean clone of eco-compiler at a fixed commit. The `with` arm has eco-kg
as its only MCP server; the `without` arm has none. A run whose `system/init`
event does not show that is discarded.

From the stream: the tool calls by name, and from the final `result` event
the turns, duration, cost, tokens and the answer. `mustMention` hits are
counted here; correctness is graded 0–2 by a separate `claude -p` prompt,
whose grades are spot-checked by hand.

-}

import ChildProcess
import Dict exposing (Dict)
import Json.Decode as D
import Json.Encode as E
import Kg.Fs as Fs
import Task exposing (Task)
import Time


type alias Question =
    { id : String, question : String, reference : String, mustMention : List String, category : String }


type alias Outcome =
    { question : String
    , arm : String
    , run : Int
    , valid : Bool
    , toolCalls : Int
    , kgCalls : Int
    , tools : Dict String Int
    , turns : Int
    , durationMs : Int
    , costUsd : Float
    , inputTokens : Int
    , outputTokens : Int
    , cacheReadTokens : Int
    , answer : String
    , mentionHits : Int
    , mentionTotal : Int
    , grade : Maybe Int
    , gradeWhy : String
    }


questionDecoder : D.Decoder Question
questionDecoder =
    D.map5 Question
        (D.field "id" D.string)
        (D.field "question" D.string)
        (D.field "reference" D.string)
        (D.field "mustMention" (D.list D.string))
        (D.field "category" D.string)


type alias Options =
    { questions : String
    , arms : List String
    , runs : Int
    , only : List String
    , phase : String
    , kg : String
    , workdir : String
    , commit : String
    , source : String
    , model : Maybe String
    , graderModel : String
    , out : String
    , progress : String -> Task String ()
    }


run : Options -> Task String String
run o =
    Fs.readText o.questions
        |> Task.andThen
            (\text ->
                case D.decodeString (D.list questionDecoder) text of
                    Err _ ->
                        Task.fail (o.questions ++ " is not a list of questions")

                    Ok qs ->
                        let
                            chosen =
                                if List.isEmpty o.only then
                                    qs

                                else
                                    List.filter (\q -> List.member q.id o.only) qs

                            jobs =
                                chosen |> List.concatMap (\q -> o.arms |> List.concatMap (\arm -> List.range 1 o.runs |> List.map (\r -> ( q, arm, r ))))
                        in
                        prepare o
                            |> Task.andThen
                                (\_ ->
                                    List.foldl
                                        (\( q, arm, r ) acc ->
                                            acc
                                                |> Task.andThen
                                                    (\done ->
                                                        runOne o q arm r
                                                            |> Task.andThen
                                                                (\out ->
                                                                    -- written after every run, so an interrupted run keeps its results
                                                                    write o chosen (done ++ [ out ]) |> Task.map (\_ -> done ++ [ out ])
                                                                )
                                                    )
                                        )
                                        (Task.succeed [])
                                        jobs
                                )
                            |> Task.andThen (\outcomes -> write o chosen outcomes)
            )


sequence : List (Task x a) -> Task x (List a)
sequence tasks =
    List.foldl (\t acc -> acc |> Task.andThen (\xs -> t |> Task.map (\x -> xs ++ [ x ]))) (Task.succeed []) tasks


options : Int -> ChildProcess.RunOptions
options minutes =
    { shell = ChildProcess.NoShell
    , workingDirectory = ChildProcess.InheritWorkingDirectory
    , environmentVariables = ChildProcess.InheritEnvironmentVariables
    , maximumBytesWrittenToStreams = 512 * 1024 * 1024
    , runDuration = ChildProcess.Milliseconds (minutes * 60 * 1000)
    }


inDir : String -> Int -> ChildProcess.RunOptions
inDir dir minutes =
    let
        base =
            options minutes
    in
    { base | workingDirectory = ChildProcess.SetWorkingDirectory dir }


{-| A clean clone of the source at the commit, sharing its objects; and the
two MCP configurations.
-}
prepare : Options -> Task String ()
prepare o =
    Fs.exists (o.workdir ++ "/.git")
        |> Task.andThen
            (\have ->
                if have then
                    Task.succeed ()

                else
                    o.progress ("cloning " ++ o.source ++ " into " ++ o.workdir)
                        |> Task.andThen (\_ -> ChildProcess.run "git" [ "clone", "--quiet", "--shared", "--no-checkout", o.source, o.workdir ] (options 10) |> Task.mapError (\_ -> "git clone failed"))
                        |> Task.map (\_ -> ())
            )
        |> Task.andThen (\_ -> ChildProcess.run "git" [ "-C", o.workdir, "checkout", "--quiet", "--force", "--detach", o.commit ] (options 10) |> Task.mapError (\_ -> "git checkout " ++ o.commit ++ " failed"))
        |> Task.andThen (\_ -> ChildProcess.run "git" [ "-C", o.workdir, "clean", "-fdxq" ] (options 10) |> Task.mapError (\_ -> "git clean failed"))
        |> Task.andThen (\_ -> Fs.writeTextAtomic (o.workdir ++ "/../with.json") (E.encode 2 (E.object [ ( "mcpServers", E.object [ ( "eco-kg", E.object [ ( "command", E.string o.kg ), ( "args", E.list E.string [ "serve" ] ) ] ) ] ) ])))
        |> Task.andThen (\_ -> Fs.writeTextAtomic (o.workdir ++ "/../without.json") (E.encode 2 (E.object [ ( "mcpServers", E.object [] ) ])))
        |> Task.andThen
            (\_ ->
                if List.member "with" o.arms then
                    o.progress "building the snapshot for the clone"
                        |> Task.andThen (\_ -> ChildProcess.run o.kg [ "update", "--worktree", o.workdir ] (options 30) |> Task.mapError (\_ -> "kg update on the clone failed"))
                        |> Task.andThen (\_ -> o.progress "gathering the clone's vectors from the shared cache")
                        |> Task.andThen (\_ -> ChildProcess.run o.kg [ "embed", "--worktree", o.workdir, "--max-minutes", "0" ] (options 30) |> Task.mapError (\_ -> "kg embed on the clone failed"))
                        |> Task.map (\_ -> ())

                else
                    Task.succeed ()
            )


runOne : Options -> Question -> String -> Int -> Task String Outcome
runOne o q arm r =
    let
        args =
            [ "-p", q.question
            , "--output-format", "stream-json", "--verbose"
            , "--strict-mcp-config", "--mcp-config", o.workdir ++ "/../" ++ arm ++ ".json"
            , "--permission-mode", "dontAsk"
            , "--allowedTools", "Read,Grep,Glob,Bash(git log:*),mcp__eco-kg__*"
            , "--max-turns", "40"
            ]
                ++ (case o.model of
                        Just m ->
                            [ "--model", m ]

                        Nothing ->
                            []
                   )
    in
    o.progress (q.id ++ " / " ++ arm ++ " / run " ++ String.fromInt r)
        |> Task.andThen
            (\_ ->
                ChildProcess.run "claude" args (inDir o.workdir 30)
                    |> Task.map (\res -> Fs.bytesToString res.stdout |> Maybe.withDefault "")
                    |> Task.onError
                        (\f ->
                            case f of
                                ChildProcess.ProgramError e ->
                                    Task.succeed (Fs.bytesToString e.stdout |> Maybe.withDefault "")

                                ChildProcess.InitError _ ->
                                    Task.fail "could not start claude"
                        )
            )
        |> Task.map (parseStream q arm r)
        |> Task.andThen (grade o q)
        |> Task.andThen
            (\out ->
                o.progress
                    ("  " ++ (if out.valid then "valid" else "DISCARDED")
                        ++ ", " ++ String.fromInt out.toolCalls ++ " tool calls (" ++ String.fromInt out.kgCalls ++ " eco-kg), "
                        ++ String.fromInt out.turns ++ " turns, $" ++ String.fromFloat (toFloat (round (out.costUsd * 100)) / 100)
                        ++ ", mentions " ++ String.fromInt out.mentionHits ++ "/" ++ String.fromInt out.mentionTotal
                        ++ ", grade " ++ (Maybe.map String.fromInt out.grade |> Maybe.withDefault "?")
                    )
                    |> Task.map (\_ -> out)
            )


type Event
    = Init (List ( String, String ))
    | ToolUse String
    | Result { turns : Int, durationMs : Int, cost : Float, input : Int, output : Int, cacheRead : Int, answer : String }
    | Other


eventDecoder : D.Decoder Event
eventDecoder =
    D.field "type" D.string
        |> D.andThen
            (\t ->
                case t of
                    "system" ->
                        D.oneOf
                            [ D.field "mcp_servers" (D.list (D.map2 Tuple.pair (D.field "name" D.string) (D.field "status" D.string))) |> D.map Init
                            , D.succeed Other
                            ]

                    "result" ->
                        D.map7 (\turns ms cost input output cacheRead answer -> Result { turns = turns, durationMs = ms, cost = cost, input = input, output = output, cacheRead = cacheRead, answer = answer })
                            (D.oneOf [ D.field "num_turns" D.int, D.succeed 0 ])
                            (D.oneOf [ D.field "duration_ms" D.int, D.succeed 0 ])
                            (D.oneOf [ D.field "total_cost_usd" D.float, D.succeed 0 ])
                            (D.oneOf [ D.at [ "usage", "input_tokens" ] D.int, D.succeed 0 ])
                            (D.oneOf [ D.at [ "usage", "output_tokens" ] D.int, D.succeed 0 ])
                            (D.oneOf [ D.at [ "usage", "cache_read_input_tokens" ] D.int, D.succeed 0 ])
                            (D.oneOf [ D.field "result" D.string, D.succeed "" ])

                    _ ->
                        D.succeed Other
            )


toolUses : D.Decoder (List String)
toolUses =
    D.oneOf
        [ D.at [ "message", "content" ]
            (D.list
                (D.oneOf
                    [ D.map2 Tuple.pair (D.field "type" D.string) (D.field "name" D.string)
                    , D.succeed ( "", "" )
                    ]
                )
            )
            |> D.map (List.filter (\( t, _ ) -> t == "tool_use") >> List.map Tuple.second)
        , D.succeed []
        ]


parseStream : Question -> String -> Int -> String -> Outcome
parseStream q arm r stream =
    let
        lines =
            String.lines stream |> List.filter (\l -> String.startsWith "{" l)

        events =
            List.filterMap (\l -> D.decodeString eventDecoder l |> Result.toMaybe) lines

        uses =
            lines
                |> List.filter (\l -> String.contains "\"type\":\"assistant\"" l)
                |> List.concatMap (\l -> D.decodeString toolUses l |> Result.withDefault [])

        servers =
            events |> List.filterMap (\e -> case e of
                Init s -> Just s
                _ -> Nothing) |> List.head |> Maybe.withDefault []

        valid =
            if arm == "with" then
                List.member ( "eco-kg", "connected" ) servers

            else
                List.isEmpty servers

        res =
            events |> List.filterMap (\e -> case e of
                Result x -> Just x
                _ -> Nothing) |> List.reverse |> List.head

        answer =
            res |> Maybe.map .answer |> Maybe.withDefault ""

        lower =
            String.toLower answer
    in
    { question = q.id
    , arm = arm
    , run = r
    , valid = valid && res /= Nothing
    , toolCalls = List.length uses
    , kgCalls = List.length (List.filter (String.startsWith "mcp__eco-kg__") uses)
    , tools = List.foldl (\u d -> Dict.update u (\v -> Just (Maybe.withDefault 0 v + 1)) d) Dict.empty uses
    , turns = res |> Maybe.map .turns |> Maybe.withDefault 0
    , durationMs = res |> Maybe.map .durationMs |> Maybe.withDefault 0
    , costUsd = res |> Maybe.map .cost |> Maybe.withDefault 0
    , inputTokens = res |> Maybe.map .input |> Maybe.withDefault 0
    , outputTokens = res |> Maybe.map .output |> Maybe.withDefault 0
    , cacheReadTokens = res |> Maybe.map .cacheRead |> Maybe.withDefault 0
    , answer = answer
    , mentionHits = List.length (List.filter (\m -> String.contains (String.toLower (lastSegment m)) lower) q.mustMention)
    , mentionTotal = List.length q.mustMention
    , grade = Nothing
    , gradeWhy = ""
    }


{-| A mention counts when the answer names the last segment of a module name,
or the file name of a path: `Compiler.Monomorphize.EntryPrep` is hit by
`EntryPrep`.
-}
lastSegment : String -> String
lastSegment m =
    if String.contains "/" m then
        String.split "/" m |> List.reverse |> List.head |> Maybe.withDefault m

    else if String.endsWith ".elm" m || String.endsWith ".cpp" m || String.endsWith ".md" m then
        m

    else
        String.split "." m |> List.reverse |> List.head |> Maybe.withDefault m


grade : Options -> Question -> Outcome -> Task String Outcome
grade o q out =
    if not out.valid || out.answer == "" then
        Task.succeed out

    else
        let
            prompt =
                String.join "\n"
                    [ "Grade an answer to a question about the eco compiler against a reference answer."
                    , "Reply with one line: the grade (0, 1 or 2), a space, then one short sentence of reason."
                    , "2 = correct and covers the reference's key points; 1 = partly correct or missing key points; 0 = wrong or no real answer."
                    , ""
                    , "QUESTION: " ++ q.question
                    , ""
                    , "REFERENCE: " ++ q.reference
                    , ""
                    , "ANSWER: " ++ String.left 12000 out.answer
                    ]
        in
        ChildProcess.run "claude" [ "-p", prompt, "--model", o.graderModel, "--strict-mcp-config", "--mcp-config", o.workdir ++ "/../without.json", "--max-turns", "1" ] (inDir o.workdir 10)
            |> Task.map (\res -> Fs.bytesToString res.stdout |> Maybe.withDefault "" |> String.trim)
            |> Task.onError (\_ -> Task.succeed "")
            |> Task.map
                (\reply ->
                    { out
                        | grade = String.left 1 reply |> String.toInt
                        , gradeWhy = String.dropLeft 2 reply |> String.left 300
                    }
                )


write : Options -> List Question -> List Outcome -> Task String String
write o qs outcomes =
    Time.now
        |> Task.andThen
            (\now ->
                let
                    encodeOutcome x =
                        E.object
                            [ ( "question", E.string x.question )
                            , ( "category", E.string (qs |> List.filter (\q -> q.id == x.question) |> List.head |> Maybe.map .category |> Maybe.withDefault "") )
                            , ( "arm", E.string x.arm )
                            , ( "run", E.int x.run )
                            , ( "valid", E.bool x.valid )
                            , ( "toolCalls", E.int x.toolCalls )
                            , ( "kgCalls", E.int x.kgCalls )
                            , ( "tools", E.dict identity E.int x.tools )
                            , ( "turns", E.int x.turns )
                            , ( "durationMs", E.int x.durationMs )
                            , ( "costUsd", E.float x.costUsd )
                            , ( "inputTokens", E.int x.inputTokens )
                            , ( "outputTokens", E.int x.outputTokens )
                            , ( "cacheReadTokens", E.int x.cacheReadTokens )
                            , ( "mentionHits", E.int x.mentionHits )
                            , ( "mentionTotal", E.int x.mentionTotal )
                            , ( "grade", Maybe.map E.int x.grade |> Maybe.withDefault E.null )
                            , ( "gradeWhy", E.string x.gradeWhy )
                            , ( "answer", E.string x.answer )
                            ]

                    doc =
                        E.object
                            [ ( "phase", E.string o.phase )
                            , ( "commit", E.string o.commit )
                            , ( "model", E.string (Maybe.withDefault "default" o.model) )
                            , ( "grader", E.string o.graderModel )
                            , ( "at", E.int (Time.posixToMillis now) )
                            , ( "outcomes", E.list encodeOutcome outcomes )
                            ]

                    path =
                        o.out
                in
                Fs.writeTextAtomic path (E.encode 2 doc) |> Task.map (\_ -> path)
            )
