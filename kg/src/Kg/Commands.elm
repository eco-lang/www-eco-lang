module Kg.Commands exposing (run)

{-| The command-line commands other than `serve`. Each is a task that ends with
an exit code, or fails with a message for standard error.
-}

import Array
import Bytes
import Bytes.Decode
import Compiler.AST.Source as Src
import Compiler.Elm.Compiler.Imports as Imports
import Compiler.Parse.Module as M
import Compiler.Reporting.Annotation as A
import FileSystem
import Dict
import Json.Encode as E
import Kg.Cli as Cli
import Kg.Extract as Extract
import Kg.Fs as Fs
import Kg.Stages as Stages
import Kg.Assemble as Assemble
import Kg.Link as Link
import Set
import Kg.Debug
import Kg.Atlas as Atlas
import Kg.Build as Build
import Kg.Context as Context
import Kg.Json as Json
import Kg.Update as Update
import Kg.Session as Session
import Kg.Eval as Eval
import Kg.Check as Check
import Kg.Neo4j as Neo4j
import Kg.Semantic as Semantic
import Kg.Embed as Embed
import Kg.Search.Vectors as Vectors
import Kg.Git as Git
import Kg.Tools as Tools
import Json.Decode as D
import Kg.Snapshot as Snapshot
import Kg.Graph as Graph
import Path
import Time
import Path
import Stream
import System
import Task exposing (Task)


run : System.Environment -> Cli.Command -> Cli.Options -> Task String Int
run env command options =
    case command of
        Cli.Parse files ->
            parseAll env files

        Cli.Facts files ->
            printFacts env (Dict.get "root" options.flags |> Maybe.withDefault ".") files

        Cli.Query tool json ->
            queryCommand env options tool json

        Cli.Summary ->
            summaryCommand env options

        Cli.Eval questions ->
            evalCommand env options questions

        Cli.BenchVectors ->
            openSession env options
                |> Task.andThen (\session -> Semantic.load session.ctx (Array.toList (Session.view session).chunks))
                |> Task.andThen
                    (\sem ->
                        let
                            q =
                                List.range 0 383 |> List.map (\j -> cos (toFloat j)) |> Vectors.normalise

                            store =
                                sem.block.store
                        in
                        timed (Task.succeed () |> Task.map (\_ -> Vectors.search store (\_ -> True) 80 q |> List.length))
                            |> Task.andThen (\( _, a ) -> timed (Task.succeed () |> Task.map (\_ -> Vectors.scanOnly store q)) |> Task.map (\( _, b ) -> ( a, b )))
                            |> Task.andThen (\( a, b ) -> timed (Task.succeed () |> Task.map (\_ -> Semantic.rankWith sem sem.view q |> List.length)) |> Task.map (\( _, c ) -> ( a, b, c )))
                            |> Task.andThen (\( a, b, c ) -> timed (Task.succeed () |> Task.map (\_ -> Vectors.scanPresent store q)) |> Task.map (\( _, d ) -> ( ( a, b ), ( c, d ) )))
                            |> Task.andThen (\( ab, ( c, d ) ) -> timed (Task.succeed () |> Task.map (\_ -> Vectors.scanTop store q)) |> Task.map (\( _, e ) -> ( ab, ( c, d, e ) )))
                            |> Task.andThen (\( ( a, b ), ( c, d, e ) ) -> Stream.logLine ("search " ++ String.fromInt a ++ " ms, bare scan " ++ String.fromInt b ++ " ms, rankWith " ++ String.fromInt c ++ " ms, with present " ++ String.fromInt d ++ " ms, with top-k " ++ String.fromInt e ++ " ms, rows " ++ String.fromInt (List.length store.rows)) env.stdout)
                    )
                |> Task.map (\_ -> 0)

        Cli.BenchEmbed ->
            openSession env options
                |> Task.andThen
                    (\session ->
                        let
                            ctx =
                                session.ctx

                            m =
                                Embed.model (Dict.get "model" options.flags |> Maybe.withDefault ctx.model) (Dict.get "dimensions" options.flags |> Maybe.andThen String.toInt)

                            n =
                                Dict.get "n" options.flags |> Maybe.andThen String.toInt |> Maybe.withDefault 256

                            texts =
                                (Session.view session).chunks |> Array.toList |> List.filter .embed |> List.map .text |> List.take n

                            opts =
                                if Dict.member "cpu" options.flags then
                                    [ ( "num_gpu", E.int 0 ) ]

                                else
                                    []

                            batches xs =
                                if List.isEmpty xs then
                                    []

                                else
                                    List.take 32 xs :: batches (List.drop 32 xs)
                        in
                        -- one small warm-up request loads the model
                        Embed.embedWith ctx m opts [ "warm up" ]
                            |> Task.andThen
                                (\_ ->
                                    timed
                                        (List.foldl
                                            (\b acc -> acc |> Task.andThen (\( t, ns ) -> Embed.embedWith ctx m opts b |> Task.map (\( _, st ) -> ( t + st.promptTokens, ns + st.durationNs ))))
                                            (Task.succeed ( 0, 0 ))
                                            (batches texts)
                                        )
                                )
                            |> Task.andThen
                                (\( ( tokens, _ ), ms ) ->
                                    Stream.logLine
                                        (m.name ++ (if List.isEmpty opts then " (default device)" else " (CPU)") ++ ": " ++ String.fromInt (List.length texts) ++ " chunks, " ++ String.fromInt tokens ++ " tokens in " ++ String.fromInt ms ++ " ms: "
                                            ++ String.fromInt (tokens * 1000 // max 1 ms) ++ " tokens/s, " ++ String.fromInt (List.length texts * 1000 // max 1 ms) ++ " chunks/s"
                                        )
                                        env.stdout
                                )
                    )
                |> Task.map (\_ -> 0)

        Cli.Edges kind ->
            edgesCommand env options kind

        Cli.Embed ->
            embedCommand env options

        Cli.Build ->
            buildCommand env options True

        Cli.Update ->
            buildCommand env options False

        Cli.Export ->
            case ( Dict.get "atlas" options.flags, Dict.get "neo4j" options.flags ) of
                ( Just file, _ ) ->
                    exportAtlas env options file

                ( Nothing, Just dir ) ->
                    openSession env options
                        |> Task.andThen
                            (\session ->
                                let
                                    g =
                                        (Session.view session).graph
                                in
                                Fs.writeTextAtomic (dir ++ "/nodes.csv") (Neo4j.nodesCsv g)
                                    |> Task.andThen (\_ -> Fs.writeTextAtomic (dir ++ "/edges.csv") (Neo4j.edgesCsv g))
                                    |> Task.andThen (\_ -> Stream.logLine ("wrote " ++ dir ++ "/nodes.csv and edges.csv: " ++ String.fromInt (Dict.size g.nodes) ++ " nodes, " ++ String.fromInt (Graph.edgeCount g) ++ " edges") env.stdout)
                                    |> Task.map (\_ -> 0)
                            )

                _ ->
                    Task.fail "export needs --atlas <file> or --neo4j <dir>"

        Cli.Check ->
            case ( Dict.get "atlas-parity" options.flags, Dict.get "determinism" options.flags ) of
                ( Just file, _ ) ->
                    atlasParity env options file

                ( Nothing, Just n ) ->
                    determinismCommand env options (String.toInt n |> Maybe.withDefault 50)

                ( Nothing, Nothing ) ->
                    referencesCommand env options

        _ ->
            Task.fail "not implemented yet"


parseAll : System.Environment -> List String -> Task String Int
parseAll env files =
    List.foldl
        (\file acc ->
            acc
                |> Task.andThen
                    (\( ok, bad ) ->
                        FileSystem.readFile (Path.fromPosixString file)
                            |> Task.map (\b -> Bytes.Decode.decode (Bytes.Decode.string (Bytes.width b)) b |> Maybe.withDefault "")
                            |> Task.map parseOne
                            |> Task.onError (\e -> Task.succeed (Err (FileSystem.errorToString e)))
                            |> Task.andThen
                                (\r ->
                                    case r of
                                        Ok line ->
                                            (if List.length files == 1 then
                                                Stream.logLine line env.stdout

                                             else
                                                Task.succeed ()
                                            )
                                                |> Task.map (\_ -> ( ok + 1, bad ))

                                        Err why ->
                                            Stream.logLine ("FAIL " ++ file ++ ": " ++ why) env.stdout
                                                |> Task.map (\_ -> ( ok, bad + 1 ))
                                )
                    )
        )
        (Task.succeed ( 0, 0 ))
        files
        |> Task.andThen
            (\( ok, bad ) ->
                Stream.logLine ("parsed " ++ String.fromInt ok ++ ", failed " ++ String.fromInt bad) env.stdout
                    |> Task.map
                        (\_ ->
                            if bad > 0 then
                                1

                            else
                                0
                        )
            )


parseOne : String -> Result String String
parseOne text =
    case M.fromByteString M.Application text of
        Ok (Src.Module data) ->
            let
                docs =
                    case data.docs of
                        Src.YesDocs _ ds ->
                            1 + List.length ds

                        Src.NoDocs _ ds ->
                            List.length ds

                name =
                    case data.name of
                        Just (A.At _ n) ->
                            n

                        Nothing ->
                            "Main"
            in
            Ok (name ++ " imports=" ++ String.fromInt (List.length data.imports - List.length Imports.defaults) ++ " docs=" ++ String.fromInt docs)

        Err _ ->
            Err "parse error"


printFacts : System.Environment -> String -> List String -> Task String Int
printFacts env root files =
    List.foldl
        (\file acc ->
            acc
                |> Task.andThen
                    (\_ ->
                        Fs.readText (root ++ "/" ++ file)
                            |> Task.andThen (\text -> Stream.logLine (E.encode 0 (Kg.Debug.factsJson file (Extract.extract file text))) env.stdout)
                    )
        )
        (Task.succeed ())
        files
        |> Task.map (\_ -> 0)


progress : System.Environment -> String -> Task x ()
progress env line =
    Stream.logLine line env.stderr


timed : Task x a -> Task x ( a, Int )
timed task =
    Time.now
        |> Task.andThen (\t0 -> task |> Task.andThen (\a -> Time.now |> Task.map (\t1 -> ( a, Time.posixToMillis t1 - Time.posixToMillis t0 ))))


atlasJson : System.Environment -> Cli.Options -> Task String String
atlasJson env options =
    Context.resolve options.worktree
        |> Task.andThen
            (\ctx ->
                Context.packageKernels ctx.elmHome
                    |> Task.andThen (\packages -> timed (Build.replay ctx packages (progress env)))
                    |> Task.andThen
                        (\( r, ms ) ->
                            progress env
                                (String.fromInt r.state.rec.frameCount ++ " frames, " ++ String.fromInt (Dict.size r.state.graph.nodes) ++ " nodes now, "
                                    ++ String.fromInt (Set.size (Link.pairs r.state.graph)) ++ " edges now; replay "
                                    ++ String.fromInt ms ++ " ms, " ++ String.fromInt r.extracted ++ " blobs extracted"
                                )
                                |> Task.map (\_ -> E.encode 0 (Atlas.encode r.state.layout r.state.rec))
                        )
            )


exportAtlas : System.Environment -> Cli.Options -> String -> Task String Int
exportAtlas env options file =
    atlasJson env options
        |> Task.andThen (\json -> Fs.writeTextAtomic file json)
        |> Task.map (\_ -> 0)


atlasParity : System.Environment -> Cli.Options -> String -> Task String Int
atlasParity env options file =
    Task.map2 Tuple.pair (atlasJson env options) (Fs.readText file)
        |> Task.andThen
            (\( ours, theirs ) ->
                case ( Json.parse ours, Json.parse theirs ) of
                    ( Just a, Just b ) ->
                        case Json.firstDifference a b of
                            Nothing ->
                                Stream.logLine "atlas parity: equal" env.stdout |> Task.map (\_ -> 0)

                            Just d ->
                                Stream.logLine ("atlas parity: differs at " ++ d) env.stdout |> Task.map (\_ -> 1)

                    _ ->
                        Task.fail "atlas parity: a document is not valid JSON"
            )


{-| The kg directory: the binary is `<kg>/bin/kg`. -}
kgHome : System.Environment -> String
kgHome env =
    let
        app =
            Path.toPosixString env.applicationPath
    in
    case List.reverse (String.split "/" app) of
        _ :: "bin" :: rest ->
            String.join "/" (List.reverse rest)

        _ :: rest ->
            String.join "/" (List.reverse rest)

        [] ->
            "."


buildCommand : System.Environment -> Cli.Options -> Bool -> Task String Int
buildCommand env options full =
    Context.resolve options.worktree
        |> Task.andThen
            (\ctx ->
                Task.map2 Tuple.pair (Context.packageKernels ctx.elmHome) (Update.loadConcepts (kgHome env))
                    |> Task.andThen
                        (\( packages, concepts ) ->
                            Fs.withLock ctx.paths.lock 30000
                                (Snapshot.load ctx.paths.snapshot
                                    |> Task.andThen
                                        (\existing ->
                                            timed
                                                (if full then
                                                    Update.build ctx packages concepts (progress env) |> Task.map Just

                                                 else
                                                    Update.update ctx packages concepts (progress env) existing
                                                )
                                        )
                                    |> Task.andThen
                                        (\( result, ms ) ->
                                            case result of
                                                Nothing ->
                                                    progress env "already current" |> Task.map (\_ -> ms)

                                                Just snap ->
                                                    timed (Snapshot.save ctx.paths.snapshot snap)
                                                        |> Task.andThen
                                                            (\( _, saveMs ) ->
                                                                progress env
                                                                    (String.fromInt (Dict.size snap.graph.nodes) ++ " nodes, "
                                                                        ++ String.fromInt (Graph.edgeCount snap.graph) ++ " edges, "
                                                                        ++ String.fromInt (List.length snap.chunks) ++ " chunks, "
                                                                        ++ String.fromInt (Array.length snap.history.commits) ++ " commits; "
                                                                        ++ String.fromInt ms ++ " ms, saved in " ++ String.fromInt saveMs ++ " ms to " ++ ctx.paths.snapshot
                                                                    )
                                                            )
                                                        |> Task.map (\_ -> ms)
                                        )
                                )
                        )
            )
        |> Task.andThen
            (\r ->
                case r of
                    Fs.Locked _ ->
                        Task.succeed 0

                    Fs.Busy ->
                        progress env "another kg process holds the update lock; it will write the snapshot" |> Task.map (\_ -> 0)
            )


openSession : System.Environment -> Cli.Options -> Task String Session.Session
openSession env options =
    Context.resolve options.worktree
        |> Task.andThen
            (\ctx ->
                Task.map2 Tuple.pair (Context.packageKernels ctx.elmHome) (Update.loadConcepts (kgHome env))
                    |> Task.andThen (\( packages, concepts ) -> Session.open ctx packages concepts (progress env))
            )


queryCommand : System.Environment -> Cli.Options -> String -> String -> Task String Int
queryCommand env options tool json =
    case D.decodeString D.value json of
        Err _ ->
            Task.fail "the arguments are not valid JSON"

        Ok args ->
            timed (openSession env options)
                |> Task.andThen
                    (\( session, openMs ) ->
                        let
                            v =
                                Session.view session

                            query =
                                D.decodeValue (D.field "query" D.string) args |> Result.withDefault ""
                        in
                        (if tool == "locate" then
                            timed (Semantic.load session.ctx (Array.toList v.chunks))
                                |> Task.andThen
                                    (\( sem, loadMs ) ->
                                        if Semantic.vectorCount sem == 0 || not sem.up then
                                            Task.succeed ( [], "no vectors or no embedding server; " )

                                        else
                                            timed (Semantic.queryVector session.ctx sem query)
                                                |> Task.andThen
                                                    (\( q, embedMs ) ->
                                                        timed (Task.succeed () |> Task.map (\_ -> Semantic.rankWith sem sem.view q))
                                                            |> Task.map
                                                                (\( rs, scanMs ) ->
                                                                    ( rs
                                                                    , "vectors " ++ String.fromInt (Semantic.vectorCount sem) ++ " loaded in " ++ String.fromInt loadMs ++ " ms, query embedded in " ++ String.fromInt embedMs ++ " ms, scanned in " ++ String.fromInt scanMs ++ " ms; "
                                                                    )
                                                                )
                                                    )
                                    )
                                |> Task.onError (\e -> Task.succeed ( [], "vectors failed: " ++ e ++ "; " ))

                         else
                            Task.succeed ( [], "" )
                        )
                            |> Task.andThen
                                (\( ranks, vectorNote ) ->
                                    timed (Task.succeed () |> Task.map (\_ -> Tools.call v ranks tool args))
                                        |> Task.map (\( r, ms ) -> ( ( r, ms ), vectorNote ))
                                )
                            |> Task.andThen
                                (\( ( result, callMs ), vectorNote ) ->
                                    Stream.logLine result.text env.stdout
                                        |> Task.andThen (\_ -> progress env ("(open " ++ String.fromInt openMs ++ " ms, " ++ vectorNote ++ "query " ++ String.fromInt callMs ++ " ms, " ++ String.fromInt (String.length result.text) ++ " characters)"))
                                        |> Task.map
                                            (\_ ->
                                                if result.isError then
                                                    1

                                                else
                                                    0
                                            )
                                )
                    )


summaryCommand : System.Environment -> Cli.Options -> Task String Int
summaryCommand env options =
    openSession env options
        |> Task.andThen
            (\session ->
                let
                    v =
                        Session.view session

                    short =
                        Tools.instructions v.graph
                in
                Fs.writeTextAtomic (kgHome env ++ "/out/compiler-map.md") (Tools.overview v)
                    |> Task.andThen (\_ -> Stream.logLine ("instructions: " ++ String.fromInt (String.length short) ++ " characters (at most 4000); wrote " ++ kgHome env ++ "/out/compiler-map.md") env.stdout)
                    |> Task.map
                        (\_ ->
                            if String.length short > 4000 then
                                1

                            else
                                0
                        )
            )


evalCommand : System.Environment -> Cli.Options -> String -> Task String Int
evalCommand env options questions =
    Task.map2 Tuple.pair System.environmentVariables Time.now
        |> Task.andThen
            (\( vars, now ) ->
                let
                    flag k d =
                        Dict.get k options.flags |> Maybe.withDefault d

                    home =
                        Dict.get "HOME" vars |> Maybe.withDefault "."

                    source =
                        Maybe.withDefault (home ++ "/sc/gitlab/eco-compiler") options.worktree

                    list k d =
                        flag k d |> String.split "," |> List.map String.trim |> List.filter ((/=) "")

                    date =
                        Tools.isoDate (Time.posixToMillis now // 1000)
                in
                (case Dict.get "commit" options.flags of
                    Just c ->
                        Task.succeed c

                    Nothing ->
                        Git.head source
                )
                    |> Task.andThen
                        (\commit ->
                            Eval.run
                                { questions = questions
                                , arms = list "arms" "with,without"
                                , runs = flag "runs" "1" |> String.toInt |> Maybe.withDefault 1
                                , only = list "only" ""
                                , phase = flag "phase" "adhoc"
                                , kg = kgHome env ++ "/bin/kg"
                                , workdir = flag "workdir" (home ++ "/.cache/eco-kg/eval/eco-compiler")
                                , commit = commit
                                , source = source
                                , model = Dict.get "model" options.flags
                                , graderModel = flag "grader" "sonnet"
                                , out = flag "out" (kgHome env ++ "/eval/results/" ++ date ++ "-" ++ flag "phase" "adhoc" ++ ".json")
                                , progress = progress env
                                }
                        )
                    |> Task.andThen (\path -> Stream.logLine ("results: " ++ path) env.stdout)
                    |> Task.map (\_ -> 0)
            )


withContext : System.Environment -> Cli.Options -> (Context.Context -> Link.PackageKernels -> List Assemble.ConceptSpec -> Task String a) -> Task String a
withContext env options f =
    Context.resolve options.worktree
        |> Task.andThen
            (\ctx ->
                Task.map2 Tuple.pair (Context.packageKernels ctx.elmHome) (Update.loadConcepts (kgHome env))
                    |> Task.andThen (\( packages, concepts ) -> f ctx packages concepts)
            )


referencesCommand : System.Environment -> Cli.Options -> Task String Int
referencesCommand env options =
    withContext env options
        (\ctx packages concepts ->
            Git.head ctx.worktree
                |> Task.andThen (\head -> Git.lsTree ctx.worktree head Stages.logPaths)
                |> Task.andThen (Update.indexTree ctx packages concepts (progress env) Nothing)
                |> Task.andThen
                    (\ix ->
                        let
                            report =
                                Check.references ix.graph ix.files concepts
                        in
                        Stream.logLine
                            (String.join "\n"
                                ([ "references: " ++ String.fromInt (List.length report.failures) ++ " failures, " ++ String.fromInt (List.length report.listed) ++ " listed" ]
                                    ++ List.map (\x -> "FAIL " ++ x) report.failures
                                    ++ List.map (\x -> "  " ++ x) report.listed
                                )
                            )
                            env.stdout
                            |> Task.map
                                (\_ ->
                                    if List.isEmpty report.failures then
                                        0

                                    else
                                        1
                                )
                    )
        )


determinismCommand : System.Environment -> Cli.Options -> Int -> Task String Int
determinismCommand env options n =
    withContext env options
        (\ctx packages concepts ->
            Git.git ctx.worktree [ "rev-parse", "HEAD~" ++ String.fromInt n ]
                |> Task.map String.trim
                |> Task.andThen
                    (\older ->
                        progress env ("building at HEAD~" ++ String.fromInt n ++ " (" ++ String.left 10 older ++ ")")
                            |> Task.andThen (\_ -> Update.reindexAt ctx packages concepts (progress env) older)
                            |> Task.andThen
                                (\atOlder ->
                                    progress env "updating to HEAD"
                                        |> Task.andThen (\_ -> timed (Update.update ctx packages concepts (progress env) (Just atOlder)))
                                )
                            |> Task.andThen
                                (\( updated, updateMs ) ->
                                    progress env ("update took " ++ String.fromInt updateMs ++ " ms; full build at HEAD")
                                        |> Task.andThen (\_ -> Update.build ctx packages concepts (progress env))
                                        |> Task.map (\full -> ( Maybe.withDefault full updated, full ))
                                )
                            |> Task.andThen
                                (\( a, b ) ->
                                    case Check.determinism a b of
                                        [] ->
                                            Stream.logLine ("determinism: HEAD~" ++ String.fromInt n ++ " updated to HEAD equals a full build") env.stdout |> Task.map (\_ -> 0)

                                        diffs ->
                                            Stream.logLine ("determinism: differs in " ++ String.join ", " diffs) env.stdout |> Task.map (\_ -> 1)
                                )
                    )
        )


edgesCommand : System.Environment -> Cli.Options -> String -> Task String Int
edgesCommand env options kind =
    openSession env options
        |> Task.andThen
            (\session ->
                let
                    g =
                        (Session.view session).graph

                    all =
                        Graph.nodes g |> List.concatMap (\x -> Graph.outgoing x.id g) |> List.filter (\e -> e.kind == kind)

                    n =
                        Dict.get "sample" options.flags |> Maybe.andThen String.toInt |> Maybe.withDefault (List.length all)

                    step =
                        max 1 (List.length all // max 1 n)

                    sample =
                        List.indexedMap Tuple.pair all |> List.filter (\( i, _ ) -> modBy step i == 0) |> List.map Tuple.second |> List.take n

                    fileOf id =
                        Graph.node id g |> Maybe.andThen (\x -> List.head x.paths) |> Maybe.withDefault ""

                    lineText e =
                        case e.line of
                            Just l ->
                                let
                                    file =
                                        if String.startsWith "plan:" e.from || String.startsWith "doc:" e.from || String.startsWith "inv:" e.from then
                                            fileOf e.from

                                        else if kind == "gates" then
                                            fileOf e.to

                                        else
                                            fileOf e.from
                                in
                                Fs.readTextMaybe (session.ctx.worktree ++ "/" ++ file)
                                    |> Task.map (\t -> file ++ ":" ++ String.fromInt l ++ ": " ++ (Maybe.withDefault "" t |> String.lines |> List.drop (l - 1) |> List.head |> Maybe.withDefault "" |> String.trim |> String.left 160))

                            Nothing ->
                                Task.succeed ""
                in
                Stream.logLine (String.fromInt (List.length all) ++ " " ++ kind ++ " edges; sample of " ++ String.fromInt (List.length sample)) env.stdout
                    |> Task.andThen
                        (\_ ->
                            sample
                                |> List.map (\e -> lineText e |> Task.andThen (\t -> Stream.logLine (e.from ++ " -> " ++ e.to ++ "\n    " ++ t) env.stdout))
                                |> Task.sequence
                        )
                    |> Task.map (\_ -> 0)
            )


{-| The background embedding, run in the foreground: for the first build. -}
embedCommand : System.Environment -> Cli.Options -> Task String Int
embedCommand env options =
    let
        maxMs =
            (Dict.get "max-minutes" options.flags |> Maybe.andThen String.toInt |> Maybe.withDefault 600) * 60 * 1000
    in
    openSession env options
        |> Task.andThen
            (\session ->
                Semantic.load session.ctx (Array.toList (Session.view session).chunks)
                    |> Task.andThen
                        (\sem ->
                            progress env ("vectors: " ++ Semantic.describe sem ++ (if sem.up then "" else "; no embedding server at " ++ session.ctx.ollama))
                                |> Task.andThen (\_ -> Time.now)
                                |> Task.andThen (\t0 -> embedLoop env session.ctx (Time.posixToMillis t0 + maxMs) 0 sem)
                        )
            )
        |> Task.map (\_ -> 0)


embedLoop : System.Environment -> Context.Context -> Int -> Int -> Semantic.State -> Task String Semantic.State
embedLoop env ctx deadline n sem =
    Time.now
        |> Task.andThen
            (\now ->
                if Semantic.pendingCount sem == 0 || not sem.up || Time.posixToMillis now > deadline then
                    Semantic.save ctx sem
                        |> Task.andThen (\saved -> progress env ("vectors: " ++ Semantic.describe saved ++ (sem.lastError |> Maybe.map (\e -> "; " ++ e) |> Maybe.withDefault "")) |> Task.map (\_ -> saved))

                else
                    Semantic.embedBatch ctx sem
                        |> Task.andThen
                            (\next ->
                                if modBy 25 (n + 1) == 0 then
                                    Semantic.save ctx next
                                        |> Task.andThen (\saved -> progress env ("  " ++ Semantic.describe saved) |> Task.map (\_ -> saved))

                                else
                                    Task.succeed next
                            )
                        |> Task.andThen (embedLoop env ctx deadline (n + 1))
            )
