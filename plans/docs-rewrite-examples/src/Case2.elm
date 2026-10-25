module Case2 exposing (main)

import Html exposing (text)


classify : Maybe Int -> Maybe Int -> String
classify a b =
    case ( a, b ) of
        ( Just 0, _ ) ->
            "a is zero"

        ( _, Just 0 ) ->
            "b is zero"

        _ ->
            "neither"


main =
    text (classify (Just 1) (Just 0) ++ classify Nothing Nothing)
