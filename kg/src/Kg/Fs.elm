module Kg.Fs exposing
    ( readText, readBytes, readTextMaybe, readBytesMaybe, exists, writeAtomic, writeTextAtomic, makeDirs, remove
    , listDir, isDirectory
    , withLock, LockResult(..)
    , cacheRoot, Paths, paths
    , bytesToString, errorText
    )

{-| Files: reading text, writing atomically, the update lock, and where kg keeps
its caches (§11 of the plan).

Every write goes to a temporary file next to the target, then is moved onto
it, so a reader never sees a partial file. The update lock is a file created
with `createNew`; a lock older than ten minutes is stale.

-}

import Bytes exposing (Bytes)
import Bytes.Decode
import Bytes.Encode
import Dict exposing (Dict)
import FileSystem
import Kg.Sha256 as Sha256
import Path
import Process
import Task exposing (Task)
import Time


errorText : FileSystem.Error -> String
errorText e =
    FileSystem.errorToString e


bytesToString : Bytes -> Maybe String
bytesToString b =
    Bytes.Decode.decode (Bytes.Decode.string (Bytes.width b)) b


readBytes : String -> Task String Bytes
readBytes path =
    FileSystem.readFile (Path.fromPosixString path)
        |> Task.mapError (\e -> path ++ ": " ++ errorText e)


readText : String -> Task String String
readText path =
    readBytes path
        |> Task.andThen
            (\b ->
                case bytesToString b of
                    Just s ->
                        Task.succeed s

                    Nothing ->
                        Task.fail (path ++ ": not UTF-8")
            )


{-| Nothing when the file does not exist or cannot be read. -}
readBytesMaybe : String -> Task x (Maybe Bytes)
readBytesMaybe path =
    FileSystem.readFile (Path.fromPosixString path)
        |> Task.map Just
        |> Task.onError (\_ -> Task.succeed Nothing)


readTextMaybe : String -> Task x (Maybe String)
readTextMaybe path =
    readBytesMaybe path |> Task.map (Maybe.andThen bytesToString)


exists : String -> Task x Bool
exists path =
    FileSystem.metadata { resolveLink = True } (Path.fromPosixString path)
        |> Task.map (\_ -> True)
        |> Task.onError (\_ -> Task.succeed False)


isDirectory : String -> Task x Bool
isDirectory path =
    FileSystem.metadata { resolveLink = True } (Path.fromPosixString path)
        |> Task.map (\m -> m.entityType == FileSystem.Directory)
        |> Task.onError (\_ -> Task.succeed False)


listDir : String -> Task String (List { name : String, isDir : Bool })
listDir path =
    FileSystem.listDirectory (Path.fromPosixString path)
        |> Task.map
            (List.map
                (\e ->
                    { name = Path.filenameWithExtension e.path
                    , isDir = e.entityType == FileSystem.Directory
                    }
                )
            )
        |> Task.mapError (\e -> path ++ ": " ++ errorText e)


makeDirs : String -> Task String ()
makeDirs path =
    FileSystem.makeDirectory { recursive = True } (Path.fromPosixString path)
        |> Task.map (\_ -> ())
        |> Task.onError
            (\e ->
                if FileSystem.errorKind e == FileSystem.FileExists then
                    Task.succeed ()

                else
                    Task.fail (path ++ ": " ++ errorText e)
            )


remove : String -> Task x ()
remove path =
    FileSystem.remove { recursive = True } (Path.fromPosixString path)
        |> Task.map (\_ -> ())
        |> Task.onError (\_ -> Task.succeed ())


parentOf : String -> String
parentOf path =
    case List.reverse (String.split "/" path) of
        _ :: rest ->
            String.join "/" (List.reverse rest)

        [] ->
            "."


{-| Writes to `<path>.tmp-<time>-<hash>` and moves it onto `path`, making the
directory first if it is missing.
-}
writeAtomic : String -> Bytes -> Task String ()
writeAtomic path bytes =
    Time.now
        |> Task.andThen
            (\now ->
                let
                    tmp =
                        path ++ ".tmp-" ++ String.fromInt (Time.posixToMillis now) ++ "-" ++ Sha256.short 8 (path ++ String.fromInt (Bytes.width bytes))

                    write =
                        FileSystem.writeFile bytes (Path.fromPosixString tmp)
                            |> Task.mapError (\e -> tmp ++ ": " ++ errorText e)
                in
                write
                    |> Task.onError (\_ -> makeDirs (parentOf path) |> Task.andThen (\_ -> write))
                    |> Task.andThen
                        (\_ ->
                            FileSystem.move (Path.fromPosixString path) (Path.fromPosixString tmp)
                                |> Task.mapError (\e -> path ++ ": " ++ errorText e)
                        )
                    |> Task.map (\_ -> ())
            )


writeTextAtomic : String -> String -> Task String ()
writeTextAtomic path text =
    writeAtomic path (Bytes.Encode.encode (Bytes.Encode.string text))



-- LOCKS


type LockResult a
    = Locked a
    | Busy


{-| Runs the task holding the lock file. While another process holds a lock
younger than ten minutes, retries every 200 ms for up to `waitMs`; then gives
`Busy`. An older lock is stale, and is removed.
-}
withLock : String -> Int -> Task String a -> Task String (LockResult a)
withLock lockPath waitMs body =
    let
        create =
            Time.now
                |> Task.andThen
                    (\now ->
                        FileSystem.writeFileWith { createNew = True, sync = False }
                            (Bytes.Encode.encode (Bytes.Encode.string (String.fromInt (Time.posixToMillis now))))
                            (Path.fromPosixString lockPath)
                            |> Task.map (\_ -> True)
                            |> Task.onError (\_ -> Task.succeed False)
                    )

        release =
            remove lockPath

        attempt left =
            create
                |> Task.andThen
                    (\got ->
                        if got then
                            body
                                |> Task.onError (\e -> release |> Task.andThen (\_ -> Task.fail e))
                                |> Task.andThen (\a -> release |> Task.map (\_ -> Locked a))

                        else
                            stale
                                |> Task.andThen
                                    (\isStale ->
                                        if isStale then
                                            release |> Task.andThen (\_ -> attempt left)

                                        else if left <= 0 then
                                            Task.succeed Busy

                                        else
                                            Process.sleep 200 |> Task.andThen (\_ -> attempt (left - 200))
                                    )
                    )

        stale =
            Task.map2
                (\now content ->
                    case content |> Maybe.andThen (String.trim >> String.toInt) of
                        Just t ->
                            Time.posixToMillis now - t > 10 * 60 * 1000

                        Nothing ->
                            False
                )
                Time.now
                (readTextMaybe lockPath)
    in
    makeDirs (parentOf lockPath) |> Task.andThen (\_ -> attempt waitMs)



-- CACHE PATHS


{-| `$ECO_KG_CACHE`, else `~/.cache/eco-kg`. -}
cacheRoot : Dict String String -> String
cacheRoot vars =
    case Dict.get "ECO_KG_CACHE" vars of
        Just dir ->
            dir

        Nothing ->
            (Dict.get "HOME" vars |> Maybe.withDefault ".") ++ "/.cache/eco-kg"


type alias Paths =
    { repo : String
    , facts : String -> String -> String
    , vector : String -> String -> String
    , worktree : String
    , snapshot : String
    , overlay : String
    , lock : String
    , scratch : String
    }


{-| Where things live. Facts and vectors are content-addressed (by git blob id,
and by the SHA-256 of a chunk's text), so every repository shares them: a
clone of eco-compiler reuses the facts its origin's history already has.
Snapshots are per worktree, under the repository (by its common git
directory).
-}
paths : String -> String -> String -> Paths
paths root commonGitDir worktreeRoot =
    let
        repo =
            root ++ "/" ++ Sha256.short 16 commonGitDir

        wt =
            repo ++ "/worktrees/" ++ Sha256.short 16 worktreeRoot
    in
    { repo = repo
    , facts = \blob kind -> root ++ "/facts/" ++ String.left 2 blob ++ "/" ++ String.dropLeft 2 blob ++ "." ++ kind
    , vector = \model hash -> root ++ "/vectors/" ++ model ++ "/" ++ String.left 2 hash ++ "/" ++ String.dropLeft 2 hash
    , worktree = wt
    , snapshot = wt ++ "/snapshot.kg"
    , overlay = wt ++ "/overlay.kg"
    , lock = wt ++ "/lock"
    , scratch = wt ++ "/tmp"
    }
