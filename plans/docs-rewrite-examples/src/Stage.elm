module Stage exposing (main)

import Html exposing (text)


adder : Int -> Int -> Int
adder a =
    \b -> a + b


scale : Int -> Int -> Int -> Int
scale k =
    let
        k2 =
            k * k
    in
    \x y -> k2 * x + y


twice : (a -> a) -> a -> a
twice f x =
    f (f x)


dup : (a -> a) -> a -> a
dup =
    twice


inc : Int -> Int
inc =
    adder 1


main =
    let
        s =
            scale 3

        r1 =
            adder 1 2

        r2 =
            s 4 5

        r3 =
            dup inc 10

        r4 =
            List.map (scale 2 1) [ 1, 2 ]
    in
    text (String.fromInt (r1 + r2 + r3 + List.sum r4))
