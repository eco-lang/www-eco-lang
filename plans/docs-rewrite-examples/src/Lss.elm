module Lss exposing (main)

import Html exposing (text)


applyTwice : (Int -> Int) -> Int -> Int
applyTwice f x =
    f (f x)


repeatApply : (Int -> Int) -> Int -> Int -> Int
repeatApply f n acc =
    if n <= 0 then
        acc

    else
        repeatApply f (n - 1) (f acc)


pick : Bool -> (Int -> Int)
pick flag =
    if flag then
        \x -> x + 1

    else
        \x -> x * 2


main =
    let
        step =
            5

        one =
            repeatApply (\x -> x + step) 5 1

        two =
            repeatApply (pick (step > 3)) 3 1

        fs =
            [ \x -> x + 1, \x -> x * 2, negate ]

        three =
            List.foldl (\g acc -> g acc) 1 fs
    in
    text (String.fromInt (one + two + three))
