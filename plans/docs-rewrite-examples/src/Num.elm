module Num exposing (main)

import Html exposing (text)


main =
    let
        n =
            30

        a =
            n + 1

        b =
            n * 1.5

        c =
            10 + 3
    in
    text (String.fromInt a ++ " " ++ String.fromFloat b ++ " " ++ Debug.toString c)
