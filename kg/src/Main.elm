module Main exposing (main)

{-| kg: the eco compiler knowledge graph. See plans/compiler-knowledge-graph.md. -}

import Kg.Cli as Cli
import Kg.Commands as Commands
import Kg.Serve as Serve
import Mcp.Server as Server
import Stream
import System
import Task


type Model
    = Serving Cli.Options (Server.Model Serve.Model)
    | Running


type Msg
    = ServerMsg (Server.Msg Serve.Msg)
    | Finished Int


main : Platform.Program System.Environment Model Msg
main =
    System.program
        { init = init
        , update = update
        , subscriptions =
            \model ->
                case model of
                    Serving options m ->
                        Sub.map ServerMsg (Server.subscriptions (Serve.spec options) m)

                    Running ->
                        Sub.none
        }


init : System.Environment -> ( Model, Cmd Msg )
init env =
    case Cli.parse (List.drop 1 env.args) of
        Ok ( Cli.Serve, options ) ->
            Server.init (Serve.spec options) env |> Tuple.mapBoth (Serving options) (Cmd.map ServerMsg)

        Ok ( command, options ) ->
            ( Running
            , Commands.run env command options
                |> Task.onError
                    (\e ->
                        Stream.logLine e env.stderr |> Task.map (\_ -> 1)
                    )
                |> Task.perform Finished
            )

        Err text ->
            ( Running, Stream.logLine text env.stderr |> Task.perform (\_ -> Finished 2) )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( ServerMsg m, Serving options s ) ->
            Server.update (Serve.spec options) m s |> Tuple.mapBoth (Serving options) (Cmd.map ServerMsg)

        ( Finished code, _ ) ->
            ( model, System.exitWithCode code )

        _ ->
            ( model, Cmd.none )
