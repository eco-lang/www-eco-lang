module Kg.Search.Bm25 exposing (Index, build, rebuild, search, codec, k1, b)

{-| A keyword index over chunks, ranked by BM25 with k1 = 1.2 and b = 0.75
(§13.2 of the plan).

    idf(t) = ln(1 + (N - n_t + 0.5) / (n_t + 0.5))
    score(c) = Σ_t idf(t) · tf(t,c)·(k1+1) / (tf(t,c) + k1·(1 - b + b·len(c)/avgLen))

-}

import Array exposing (Array)
import Dict exposing (Dict)
import Kg.Codec as C exposing (Codec)


k1 : Float
k1 =
    1.2


b : Float
b =
    0.75


type alias Index =
    { postings : Dict String (List ( Int, Int ))
    , lengths : Array Int
    , avgLen : Float
    }


{-| Chunk ids must run from 0 without gaps. -}
build : List ( Int, List String ) -> Index
build docs =
    let
        sorted =
            List.sortBy Tuple.first docs

        postings =
            List.foldl
                (\( id, toks ) acc ->
                    let
                        tf =
                            List.foldl (\t d -> Dict.update t (\v -> Just (Maybe.withDefault 0 v + 1)) d) Dict.empty toks
                    in
                    Dict.foldl (\t count a -> Dict.update t (\v -> Just (( id, count ) :: Maybe.withDefault [] v)) a) acc tf
                )
                Dict.empty
                sorted
                |> Dict.map (\_ l -> List.reverse l)

        lengths =
            Array.fromList (List.map (\( _, toks ) -> List.length toks) sorted)

        total =
            Array.foldl (+) 0 lengths

        n =
            Array.length lengths
    in
    { postings = postings
    , lengths = lengths
    , avgLen =
        if n == 0 then
            1

        else
            toFloat total / toFloat n
    }


{-| The best `limit` chunks for the query tokens, with their scores, best first.
`allowed` filters chunk ids.
-}
search : Index -> (Int -> Bool) -> Int -> List String -> List ( Int, Float )
search index allowed limit tokens =
    let
        n =
            toFloat (Array.length index.lengths)

        scores =
            tokens
                |> dedupe
                |> List.foldl
                    (\t acc ->
                        case Dict.get t index.postings of
                            Nothing ->
                                acc

                            Just plist ->
                                let
                                    nt =
                                        toFloat (List.length plist)

                                    idf =
                                        logBase e (1 + (n - nt + 0.5) / (nt + 0.5))
                                in
                                List.foldl
                                    (\( id, tf ) a ->
                                        if allowed id then
                                            let
                                                len =
                                                    toFloat (Array.get id index.lengths |> Maybe.withDefault 0)

                                                f =
                                                    toFloat tf

                                                s =
                                                    idf * f * (k1 + 1) / (f + k1 * (1 - b + b * len / index.avgLen))
                                            in
                                            Dict.update id (\v -> Just (Maybe.withDefault 0 v + s)) a

                                        else
                                            a
                                    )
                                    acc
                                    plist
                    )
                    Dict.empty
    in
    Dict.toList scores
        |> List.sortBy (\( id, s ) -> ( -s, id ))
        |> List.take limit


dedupe : List String -> List String
dedupe xs =
    List.foldl
        (\x acc ->
            if List.member x acc then
                acc

            else
                acc ++ [ x ]
        )
        []
        xs


codec : Codec Index
codec =
    C.record Index
        |> C.field .postings (C.dict C.string (C.list (C.pair C.int C.int)))
        |> C.field .lengths (C.array C.int)
        |> C.field .avgLen C.float
        |> C.finish


{-| The index for new documents, reusing an old index: `reused` maps each new
id to the old id of an identical document, if there is one; only the others
are tokenized. Gives exactly what `build` would.
-}
rebuild : Index -> Array (Maybe Int) -> List ( Int, List String ) -> Index
rebuild old reused fresh =
    let
        n =
            Array.length reused

        oldToNew : Array (Maybe Int)
        oldToNew =
            Array.foldl
                (\m ( newId, acc ) ->
                    case m of
                        Just oid ->
                            ( newId + 1, Array.set oid (Just newId) acc )

                        Nothing ->
                            ( newId + 1, acc )
                )
                ( 0, Array.repeat (Array.length old.lengths) Nothing )
                reused
                |> Tuple.second

        remapped =
            Dict.foldl
                (\t plist acc ->
                    case List.filterMap (\( oid, tf ) -> Array.get oid oldToNew |> Maybe.andThen identity |> Maybe.map (\nid -> ( nid, tf ))) plist of
                        [] ->
                            acc

                        kept ->
                            Dict.insert t kept acc
                )
                Dict.empty
                old.postings

        withFresh =
            List.foldl
                (\( id, toks ) acc ->
                    let
                        tf =
                            List.foldl (\t d -> Dict.update t (\v -> Just (Maybe.withDefault 0 v + 1)) d) Dict.empty toks
                    in
                    Dict.foldl (\t count a -> Dict.update t (\v -> Just (insertById ( id, count ) (Maybe.withDefault [] v))) a) acc tf
                )
                remapped
                fresh

        freshLengths =
            Dict.fromList (List.map (\( id, toks ) -> ( id, List.length toks )) fresh)

        lengths =
            Array.initialize n
                (\i ->
                    case Array.get i reused |> Maybe.andThen identity of
                        Just oid ->
                            Array.get oid old.lengths |> Maybe.withDefault 0

                        Nothing ->
                            Dict.get i freshLengths |> Maybe.withDefault 0
                )

        total =
            Array.foldl (+) 0 lengths
    in
    { postings = withFresh
    , lengths = lengths
    , avgLen =
        if n == 0 then
            1

        else
            toFloat total / toFloat n
    }


insertById : ( Int, Int ) -> List ( Int, Int ) -> List ( Int, Int )
insertById (( id, _ ) as item) list =
    case list of
        (( i, _ ) as x) :: rest ->
            if id < i then
                item :: list

            else
                x :: insertById item rest

        [] ->
            [ item ]
