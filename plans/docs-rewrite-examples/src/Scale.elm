module Scale exposing (main)

import Html exposing (text)


type Shape
    = Circle Float
    | Rect Float Float


scale : Float -> Shape -> Shape
scale k shape =
    case shape of
        Circle r ->
            Circle (k * r)

        Rect w h ->
            Rect (k * w) (k * h)


count : Int -> Maybe Int -> Int
count n m =
    case m of
        Just x ->
            n + x

        Nothing ->
            n


main =
    let
        s =
            scale 2 (Rect 1 2)
    in
    text
        (String.fromInt (count 1 (Just 2))
            ++ (case s of
                    Rect w _ ->
                        String.fromFloat w

                    Circle r ->
                        String.fromFloat r
               )
        )
