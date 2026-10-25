module Agg exposing (main)

import Html exposing (text)


minMax : List Int -> ( Int, Int )
minMax xs =
    List.foldl (\x ( lo, hi ) -> ( min lo x, max hi x )) ( 999, -999 ) xs


main =
    let
        pair =
            ( 3, 4 )

        ( a, b ) =
            pair

        ( lo, hi ) =
            minMax [ 5, 1, 9 ]
    in
    text (String.fromInt (a * b + lo + hi))
