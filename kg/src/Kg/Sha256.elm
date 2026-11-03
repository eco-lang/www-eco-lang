module Kg.Sha256 exposing (sha256, sha256Bytes, short)

{-| SHA-256, in hex.

`billstclair/elm-sha256` gives wrong hashes under eco, whose `Bitwise` works on
64-bit integers by design, where JavaScript Elm's works on 32. This version
masks every result to 32 bits, so it is right under both.

-}

import Array exposing (Array)
import Bitwise exposing (and, or, shiftLeftBy, shiftRightZfBy)
import Bytes exposing (Bytes, Endianness(..))
import Bytes.Decode as D
import Bytes.Encode as E


sha256 : String -> String
sha256 text =
    sha256Bytes (E.encode (E.string text))


{-| The first n hex characters of the SHA-256 of a string. -}
short : Int -> String -> String
short n text =
    String.left n (sha256 text)


sha256Bytes : Bytes -> String
sha256Bytes bytes =
    let
        len =
            Bytes.width bytes

        zeros =
            modBy 64 (55 - len)

        bits =
            len * 8

        padded =
            E.encode
                (E.sequence
                    [ E.bytes bytes
                    , E.unsignedInt8 0x80
                    , E.sequence (List.repeat zeros (E.unsignedInt8 0))
                    , E.unsignedInt32 BE (bits // 0x0000000100000000)
                    , E.unsignedInt32 BE (modBy 0x0000000100000000 bits)
                    ]
                )

        blocks =
            Bytes.width padded // 64
    in
    case D.decode (D.loop ( blocks, initial ) step) padded of
        Just h ->
            List.map hex8 [ h.a, h.b, h.c, h.d, h.e, h.f, h.g, h.h ] |> String.concat

        Nothing ->
            ""


type alias State =
    { a : Int, b : Int, c : Int, d : Int, e : Int, f : Int, g : Int, h : Int }


initial : State
initial =
    State 0x6A09E667 0xBB67AE85 0x3C6EF372 0xA54FF53A 0x510E527F 0x9B05688C 0x1F83D9AB 0x5BE0CD19


step : ( Int, State ) -> D.Decoder (D.Step ( Int, State ) State)
step ( left, state ) =
    if left <= 0 then
        D.succeed (D.Done state)

    else
        D.loop ( 16, [] ) word
            |> D.map (\ws -> D.Loop ( left - 1, compress state (schedule (Array.fromList (List.reverse ws))) ))


word : ( Int, List Int ) -> D.Decoder (D.Step ( Int, List Int ) (List Int))
word ( n, acc ) =
    if n <= 0 then
        D.succeed (D.Done acc)

    else
        D.unsignedInt32 BE |> D.map (\w -> D.Loop ( n - 1, w :: acc ))


m32 : Int -> Int
m32 x =
    and x 0xFFFFFFFF


rotr : Int -> Int -> Int
rotr n x =
    or (shiftRightZfBy n x) (m32 (shiftLeftBy (32 - n) x))


schedule : Array Int -> Array Int
schedule w16 =
    let
        go i w =
            if i >= 64 then
                w

            else
                let
                    at k =
                        Array.get k w |> Maybe.withDefault 0

                    x15 =
                        at (i - 15)

                    x2 =
                        at (i - 2)

                    s0 =
                        Bitwise.xor (Bitwise.xor (rotr 7 x15) (rotr 18 x15)) (shiftRightZfBy 3 x15)

                    s1 =
                        Bitwise.xor (Bitwise.xor (rotr 17 x2) (rotr 19 x2)) (shiftRightZfBy 10 x2)
                in
                go (i + 1) (Array.push (m32 (at (i - 16) + s0 + at (i - 7) + s1)) w)
    in
    go 16 w16


compress : State -> Array Int -> State
compress start w =
    let
        round i s =
            if i >= 64 then
                s

            else
                let
                    s1 =
                        Bitwise.xor (Bitwise.xor (rotr 6 s.e) (rotr 11 s.e)) (rotr 25 s.e)

                    ch =
                        Bitwise.xor (and s.e s.f) (and (Bitwise.xor s.e 0xFFFFFFFF) s.g)

                    t1 =
                        m32 (s.h + s1 + ch + (Array.get i roundConstants |> Maybe.withDefault 0) + (Array.get i w |> Maybe.withDefault 0))

                    s0 =
                        Bitwise.xor (Bitwise.xor (rotr 2 s.a) (rotr 13 s.a)) (rotr 22 s.a)

                    maj =
                        Bitwise.xor (Bitwise.xor (and s.a s.b) (and s.a s.c)) (and s.b s.c)

                    t2 =
                        m32 (s0 + maj)
                in
                round (i + 1) (State (m32 (t1 + t2)) s.a s.b s.c (m32 (s.d + t1)) s.e s.f s.g)

        r =
            round 0 start
    in
    State (m32 (start.a + r.a)) (m32 (start.b + r.b)) (m32 (start.c + r.c)) (m32 (start.d + r.d)) (m32 (start.e + r.e)) (m32 (start.f + r.f)) (m32 (start.g + r.g)) (m32 (start.h + r.h))


hex8 : Int -> String
hex8 n =
    String.padLeft 8 '0' (hex n)


hex : Int -> String
hex n =
    if n < 16 then
        String.fromChar (digit n)

    else
        hex (n // 16) ++ String.fromChar (digit (modBy 16 n))


digit : Int -> Char
digit d =
    String.slice d (d + 1) "0123456789abcdef" |> String.toList |> List.head |> Maybe.withDefault '0'


roundConstants : Array Int
roundConstants =
    Array.fromList
        [ 0x428A2F98, 0x71374491, 0xB5C0FBCF, 0xE9B5DBA5, 0x3956C25B, 0x59F111F1, 0x923F82A4, 0xAB1C5ED5
        , 0xD807AA98, 0x12835B01, 0x243185BE, 0x550C7DC3, 0x72BE5D74, 0x80DEB1FE, 0x9BDC06A7, 0xC19BF174
        , 0xE49B69C1, 0xEFBE4786, 0x0FC19DC6, 0x240CA1CC, 0x2DE92C6F, 0x4A7484AA, 0x5CB0A9DC, 0x76F988DA
        , 0x983E5152, 0xA831C66D, 0xB00327C8, 0xBF597FC7, 0xC6E00BF3, 0xD5A79147, 0x06CA6351, 0x14292967
        , 0x27B70A85, 0x2E1B2138, 0x4D2C6DFC, 0x53380D13, 0x650A7354, 0x766A0ABB, 0x81C2C92E, 0x92722C85
        , 0xA2BFE8A1, 0xA81A664B, 0xC24B8B70, 0xC76C51A3, 0xD192E819, 0xD6990624, 0xF40E3585, 0x106AA070
        , 0x19A4C116, 0x1E376C08, 0x2748774C, 0x34B0BCB5, 0x391C0CB3, 0x4ED8AA4A, 0x5B9CCA4F, 0x682E6FF3
        , 0x748F82EE, 0x78A5636F, 0x84C87814, 0x8CC70208, 0x90BEFFFA, 0xA4506CEB, 0xBEF9A3F7, 0xC67178F2
        ]
