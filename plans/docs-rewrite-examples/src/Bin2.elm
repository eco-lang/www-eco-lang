module Bin2 exposing (main)

import Bytes exposing (Bytes, Endianness(..))
import Bytes.Decode as D
import Bytes.Encode as E
import Html exposing (text)


encodePoint : Int -> Int -> Bytes
encodePoint x y =
    E.encode
        (E.sequence
            [ E.unsignedInt8 1
            , E.unsignedInt16 BE x
            , E.unsignedInt16 BE y
            ]
        )


decodePoint : Bytes -> Maybe ( Int, Int )
decodePoint bytes =
    D.decode
        (D.map3 (\_ x y -> ( x, y ))
            D.unsignedInt8
            (D.unsignedInt16 BE)
            (D.unsignedInt16 BE)
        )
        bytes


main =
    case decodePoint (encodePoint 300 7) of
        Just ( x, y ) ->
            text (String.fromInt (x + y))

        Nothing ->
            text "fail"
