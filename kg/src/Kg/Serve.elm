module Kg.Serve exposing (Model, Msg, spec)

{-| The eco-kg MCP server: the application `Mcp.Server` runs (§14, §15 of the
plan).

The worktree comes from `CLAUDE_PROJECT_DIR`, else `--worktree`, else the
working directory. The session opens in the background, so `initialize` is
answered at once; tool calls that arrive before it is open wait for it.

Every call runs the freshness check first (§12.2). Watching the source roots
and the git directory (§12.4) only makes that faster: an event starts a
500 ms timer, and when it fires the check runs in the background, so the next
query finds the graph current.

-}

import Array
import FileSystem
import Json.Encode as E
import Kg.Cli as Cli
import Kg.Assemble
import Kg.Context as Context exposing (Context)
import Kg.Link
import Kg.Fs as Fs
import Kg.Git as Git
import Kg.Graph as Graph
import Kg.Semantic as Semantic
import Kg.Session as Session exposing (Session)
import Kg.Tools as Tools
import Kg.Update as Update
import Mcp.Protocol as P
import Mcp.Server as Server
import Path
import Process
import Stream
import System
import Task exposing (Task)


type alias Model =
    { env : System.Environment
    , kgHome : String
    , state : State
    , waiting : Maybe Server.Call
    , running : Bool
    , watchGeneration : Int
    , refreshQueued : Bool
    , gitDir : Maybe String
    , roots : List String
    , semantic : Semantic.State
    , semanticKey : String
    , embedding : Bool
    , batches : Int
    }


type State
    = Resolving
    | Opening
    | Open Session
    | Inactive String


type Msg
    = Resolved (Result String ( Context, ( Kg.Link.PackageKernels, List Kg.Assemble.ConceptSpec ) ))
    | Opened (Result String ( Session, String, List String ))
    | Called (Result String ( Session, P.ToolResult ))
    | SemanticLoaded String (Result String Semantic.State)
    | Embedded String (Result String Semantic.State)
    | SemanticSaved (Result String Semantic.State)
    | Watched
    | DebounceFired Int
    | Refreshed (Result String Session)
    | Logged


spec : Cli.Options -> Server.Spec Model Msg
spec options =
    { init = init options
    , info = info
    , tools = \_ -> Tools.tools
    , call = call
    , update = update
    , subscriptions = subscriptions
    , ready = \m -> m.state /= Resolving
    }


log : Model -> String -> Cmd Msg
log model line =
    Task.perform (\_ -> Logged) (Stream.logLine ("eco-kg: " ++ line) model.env.stderr)


progress : System.Environment -> Update.Progress
progress env line =
    Stream.logLine ("eco-kg: " ++ line) env.stderr


init : Cli.Options -> System.Environment -> ( Model, Cmd Msg )
init options env =
    let
        home =
            kgHomeOf env

        model =
            { env = env, kgHome = home, state = Resolving, waiting = Nothing, running = False, watchGeneration = 0, refreshQueued = False, gitDir = Nothing, roots = [], semantic = Semantic.initial, semanticKey = "", embedding = False, batches = 0 }
    in
    ( model
    , Context.resolve options.worktree
        |> Task.andThen (\ctx -> Task.map2 Tuple.pair (Context.packageKernels ctx.elmHome) (Update.loadConcepts home) |> Task.map (Tuple.pair ctx))
        |> Task.attempt Resolved
    )


open : Model -> Context -> Kg.Link.PackageKernels -> List Kg.Assemble.ConceptSpec -> Cmd Msg
open model ctx packages concepts =
    Session.open ctx packages concepts (progress model.env)
        |> Task.andThen (\session -> Git.git ctx.worktree [ "rev-parse", "--path-format=absolute", "--git-dir" ] |> Task.map (\d -> ( session, String.trim d )))
        |> Task.andThen
            (\( session, d ) ->
                watchedRoots
                    |> List.map (\r -> Fs.isDirectory (ctx.worktree ++ "/" ++ r) |> Task.map (\ok -> if ok then [ ctx.worktree ++ "/" ++ r ] else []))
                    |> Task.sequence
                    |> Task.map (\rs -> ( session, d, List.concat rs ))
            )
        |> Task.attempt Opened


kgHomeOf : System.Environment -> String
kgHomeOf env =
    case List.reverse (String.split "/" (Path.toPosixString env.applicationPath)) of
        _ :: "bin" :: rest ->
            String.join "/" (List.reverse rest)

        _ :: rest ->
            String.join "/" (List.reverse rest)

        [] ->
            "."


info : Model -> P.ServerInfo
info model =
    { name = "eco-kg"
    , version = "0.1.0"
    , instructions =
        case model.state of
            Inactive why ->
                Tools.inactiveInstructions why

            Open session ->
                Tools.instructions session.snapshot.graph

            _ ->
                Tools.instructions Graph.empty
    }


call : Server.Call -> Model -> ( Model, Server.Outcome Msg )
call c model =
    case model.state of
        Inactive why ->
            ( model, Server.Done (P.errorResult (Tools.inactiveInstructions why)) )

        Open session ->
            ( { model | running = True }, Server.Pending (runCall model session c) )

        _ ->
            ( { model | waiting = Just c }, Server.Pending Cmd.none )


runCall : Model -> Session -> Server.Call -> Cmd Msg
runCall model session c =
    Session.refresh (progress model.env) session
        |> Task.andThen
            (\fresh ->
                let
                    v =
                        Session.view fresh
                in
                Semantic.ranksFor fresh.ctx model.semantic v c.name c.arguments
                    |> Task.map (\ranks -> ( fresh, Tools.call v ranks c.name c.arguments ))
            )
        |> Task.attempt Called


update : Msg -> Model -> ( Model, Cmd Msg, Maybe P.ToolResult )
update msg model =
    case msg of
        Resolved (Ok ( ctx, ( packages, concepts ) )) ->
            ( { model | state = Opening }, open model ctx packages concepts, Nothing )

        Resolved (Err why) ->
            ( { model | state = Inactive why }, log model ("inactive: " ++ why), Nothing )

        Opened (Ok ( session, gitDir, roots )) ->
            let
                m =
                    { model | state = Open session, gitDir = Just gitDir, roots = roots }

                ( m2, startSemantic ) =
                    semanticFor session m
            in
            case model.waiting of
                Just c ->
                    ( { m2 | waiting = Nothing, running = True }, Cmd.batch [ runCall m2 session c, log m2 ("open at " ++ String.left 10 session.snapshot.header.commit), startSemantic ], Nothing )

                Nothing ->
                    ( m2, Cmd.batch [ log m2 ("open at " ++ String.left 10 session.snapshot.header.commit), startSemantic ], Nothing )

        Opened (Err why) ->
            let
                m =
                    { model | state = Inactive why }
            in
            case model.waiting of
                Just _ ->
                    ( { m | waiting = Nothing }, log m ("inactive: " ++ why), Just (P.errorResult (Tools.inactiveInstructions why)) )

                Nothing ->
                    ( m, log m ("inactive: " ++ why), Nothing )

        Called (Ok ( session, result )) ->
            let
                ( m, cmd ) =
                    semanticFor session { model | state = Open session, running = False }
            in
            ( m, cmd, Just result )

        SemanticLoaded key (Ok sem) ->
            if key /= model.semanticKey then
                ( model, Cmd.none, Nothing )

            else
                let
                    ( m, next ) =
                        startEmbedding { model | semantic = sem }
                in
                ( m, Cmd.batch [ log m ("vectors: " ++ Semantic.describe sem ++ (if sem.up then "" else "; no embedding server")), next ], Nothing )

        SemanticLoaded _ (Err why) ->
            ( model, log model ("vectors: " ++ why), Nothing )

        Embedded key (Ok sem) ->
            if key /= model.semanticKey then
                ( { model | embedding = False }, Cmd.none, Nothing )

            else
                let
                    m =
                        { model | semantic = sem, embedding = False, batches = model.batches + 1 }
                in
                if Semantic.pendingCount sem == 0 || modBy 20 m.batches == 0 || not sem.up then
                    ( { m | embedding = True }
                    , Cmd.batch
                        [ withOpen m (\session -> Task.attempt SemanticSaved (Semantic.save session.ctx sem))
                        , log m ("vectors: " ++ Semantic.describe sem ++ (sem.lastError |> Maybe.map (\e -> "; " ++ e) |> Maybe.withDefault ""))
                        ]
                    , Nothing
                    )

                else
                    let
                        ( m2, next ) =
                            startEmbedding m
                    in
                    ( m2, next, Nothing )

        Embedded _ (Err why) ->
            ( { model | embedding = False }, log model ("vectors: " ++ why), Nothing )

        SemanticSaved (Ok sem) ->
            let
                ( m, next ) =
                    startEmbedding { model | semantic = sem, embedding = False }
            in
            ( m, next, Nothing )

        SemanticSaved (Err why) ->
            ( { model | embedding = False }, log model ("vectors: " ++ why), Nothing )

        Called (Err why) ->
            ( { model | running = False }, log model why, Just (P.errorResult ("eco-kg failed: " ++ why)) )

        Watched ->
            let
                gen =
                    model.watchGeneration + 1
            in
            ( { model | watchGeneration = gen }, Task.perform (\_ -> DebounceFired gen) (Process.sleep 500), Nothing )

        DebounceFired gen ->
            if gen /= model.watchGeneration then
                ( model, Cmd.none, Nothing )

            else
                case ( model.state, model.running ) of
                    ( Open session, False ) ->
                        ( { model | running = True }, Task.attempt Refreshed (Session.refresh (progress model.env) session), Nothing )

                    _ ->
                        ( model, Cmd.none, Nothing )

        Refreshed (Ok session) ->
            let
                ( m, cmd ) =
                    semanticFor session { model | state = Open session, running = False }
            in
            ( m, cmd, Nothing )

        Refreshed (Err why) ->
            ( { model | running = False }, log model why, Nothing )

        Logged ->
            ( model, Cmd.none, Nothing )


{-| The source roots, never the worktree root, which would recurse into
`worktrees/`, `build/` and `.git`; and the git directory, for HEAD and the
index, not recursively.
-}
watchedRoots : List String
watchedRoots =
    [ "compiler/src", "compiler/src-xhr", "compiler/src-version", "runtime/src", "runtime/include", "elm-kernel-cpp/src", "eco-kernel-cpp/src", "system-kernel-cpp/src", "plans", "design_docs" ]


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.state of
        Open _ ->
            Sub.batch
                (List.map (\r -> FileSystem.watchRecursive (\_ -> Watched) (Path.fromPosixString r)) model.roots
                    ++ (case model.gitDir of
                            Just d ->
                                [ FileSystem.watch (\_ -> Watched) (Path.fromPosixString d) ]

                            Nothing ->
                                []
                       )
                )

        _ ->
            Sub.none


{-| The view's identity: when it changes, the vectors are matched to its
chunks again.
-}
viewKey : Session -> String
viewKey session =
    session.snapshot.header.commit ++ (session.overlay |> Maybe.map .fingerprint |> Maybe.withDefault "")


semanticFor : Session -> Model -> ( Model, Cmd Msg )
semanticFor session model =
    let
        key =
            viewKey session
    in
    if key == model.semanticKey then
        ( model, Cmd.none )

    else
        ( { model | semanticKey = key }
        , Task.attempt (SemanticLoaded key) (Semantic.load session.ctx (Array.toList (Session.view session).chunks))
        )


startEmbedding : Model -> ( Model, Cmd Msg )
startEmbedding model =
    if model.embedding || not model.semantic.up || Semantic.pendingCount model.semantic == 0 then
        ( model, Cmd.none )

    else
        ( { model | embedding = True }
        , withOpen model (\session -> Task.attempt (Embedded model.semanticKey) (Semantic.embedBatch session.ctx model.semantic))
        )


withOpen : Model -> (Session -> Cmd Msg) -> Cmd Msg
withOpen model f =
    case model.state of
        Open session ->
            f session

        _ ->
            Cmd.none
