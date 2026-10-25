module Agg2 exposing (main)

import Html exposing (text)


divMod : Int -> Int -> ( Int, Int )
divMod a b =
    ( a // b, modBy b a )


magnitude : ( Int, Int ) -> Int
magnitude ( x, y ) =
    x * x + y * y


main =
    let
        ( q, r ) =
            divMod 17 5

        point =
            ( q, r )
    in
    text (String.fromInt (magnitude point))
