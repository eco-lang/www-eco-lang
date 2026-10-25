module Stage2 exposing (main)

import Html exposing (text)
import Set


makeLookup : List Int -> Int -> Bool
makeLookup xs =
    let
        s =
            Set.fromList xs
    in
    \x -> Set.member x s


add3 : Int -> Int -> Int -> Int
add3 a b c =
    a + b + c


main =
    let
        isIn =
            makeLookup [ 1, 5, 9 ]

        hits =
            List.filter isIn [ 1, 2, 3, 4, 5 ]

        partial =
            add3 1

        r =
            partial 2 3 + (if makeLookup [ 2 ] 2 then 1 else 0)
    in
    text (String.fromInt (List.length hits + r))
