module Test.Runner exposing (Test, equal, expect, pure, run, task)

{-| A small test runner for eco programs: each test is a task that succeeds or
fails with a message, and `run` prints a PASS or FAIL line for each.
-}

import Stream
import System
import Task exposing (Task)


type alias Test =
    { name : String, body : Task String () }


pure : String -> (() -> Result String ()) -> Test
pure name f =
    { name = name, body = Task.succeed () |> Task.andThen (\_ -> resultToTask (f ())) }


task : String -> Task String () -> Test
task name body =
    { name = name, body = body }


expect : Bool -> String -> Result String ()
expect ok why =
    if ok then
        Ok ()

    else
        Err why


equal : a -> a -> Result String ()
equal expected actual =
    if expected == actual then
        Ok ()

    else
        Err ("expected\n    " ++ Debug.toString expected ++ "\nbut got\n    " ++ Debug.toString actual)


resultToTask : Result String () -> Task String ()
resultToTask r =
    case r of
        Ok () ->
            Task.succeed ()

        Err e ->
            Task.fail e


{-| Runs the tests whose names contain the filter, in order. -}
run : System.Environment -> String -> List Test -> Task Never ()
run env filter tests =
    List.foldl
        (\t acc ->
            if String.contains filter t.name then
                acc
                    |> Task.andThen
                        (\( pass, fail ) ->
                            t.body
                                |> Task.map (\_ -> Ok ())
                                |> Task.onError (\e -> Task.succeed (Err e))
                                |> Task.andThen
                                    (\r ->
                                        case r of
                                            Ok () ->
                                                Stream.logLine ("PASS " ++ t.name) env.stdout
                                                    |> Task.map (\_ -> ( pass + 1, fail ))

                                            Err e ->
                                                Stream.logLine ("FAIL " ++ t.name ++ "\n  " ++ String.replace "\n" "\n  " e) env.stdout
                                                    |> Task.map (\_ -> ( pass, fail + 1 ))
                                    )
                        )

            else
                acc
        )
        (Task.succeed ( 0, 0 ))
        tests
        |> Task.andThen
            (\( pass, fail ) ->
                Stream.logLine (String.fromInt pass ++ " passed, " ++ String.fromInt fail ++ " failed") env.stdout
                    |> Task.andThen
                        (\_ ->
                            if fail > 0 then
                                System.setExitCode 1

                            else
                                Task.succeed ()
                        )
            )
