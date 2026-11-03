module Mcp.Server exposing (Spec, Call, Outcome(..), Model, Msg, init, update, subscriptions)

{-| An MCP server over standard input and output, as an eco program.

The server reads one line at a time and issues the next read as soon as a
line arrives, so pings and notifications are answered while a tool runs. Tool
calls run one at a time, in the order they came: the application starts one
with `call`, and finishes it either at once (`Done`) or later, from its
`update`.

Only MCP messages go to standard output. Standard input closing ends the
program with exit code 0.

-}

import Json.Encode as E
import Mcp.Protocol as P
import Stream
import System
import Task


type alias Call =
    { name : String, arguments : E.Value }


type Outcome msg
    = Done P.ToolResult
    | Pending (Cmd msg)


type alias Spec model msg =
    { init : System.Environment -> ( model, Cmd msg )
    , info : model -> P.ServerInfo
    , tools : model -> List P.Tool
    , call : Call -> model -> ( model, Outcome msg )
    , update : msg -> model -> ( model, Cmd msg, Maybe P.ToolResult )
    , subscriptions : model -> Sub msg
    , ready : model -> Bool
    }


type Msg msg
    = GotLine (Result Stream.Error String)
    | App msg
    | Written


type alias Model model =
    { env : System.Environment
    , app : model
    , queue : List { id : E.Value, call : Call }
    , running : Maybe E.Value
    , reading : Bool
    }


init : Spec model msg -> System.Environment -> ( Model model, Cmd (Msg msg) )
init spec env =
    let
        ( app, cmd ) =
            spec.init env
    in
    if spec.ready app then
        ( { env = env, app = app, queue = [], running = Nothing, reading = True }
        , Cmd.batch [ readNext env, Cmd.map App cmd ]
        )

    else
        -- standard input is not read until the application is ready, so the
        -- first message (`initialize`) sees it ready
        ( { env = env, app = app, queue = [], running = Nothing, reading = False }
        , Cmd.map App cmd
        )


subscriptions : Spec model msg -> Model model -> Sub (Msg msg)
subscriptions spec model =
    Sub.map App (spec.subscriptions model.app)


readNext : System.Environment -> Cmd (Msg msg)
readNext env =
    Task.attempt GotLine (Stream.readLine env.stdin)


send : System.Environment -> String -> Cmd (Msg msg)
send env line =
    Task.attempt (\_ -> Written) (Stream.writeLine line env.stdout)


update : Spec model msg -> Msg msg -> Model model -> ( Model model, Cmd (Msg msg) )
update spec msg model =
    case msg of
        GotLine (Err _) ->
            ( model, System.exit )

        GotLine (Ok line) ->
            if String.trim line == "" then
                ( model, readNext model.env )

            else
                case P.handle (spec.info model.app) (spec.tools model.app) (P.decode line) of
                    P.Reply text ->
                        ( model, Cmd.batch [ send model.env text, readNext model.env ] )

                    P.NoReply ->
                        ( model, readNext model.env )

                    P.CallTool c ->
                        let
                            ( next, cmd ) =
                                startNext spec { model | queue = model.queue ++ [ { id = c.id, call = { name = c.name, arguments = c.arguments } } ] }
                        in
                        ( next, Cmd.batch [ cmd, readNext model.env ] )

        App appMsg ->
            let
                ( app, cmd0, finished ) =
                    spec.update appMsg model.app

                startReading =
                    not model.reading && spec.ready app

                cmd =
                    cmd0

                m =
                    { model | app = app, reading = model.reading || startReading }

                readCmd =
                    if startReading then
                        readNext model.env

                    else
                        Cmd.none
            in
            case ( finished, m.running ) of
                ( Just r, Just id ) ->
                    let
                        ( next, more ) =
                            startNext spec { m | running = Nothing }
                    in
                    ( next, Cmd.batch [ Cmd.map App cmd, send m.env (P.toolResult id r), more, readCmd ] )

                _ ->
                    ( m, Cmd.batch [ Cmd.map App cmd, readCmd ] )

        Written ->
            ( model, Cmd.none )


{-| Starts queued calls until one is pending or the queue is empty. -}
startNext : Spec model msg -> Model model -> ( Model model, Cmd (Msg msg) )
startNext spec model =
    case ( model.running, model.queue ) of
        ( Nothing, next :: rest ) ->
            let
                ( app, outcome ) =
                    spec.call next.call model.app
            in
            case outcome of
                Done r ->
                    let
                        ( m, cmd ) =
                            startNext spec { model | app = app, queue = rest }
                    in
                    ( m, Cmd.batch [ send model.env (P.toolResult next.id r), cmd ] )

                Pending cmd ->
                    ( { model | app = app, queue = rest, running = Just next.id }, Cmd.map App cmd )

        _ ->
            ( model, Cmd.none )
