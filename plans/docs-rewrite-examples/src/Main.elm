module Main exposing (main)

import Html exposing (text)


type Shape
    = Circle Float
    | Rect Float Float
    | Square Float


area : Shape -> Float
area shape =
    case shape of
        Circle r ->
            3.14 * r * r

        Rect w h ->
            w * h

        Square s ->
            s * s


sumTo : Int -> Int -> Int
sumTo acc n =
    if n <= 0 then
        acc

    else
        sumTo (acc + n) (n - 1)


twice : (a -> a) -> a -> a
twice f x =
    f (f x)


add : number -> number -> number
add a b =
    a + b


main =
    text
        (String.fromInt (sumTo 0 (twice (add 1) 10))
            ++ String.fromFloat (area (Rect 2 3))
            ++ String.join "," (List.map String.fromInt (List.map (\x -> x * 2) [ 1, 2, 3 ]))
        )
