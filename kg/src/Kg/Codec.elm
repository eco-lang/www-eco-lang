module Kg.Codec exposing
    ( Codec, encode, decode, encoder, decoder
    , int, float, bool, string, bytes, list, array, dict, set, maybe, pair, triple, map, lazy, fixed, oneOf
    , record, field, finish
    , header, withHeader
    , Variant, variant0, variant1, variant2, variant3, variant4, variants
    )

{-| Binary codecs for everything kg stores, over `elm/bytes`.

The format: an `Int` is a signed 64-bit integer written as two 32-bit
little-endian halves; a `Float` is a 64-bit float; a `String` is its UTF-8
length as a `u32` then its bytes; a list is its length as a `u32` then its
items; a dict is a list of pairs in key order. A union is a `u8` tag then the
fields of that variant.

A codec pairs the encoder and the decoder so they cannot drift apart, and the
tests check `decode (encode x) == x` for every stored type.

-}

import Array exposing (Array)
import Bytes exposing (Bytes, Endianness(..))
import Bytes.Decode as D
import Bytes.Encode as E
import Dict exposing (Dict)
import Set exposing (Set)


type alias Codec a =
    { enc : a -> E.Encoder, dec : D.Decoder a }


encoder : Codec a -> a -> E.Encoder
encoder =
    .enc


decoder : Codec a -> D.Decoder a
decoder =
    .dec


encode : Codec a -> a -> Bytes
encode c a =
    E.encode (c.enc a)


decode : Codec a -> Bytes -> Maybe a
decode c input =
    D.decode c.dec input



-- PRIMITIVES


int : Codec Int
int =
    { enc =
        \n ->
            let
                lo =
                    modBy 0x0000000100000000 n

                hi =
                    (n - lo) // 0x0000000100000000
            in
            E.sequence [ E.unsignedInt32 LE lo, E.signedInt32 LE hi ]
    , dec =
        D.map2 (\lo hi -> hi * 0x0000000100000000 + lo) (D.unsignedInt32 LE) (D.signedInt32 LE)
    }


float : Codec Float
float =
    { enc = E.float64 LE, dec = D.float64 LE }


bool : Codec Bool
bool =
    { enc =
        \b ->
            E.unsignedInt8
                (if b then
                    1

                 else
                    0
                )
    , dec = D.map (\n -> n /= 0) D.unsignedInt8
    }


string : Codec String
string =
    { enc = \s -> E.sequence [ E.unsignedInt32 LE (E.getStringWidth s), E.string s ]
    , dec = D.unsignedInt32 LE |> D.andThen D.string
    }


{-| Raw bytes: the length as a `u32`, then the bytes. -}
bytes : Codec Bytes
bytes =
    { enc = \b -> E.sequence [ E.unsignedInt32 LE (Bytes.width b), E.bytes b ]
    , dec = D.unsignedInt32 LE |> D.andThen D.bytes
    }


fixed : a -> Codec a
fixed a =
    { enc = \_ -> E.sequence [], dec = D.succeed a }



-- CONTAINERS


list : Codec a -> Codec (List a)
list c =
    { enc = \xs -> E.sequence (E.unsignedInt32 LE (List.length xs) :: List.map c.enc xs)
    , dec =
        D.unsignedInt32 LE
            |> D.andThen
                (\n ->
                    D.loop ( n, [] )
                        (\( left, acc ) ->
                            if left <= 0 then
                                D.succeed (D.Done (List.reverse acc))

                            else
                                D.map (\x -> D.Loop ( left - 1, x :: acc )) c.dec
                        )
                )
    }


array : Codec a -> Codec (Array a)
array c =
    map Array.fromList Array.toList (list c)


dict : Codec comparable -> Codec v -> Codec (Dict comparable v)
dict k v =
    map Dict.fromList Dict.toList (list (pair k v))


set : Codec comparable -> Codec (Set comparable)
set c =
    map Set.fromList Set.toList (list c)


maybe : Codec a -> Codec (Maybe a)
maybe c =
    { enc =
        \m ->
            case m of
                Nothing ->
                    E.unsignedInt8 0

                Just a ->
                    E.sequence [ E.unsignedInt8 1, c.enc a ]
    , dec =
        D.unsignedInt8
            |> D.andThen
                (\t ->
                    if t == 0 then
                        D.succeed Nothing

                    else
                        D.map Just c.dec
                )
    }


pair : Codec a -> Codec b -> Codec ( a, b )
pair a b =
    { enc = \( x, y ) -> E.sequence [ a.enc x, b.enc y ]
    , dec = D.map2 Tuple.pair a.dec b.dec
    }


triple : Codec a -> Codec b -> Codec c -> Codec ( a, b, c )
triple a b c =
    { enc = \( x, y, z ) -> E.sequence [ a.enc x, b.enc y, c.enc z ]
    , dec = D.map3 (\x y z -> ( x, y, z )) a.dec b.dec c.dec
    }


map : (a -> b) -> (b -> a) -> Codec a -> Codec b
map to from c =
    { enc = \b -> c.enc (from b), dec = D.map to c.dec }


lazy : (() -> Codec a) -> Codec a
lazy f =
    { enc = \a -> (f ()).enc a
    , dec = D.succeed () |> D.andThen (\_ -> (f ()).dec)
    }


{-| Tries nothing: kept for symmetry. A union is written with `variants`. -}
oneOf : List (Codec a) -> Codec a
oneOf cs =
    case cs of
        c :: _ ->
            c

        [] ->
            { enc = \_ -> E.sequence [], dec = D.fail }



-- RECORDS


{-| A record codec, built field by field:

    record Point
        |> field .x int
        |> field .y int
        |> finish

-}
type alias RecordBuilder r a =
    { enc : r -> List E.Encoder, dec : D.Decoder a }


record : a -> RecordBuilder r a
record ctor =
    { enc = \_ -> [], dec = D.succeed ctor }


field : (r -> f) -> Codec f -> RecordBuilder r (f -> b) -> RecordBuilder r b
field get c builder =
    { enc = \r -> c.enc (get r) :: builder.enc r
    , dec = D.map2 (\f x -> f x) builder.dec c.dec
    }


finish : RecordBuilder r r -> Codec r
finish builder =
    { enc = \r -> E.sequence (List.reverse (builder.enc r)), dec = builder.dec }



-- UNIONS


{-| One variant of a union: how to encode a value if it is this variant, and
how to decode its fields.
-}
type alias Variant a =
    { match : a -> Maybe E.Encoder, dec : D.Decoder a }


variant0 : a -> (a -> Bool) -> Variant a
variant0 value is =
    { match =
        \a ->
            if is a then
                Just (E.sequence [])

            else
                Nothing
    , dec = D.succeed value
    }


variant1 : (x -> a) -> (a -> Maybe x) -> Codec x -> Variant a
variant1 ctor get cx =
    { match = \a -> Maybe.map cx.enc (get a)
    , dec = D.map ctor cx.dec
    }


variant2 : (x -> y -> a) -> (a -> Maybe ( x, y )) -> Codec x -> Codec y -> Variant a
variant2 ctor get cx cy =
    { match = \a -> Maybe.map (\( x, y ) -> E.sequence [ cx.enc x, cy.enc y ]) (get a)
    , dec = D.map2 ctor cx.dec cy.dec
    }


variant3 : (x -> y -> z -> a) -> (a -> Maybe ( x, y, z )) -> Codec x -> Codec y -> Codec z -> Variant a
variant3 ctor get cx cy cz =
    { match = \a -> Maybe.map (\( x, y, z ) -> E.sequence [ cx.enc x, cy.enc y, cz.enc z ]) (get a)
    , dec = D.map3 ctor cx.dec cy.dec cz.dec
    }


variant4 : (w -> x -> y -> z -> a) -> (a -> Maybe ( ( w, x ), ( y, z ) )) -> Codec w -> Codec x -> Codec y -> Codec z -> Variant a
variant4 ctor get cw cx cy cz =
    { match = \a -> Maybe.map (\( ( w, x ), ( y, z ) ) -> E.sequence [ cw.enc w, cx.enc x, cy.enc y, cz.enc z ]) (get a)
    , dec = D.map4 ctor cw.dec cx.dec cy.dec cz.dec
    }


{-| A union from its variants, tagged by their position in the list. -}
variants : List (Variant a) -> Codec a
variants vs =
    let
        indexed =
            List.indexedMap Tuple.pair vs

        enc a =
            firstJust (\( i, v ) -> Maybe.map (\e -> E.sequence [ E.unsignedInt8 i, e ]) (v.match a)) indexed
                |> Maybe.withDefault (E.unsignedInt8 255)

        dec =
            D.unsignedInt8
                |> D.andThen
                    (\t ->
                        case List.drop t vs of
                            v :: _ ->
                                v.dec

                            [] ->
                                D.fail
                    )
    in
    { enc = enc, dec = dec }


firstJust : (a -> Maybe b) -> List a -> Maybe b
firstJust f xs =
    case xs of
        x :: rest ->
            case f x of
                Just b ->
                    Just b

                Nothing ->
                    firstJust f rest

        [] ->
            Nothing



-- HEADERS


{-| A file header: a magic string and a format version. -}
header : String -> Int -> Codec ()
header magic version =
    { enc = \_ -> E.sequence [ E.string magic, E.unsignedInt16 LE version ]
    , dec =
        D.string (String.length magic)
            |> D.andThen
                (\m ->
                    if m /= magic then
                        D.fail

                    else
                        D.unsignedInt16 LE
                            |> D.andThen
                                (\v ->
                                    if v /= version then
                                        D.fail

                                    else
                                        D.succeed ()
                                )
                )
    }


{-| A codec whose bytes start with a header; a file with another magic or
version does not decode.
-}
withHeader : String -> Int -> Codec a -> Codec a
withHeader magic version c =
    map Tuple.second (\a -> ( (), a )) (pair (header magic version) c)
