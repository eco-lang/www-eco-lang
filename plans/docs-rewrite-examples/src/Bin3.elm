module Bin3 exposing (main)

import Bytes exposing (Bytes)
import Bytes.Decode as D
import Bytes.Encode as E
import Html exposing (text)


encodeRgb : Int -> Int -> Int -> Bytes
encodeRgb r g b =
    E.encode (E.sequence [ E.unsignedInt8 r, E.unsignedInt8 g, E.unsignedInt8 b ])


decodeRgb : Bytes -> Maybe ( Int, Int, Int )
decodeRgb bytes =
    D.decode (D.map3 (\r g b -> ( r, g, b )) D.unsignedInt8 D.unsignedInt8 D.unsignedInt8) bytes


main =
    case decodeRgb (encodeRgb 255 128 0) of
        Just ( r, g, b ) ->
            text (String.fromInt (r + g + b))

        Nothing ->
            text "fail"
