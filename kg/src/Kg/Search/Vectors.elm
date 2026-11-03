module Kg.Search.Vectors exposing
    ( Store, empty, fromList, toList, normalise, scanOnly, scanPresent, scanTop, search, searchBytes, dimensions, count, present, toBytes, fromBytes
    , encodeVector, decodeVector
    )

{-| Vectors for chunks, and the scan that ranks them against a query (§13.5 of
the plan).

The store is one block of `n × d` float32 values, with a `present` flag per
vector. The plan asked for two scans, measured against each other; under
eco 0.2.0 both were too slow or too big (see the measurements in the plan),
so a third is the one used:

  - `searchBytes` (A) decodes the float32 block with `Bytes.Decode` on every
    query: 1,089 ms for 37k × 384.
  - B decoded the block once into a flat `Array Float`: 356 ms, and about
    550 MB. It is gone.
  - `search` (C) quantizes each vector at load to int8 with a scale of its
    own, packs eight to an `Int`, and keeps the rows as lists: 68 ms, and an
    eighth of B's memory. Ranking by these dot products agrees with the
    float32 ranking except among near ties.

The top `k` are kept in a small sorted list.

-}

import Array exposing (Array)
import Bitwise
import Bytes exposing (Bytes, Endianness(..))
import Bytes.Decode as D
import Bytes.Encode as E


type alias Store =
    { d : Int
    , n : Int
    , bytes : Bytes
    , rows : List PackedRow
    , present : Array Bool
    }


{-| A vector quantized to int8 (value × scale, rounded, plus 128), eight to an
`Int`; `inverse` is 1 / scale.
-}
type alias PackedRow =
    { inverse : Float, words : List Int }


empty : Store
empty =
    { d = 0, n = 0, bytes = E.encode (E.sequence []), rows = [], present = Array.empty }


dimensions : Store -> Int
dimensions =
    .d


count : Store -> Int
count s =
    Array.foldl
        (\p acc ->
            if p then
                acc + 1

            else
                acc
        )
        0
        s.present


present : Store -> Int -> Bool
present s i =
    Array.get i s.present |> Maybe.withDefault False


normalise : List Float -> List Float
normalise v =
    let
        len =
            sqrt (List.sum (List.map (\x -> x * x) v))
    in
    if len == 0 then
        v

    else
        List.map (\x -> x / len) v


{-| A store for `n` chunks from (chunk id, vector) pairs; missing chunks get
zeros and are not present.
-}
fromList : Int -> List ( Int, List Float ) -> Int -> Store
fromList d pairs n =
    let
        byId =
            List.foldl (\( i, v ) acc -> Array.set i (Just v) acc) (Array.repeat n Nothing) pairs

        zeros =
            List.repeat d 0

        bytes =
            E.encode
                (E.sequence
                    (Array.toList byId
                        |> List.map (\m -> E.sequence (List.map (E.float32 LE) (Maybe.withDefault zeros m |> padTo d)))
                    )
                )
    in
    fromBytes d n (Array.map (\m -> m /= Nothing) byId) bytes


{-| A vector of exactly d values: cut, or padded with zeros. A vector that is
already the right length is returned as it is: under eco 0.2.0 a list made by
`List.take` makes the scan over it ten times slower (see the dogfooding log).
-}
padTo : Int -> List Float -> List Float
padTo d v =
    let
        n =
            List.length v
    in
    if n == d then
        v

    else if n > d then
        List.take d v

    else
        v ++ List.repeat (d - n) 0


toBytes : Store -> Bytes
toBytes =
    .bytes


{-| Decodes the block once and packs its rows, for `search`. -}
fromBytes : Int -> Int -> Array Bool -> Bytes -> Store
fromBytes d n presentFlags bytes =
    let
        row =
            D.loop ( d, [] )
                (\( left, acc ) ->
                    if left <= 0 then
                        D.succeed (D.Done (List.reverse acc))

                    else
                        D.float32 LE |> D.map (\x -> D.Loop ( left - 1, x :: acc ))
                )

        rows =
            D.decode
                (D.loop ( n, [] )
                    (\( left, acc ) ->
                        if left <= 0 then
                            D.succeed (D.Done (List.reverse acc))

                        else
                            row |> D.map (\r -> D.Loop ( left - 1, pack r :: acc ))
                    )
                )
                bytes
                |> Maybe.withDefault []
    in
    { d = d, n = n, bytes = bytes, rows = rows, present = presentFlags }


pack : List Float -> PackedRow
pack v =
    let
        biggest =
            List.foldl (\x m -> max m (abs x)) 0 v

        scale =
            if biggest == 0 then
                1

            else
                127 / biggest

        quantized =
            List.map (\x -> clamp 0 255 (round (x * scale) + 128)) v

        words xs =
            case xs of
                [] ->
                    []

                _ ->
                    (List.take 8 xs |> List.indexedMap (\b q -> Bitwise.shiftLeftBy (8 * b) q) |> List.sum) :: words (List.drop 8 xs)
    in
    { inverse = 1 / scale, words = words quantized }


dotPacked : List Float -> List Int -> Float -> Float
dotPacked qs ws acc =
    case ws of
        w :: wr ->
            case qs of
                q0 :: q1 :: q2 :: q3 :: q4 :: q5 :: q6 :: q7 :: qr ->
                    let
                        b k =
                            toFloat (Bitwise.and 255 (Bitwise.shiftRightZfBy (8 * k) w) - 128)
                    in
                    dotPacked qr wr (acc + q0 * b 0 + q1 * b 1 + q2 * b 2 + q3 * b 3 + q4 * b 4 + q5 * b 5 + q6 * b 6 + q7 * b 7)

                _ ->
                    -- fewer than eight left: the rest of the query, one by one
                    List.indexedMap (\k q -> q * toFloat (Bitwise.and 255 (Bitwise.shiftRightZfBy (8 * k) w) - 128)) qs
                        |> List.sum
                        |> (+) acc

        [] ->
            acc


{-| The best k so far: how many, the worst score among them, and the list,
best first. Most rows score below the worst and cost one comparison.
-}
type alias Top =
    { count : Int, worst : Float, items : List ( Float, Int ) }


emptyTop : Top
emptyTop =
    { count = 0, worst = -1.0e300, items = [] }


insertTop : Int -> ( Float, Int ) -> Top -> Top
insertTop k (( s, _ ) as item) top =
    if top.count >= k && s <= top.worst then
        top

    else
        let
            items =
                insertSorted item top.items |> List.take k

            size =
                min k (top.count + 1)
        in
        { count = size
        , worst =
            if size >= k then
                List.reverse items |> List.head |> Maybe.map Tuple.first |> Maybe.withDefault -1.0e300

            else
                -1.0e300
        , items = items
        }


insertSorted : ( Float, Int ) -> List ( Float, Int ) -> List ( Float, Int )
insertSorted (( s, i ) as item) list =
    case list of
        (( s2, i2 ) as x) :: rest ->
            if s > s2 || (s == s2 && i < i2) then
                item :: list

            else
                x :: insertSorted item rest

        [] ->
            [ item ]


{-| C: dot products against the packed rows. -}
search : Store -> (Int -> Bool) -> Int -> List Float -> List ( Int, Float )
search store allowed k query =
    let
        q =
            padTo store.d query

        step r ( i, top ) =
            if present store i && allowed i then
                ( i + 1, insertTop k ( dotPacked q r.words 0 * r.inverse, i ) top )

            else
                ( i + 1, top )
    in
    List.foldl step ( 0, emptyTop ) store.rows
        |> Tuple.second
        |> .items
        |> List.map (\( s, i ) -> ( i, s ))


{-| A: dot products decoding the block as it goes. -}
searchBytes : Store -> (Int -> Bool) -> Int -> List Float -> List ( Int, Float )
searchBytes store allowed k query =
    let
        q =
            padTo store.d query

        vector =
            D.loop ( q, 0 )
                (\( qs, acc ) ->
                    case qs of
                        x :: rest ->
                            D.float32 LE |> D.map (\v -> D.Loop ( rest, acc + x * v ))

                        [] ->
                            D.succeed (D.Done acc)
                )

        all =
            D.loop ( 0, emptyTop )
                (\( i, top ) ->
                    if i >= store.n then
                        D.succeed (D.Done top)

                    else
                        vector
                            |> D.map
                                (\s ->
                                    if present store i && allowed i then
                                        D.Loop ( i + 1, insertTop k ( s, i ) top )

                                    else
                                        D.Loop ( i + 1, top )
                                )
                )
    in
    D.decode all store.bytes |> Maybe.map .items |> Maybe.withDefault [] |> List.map (\( s, i ) -> ( i, s ))


{-| One cached vector: its dimension as a u16, then the float32 values. -}
encodeVector : List Float -> Bytes
encodeVector v =
    E.encode (E.sequence (E.unsignedInt16 LE (List.length v) :: List.map (E.float32 LE) v))


decodeVector : Bytes -> Maybe (List Float)
decodeVector bytes =
    D.decode
        (D.unsignedInt16 LE
            |> D.andThen
                (\d ->
                    D.loop ( d, [] )
                        (\( left, acc ) ->
                            if left <= 0 then
                                D.succeed (D.Done (List.reverse acc))

                            else
                                D.float32 LE |> D.map (\x -> D.Loop ( left - 1, x :: acc ))
                        )
                )
        )
        bytes


{-| Every vector in the block, in order, decoded from the float32 block. -}
toList : Store -> List (List Float)
toList store =
    let
        row =
            D.loop ( store.d, [] )
                (\( left, acc ) ->
                    if left <= 0 then
                        D.succeed (D.Done (List.reverse acc))

                    else
                        D.float32 LE |> D.map (\x -> D.Loop ( left - 1, x :: acc ))
                )
    in
    D.decode
        (D.loop ( store.n, [] )
            (\( left, acc ) ->
                if left <= 0 then
                    D.succeed (D.Done (List.reverse acc))

                else
                    row |> D.map (\r -> D.Loop ( left - 1, r :: acc ))
            )
        )
        store.bytes
        |> Maybe.withDefault []


{-| The best dot product, with nothing else: for measuring. -}
scanOnly : Store -> List Float -> Float
scanOnly store query =
    List.foldl (\r best -> max best (dotPacked query r.words 0 * r.inverse)) -1000 store.rows


scanPresent : Store -> List Float -> Float
scanPresent store query =
    List.foldl (\r ( i, best ) -> ( i + 1, if present store i then max best (dotPacked query r.words 0 * r.inverse) else best )) ( 0, -1000 ) store.rows |> Tuple.second


scanTop : Store -> List Float -> Int
scanTop store query =
    List.foldl (\r ( i, top ) -> ( i + 1, insertTop 80 ( dotPacked query r.words 0 * r.inverse, i ) top )) ( 0, emptyTop ) store.rows |> Tuple.second |> .count
