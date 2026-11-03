module Kg.Git exposing
    ( Commit, Change, StatusEntry
    , git, gitBytes, topLevel, commonDir, head, isAncestor, mergeBase
    , log, parseLog, lsTree, status, parseStatus, hashObjects, catFiles, parseCatFile
    )

{-| Git, through `ChildProcess.run` (§7 of the plan).

Every command runs `git --no-optional-locks -C <worktree>` with
`GIT_OPTIONAL_LOCKS=0`, with no shell, so `status` never takes `index.lock` in a
worktree Claude is using. Paths are not quoted (`core.quotePath=false`).

Blob contents come from `git cat-file --batch` in batches: the ids are written
to a list file and fed to it on standard input by `sh`, with the paths passed as
arguments, never spliced into the command.

-}

import Bytes exposing (Bytes)
import Bytes.Decode as D
import Bytes.Encode as E
import ChildProcess
import Dict exposing (Dict)
import Kg.Fs as Fs
import Task exposing (Task)


type alias Commit =
    { hash : String, time : Int, subject : String, changes : List Change }


{-| One line of `--raw` output: the status letter, the old path, the new path
(the same as the old unless renamed or copied) and the new blob id (all zeros
for a deletion).
-}
type alias Change =
    { status : Char, old : String, new : String, blob : String }


type alias StatusEntry =
    { xy : String, path : String, from : Maybe String }


options : Int -> ChildProcess.RunOptions
options limit =
    { shell = ChildProcess.NoShell
    , workingDirectory = ChildProcess.InheritWorkingDirectory
    , environmentVariables = ChildProcess.MergeWithEnvironmentVariables (Dict.fromList [ ( "GIT_OPTIONAL_LOCKS", "0" ) ])
    , maximumBytesWrittenToStreams = limit
    , runDuration = ChildProcess.NoLimit
    }


baseArgs : String -> List String
baseArgs worktree =
    [ "--no-optional-locks", "-C", worktree, "-c", "core.quotePath=false" ]


failure : List String -> ChildProcess.FailedRun -> String
failure args f =
    "git " ++ String.join " " (List.take 6 args) ++ ": "
        ++ (case f of
                ChildProcess.InitError e ->
                    "could not start (" ++ e.errorCode ++ ")"

                ChildProcess.ProgramError e ->
                    "exit " ++ String.fromInt e.exitCode ++ ": " ++ String.left 500 (Maybe.withDefault "" (Fs.bytesToString e.stderr))
           )


gitBytes : Int -> String -> List String -> Task String Bytes
gitBytes limit worktree args =
    ChildProcess.run "git" (baseArgs worktree ++ args) (options limit)
        |> Task.map .stdout
        |> Task.mapError (failure args)


{-| Runs git and gives its standard output as text. -}
git : String -> List String -> Task String String
git worktree args =
    gitBytes (64 * 1024 * 1024) worktree args
        |> Task.map (Fs.bytesToString >> Maybe.withDefault "")


trimmed : String -> List String -> Task String String
trimmed worktree args =
    git worktree args |> Task.map String.trim


topLevel : String -> Task String String
topLevel dir =
    trimmed dir [ "rev-parse", "--path-format=absolute", "--show-toplevel" ]


commonDir : String -> Task String String
commonDir dir =
    trimmed dir [ "rev-parse", "--path-format=absolute", "--git-common-dir" ]


head : String -> Task String String
head dir =
    trimmed dir [ "rev-parse", "HEAD" ]


isAncestor : String -> String -> String -> Task String Bool
isAncestor dir a b =
    ChildProcess.run "git" (baseArgs dir ++ [ "merge-base", "--is-ancestor", a, b ]) (options 65536)
        |> Task.map (\_ -> True)
        |> Task.onError
            (\f ->
                case f of
                    ChildProcess.ProgramError e ->
                        if e.exitCode == 1 then
                            Task.succeed False

                        else
                            Task.fail (failure [ "merge-base" ] f)

                    _ ->
                        Task.fail (failure [ "merge-base" ] f)
            )


mergeBase : String -> String -> String -> Task String String
mergeBase dir a b =
    trimmed dir [ "merge-base", a, b ]


{-| The first-parent history in `range` (empty for all of it up to HEAD), oldest
first, limited to `paths`.
-}
log : String -> String -> List String -> Task String (List Commit)
log dir range paths =
    git dir
        ([ "log", "--first-parent", "--diff-merges=first-parent", "--reverse", "-M", "--raw", "--no-abbrev", "--format=@%H%x09%ct%x09%s" ]
            ++ (if range == "" then
                    []

                else
                    [ range ]
               )
            ++ ("--" :: paths)
        )
        |> Task.map parseLog


parseLog : String -> List Commit
parseLog out =
    let
        step line acc =
            if String.startsWith "@" line then
                case String.split "\t" (String.dropLeft 1 line) of
                    h :: t :: rest ->
                        { hash = h, time = String.toInt t |> Maybe.withDefault 0, subject = String.join "\t" rest, changes = [] } :: finishLast acc

                    _ ->
                        acc

            else if String.startsWith ":" line then
                case ( acc, String.split "\t" line ) of
                    ( c :: rest, meta :: pathsHere ) ->
                        case String.words meta of
                            [ _, _, _, new, st ] ->
                                let
                                    old =
                                        List.head pathsHere |> Maybe.withDefault ""

                                    newPath =
                                        List.reverse pathsHere |> List.head |> Maybe.withDefault old
                                in
                                { c | changes = { status = String.uncons st |> Maybe.map Tuple.first |> Maybe.withDefault 'M', old = old, new = newPath, blob = new } :: c.changes } :: rest

                            _ ->
                                acc

                    _ ->
                        acc

            else
                acc

        finishLast acc =
            case acc of
                c :: rest ->
                    { c | changes = List.reverse c.changes } :: rest

                [] ->
                    []
    in
    String.lines out
        |> List.foldl step []
        |> finishLast
        |> List.reverse


{-| The blobs of a commit's tree under `paths`, by path. -}
lsTree : String -> String -> List String -> Task String (Dict String String)
lsTree dir commit paths =
    git dir ([ "ls-tree", "-r", "--full-tree", commit, "--" ] ++ paths)
        |> Task.map
            (\out ->
                String.lines out
                    |> List.filterMap
                        (\line ->
                            case String.split "\t" line of
                                [ meta, path ] ->
                                    case String.words meta of
                                        [ _, "blob", sha ] ->
                                            Just ( path, sha )

                                        _ ->
                                            Nothing

                                _ ->
                                    Nothing
                        )
                    |> Dict.fromList
            )


{-| Files that differ from HEAD (staged, unstaged or untracked) under `paths`. -}
status : String -> List String -> Task String (List StatusEntry)
status dir paths =
    git dir ([ "status", "--porcelain=v1", "-z", "--untracked-files=all", "--" ] ++ paths)
        |> Task.map parseStatus


parseStatus : String -> List StatusEntry
parseStatus out =
    let
        go parts acc =
            case parts of
                entry :: rest ->
                    if String.length entry < 4 then
                        go rest acc

                    else
                        let
                            xy =
                                String.left 2 entry

                            path =
                                String.dropLeft 3 entry
                        in
                        if String.contains "R" xy || String.contains "C" xy then
                            case rest of
                                from :: more ->
                                    go more ({ xy = xy, path = path, from = Just from } :: acc)

                                [] ->
                                    List.reverse ({ xy = xy, path = path, from = Nothing } :: acc)

                        else
                            go rest ({ xy = xy, path = path, from = Nothing } :: acc)

                [] ->
                    List.reverse acc
    in
    go (String.split "\u{0000}" out) []


{-| The blob ids the files in the worktree would have, without writing them. -}
hashObjects : String -> List String -> Task String (List String)
hashObjects dir files =
    if List.isEmpty files then
        Task.succeed []

    else
        git dir ("hash-object" :: "--" :: files)
            |> Task.map (String.lines >> List.map String.trim >> List.filter ((/=) ""))


{-| The contents of blobs, by id, read in batches of 400. `scratch` is a
directory kg may write the list files into. A missing blob is left out.
-}
catFiles : String -> String -> List String -> Task String (Dict String Bytes)
catFiles dir scratch blobs =
    let
        batches xs =
            if List.isEmpty xs then
                []

            else
                List.take 400 xs :: batches (List.drop 400 xs)

        listFile =
            scratch ++ "/cat-file-list"

        one batch =
            Fs.writeTextAtomic listFile (String.join "\n" batch ++ "\n")
                |> Task.andThen
                    (\_ ->
                        ChildProcess.run "sh"
                            [ "-c", "exec git --no-optional-locks -C \"$1\" cat-file --batch < \"$2\"", "sh", dir, listFile ]
                            (options (1024 * 1024 * 1024))
                            |> Task.map (.stdout >> parseCatFile)
                            |> Task.mapError (failure [ "cat-file" ])
                    )
    in
    List.foldl
        (\batch acc -> acc |> Task.andThen (\d -> one batch |> Task.map (Dict.union d)))
        (Task.succeed Dict.empty)
        (batches blobs)


{-| `<sha> blob <size>\n<body>\n`, repeated; `<sha> missing\n` for an id git
does not have.
-}
parseCatFile : Bytes -> Dict String Bytes
parseCatFile bytes =
    let
        headerLine =
            D.loop [] (\acc -> D.unsignedInt8 |> D.map (\b -> if b == 10 then D.Done (List.reverse acc) else D.Loop (b :: acc)))

        object total =
            D.loop ( total, Dict.empty )
                (\( left, acc ) ->
                    if left <= 0 then
                        D.succeed (D.Done acc)

                    else
                        headerLine
                            |> D.andThen
                                (\codes ->
                                    let
                                        line =
                                            String.fromList (List.map Char.fromCode codes)

                                        consumed =
                                            List.length codes + 1
                                    in
                                    case String.words line of
                                        [ sha, _, size ] ->
                                            case String.toInt size of
                                                Just n ->
                                                    D.bytes n
                                                        |> D.andThen (\body -> D.unsignedInt8 |> D.map (\_ -> D.Loop ( left - consumed - n - 1, Dict.insert sha body acc )))

                                                Nothing ->
                                                    D.succeed (D.Done acc)

                                        [ _, "missing" ] ->
                                            D.succeed (D.Loop ( left - consumed, acc ))

                                        _ ->
                                            D.succeed (D.Done acc)
                                )
                )
    in
    D.decode (object (Bytes.width bytes)) bytes |> Maybe.withDefault Dict.empty
