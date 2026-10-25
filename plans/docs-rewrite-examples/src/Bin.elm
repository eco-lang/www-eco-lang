module Bin exposing (main)

import Bytes exposing (Endianness(..))
import Bytes.Decode as D
import Bytes.Encode as E
import Html exposing (text)


type alias Point =
    { x : Int, y : Int }


encodePoint : Point -> E.Encoder
encodePoint p =
    E.sequence
        [ E.unsignedInt8 1
        , E.unsignedInt16 BE p.x
        , E.unsignedInt16 BE p.y
        ]


decodePoint : D.Decoder Point
decodePoint =
    D.map3 (\_ x y -> Point x y)
        D.unsignedInt8
        (D.unsignedInt16 BE)
        (D.unsignedInt16 BE)


main =
    let
        bytes =
            E.encode (encodePoint { x = 300, y = 7 })
    in
    case D.decode decodePoint bytes of
        Just p ->
            text (String.fromInt (p.x + p.y))

        Nothing ->
            text "fail"
