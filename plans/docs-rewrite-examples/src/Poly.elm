module Poly exposing (main)

import Html exposing (text)


identity2 : a -> a
identity2 x =
    x


add : number -> number -> number
add a b =
    a + b


double : Int -> Int
double n =
    n * 2


main =
    let
        ints =
            List.map double [ 1, 2, 3 ]

        lens =
            List.map String.length [ "a", "bb" ]

        i =
            identity2 42

        s =
            identity2 "hi"

        n =
            add 1 2

        f =
            add 1.5 2.5
    in
    text
        (String.fromInt (List.sum ints + List.sum lens + i + n)
            ++ s
            ++ String.fromFloat f
        )
