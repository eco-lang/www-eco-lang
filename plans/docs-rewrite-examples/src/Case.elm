module Case exposing (main)

import Html exposing (text)


describe : List (Maybe Int) -> String
describe xs =
    case xs of
        [] ->
            "empty"

        (Just 0) :: _ ->
            "starts with zero"

        (Just n) :: [] ->
            "one: " ++ String.fromInt n

        Nothing :: rest ->
            "skip " ++ describe rest

        _ ->
            "other"


main =
    text (describe [ Just 0 ] ++ describe [ Nothing, Just 3 ] ++ describe [])
