module Kg.Semantic exposing
    ( State, initial, load, embedBatch, save, ranksFor, ranks, pendingCount, vectorCount, describe
    , queryVector, rankWith
    )

{-| Vector search for `locate` (§13.3–§13.6 of the plan).

The vectors of a worktree's chunks are kept in one block, in the order they
were added, with the text hash of each; the block is saved next to the
snapshot (`vectors-<model>.kg`) so that it loads in one read. The shared,
content-addressed cache under `vectors/<model>/` is the source of truth: a
chunk whose hash is not in the block is looked up there before it is embedded.

Embedding runs in the background, in batches of 32, in priority order: doc
chunks of code, design docs, invariants and flags first; then open plans;
then the other plans. Until a chunk has a vector it is found by keywords only.

-}

import Array exposing (Array)
import Bytes exposing (Bytes)
import Dict exposing (Dict)
import Json.Decode as D
import Json.Encode as E
import Kg.Codec as C exposing (Codec)
import Kg.Context exposing (Context)
import Kg.Embed as Embed
import Kg.Fs as Fs
import Kg.Search.Chunks exposing (Chunk)
import Kg.Search.Vectors as Vectors
import Kg.Tools as Tools
import Set exposing (Set)
import Task exposing (Task)
import Time


type alias Block =
    { d : Int
    , hashes : Array String
    , store : Vectors.Store
    , side : List ( String, List Float )
    }


type alias State =
    { model : Maybe Embed.Model
    , block : Block
    , known : Set String
    , pending : List ( String, String )
    , up : Bool
    , embedded : Int
    , tokens : Int
    , nanos : Int
    , lastError : Maybe String
    , scanBytes : Bool
    , view : Dict String (List Int)
    }


emptyBlock : Block
emptyBlock =
    { d = 0, hashes = Array.empty, store = Vectors.empty, side = [] }


initial : State
initial =
    { model = Nothing, block = emptyBlock, known = Set.empty, pending = [], up = False, embedded = 0, tokens = 0, nanos = 0, lastError = Nothing, scanBytes = False, view = Dict.empty }


pendingCount : State -> Int
pendingCount s =
    List.length s.pending


vectorCount : State -> Int
vectorCount s =
    Set.size s.known


describe : State -> String
describe s =
    String.fromInt (vectorCount s) ++ " vectors, " ++ String.fromInt (pendingCount s) ++ " chunks to embed"
        ++ (if s.nanos > 0 then
                ", " ++ String.fromInt (round (toFloat s.tokens / (toFloat s.nanos / 1.0e9))) ++ " tokens/s, " ++ String.fromInt (round (toFloat s.embedded / (toFloat s.nanos / 1.0e9))) ++ " chunks/s"

            else
                ""
           )



-- THE BLOCK FILE


blockPath : Context -> Embed.Model -> String
blockPath ctx m =
    ctx.paths.worktree ++ "/vectors-" ++ m.slug ++ ".kg"


blockCodec : Codec ( Int, List String, Bytes )
blockCodec =
    C.withHeader "KGVEC" 1 (C.triple C.int (C.list C.string) C.bytes)


{-| Loads the block and fills it from the shared cache; what is still missing
is pending, in priority order.
-}
load : Context -> List Chunk -> Task String State
load ctx chunks =
    let
        m =
            Embed.model ctx.model ctx.dimensions

        wanted =
            chunks
                |> List.filter .embed
                |> List.sortBy (\c -> ( priority c, c.id ))
                |> List.foldl
                    (\c ( seen, acc ) ->
                        if Set.member c.textHash seen then
                            ( seen, acc )

                        else
                            ( Set.insert c.textHash seen, ( c.textHash, c.text ) :: acc )
                    )
                    ( Set.empty, [] )
                |> Tuple.second
                |> List.reverse
    in
    Fs.readBytesMaybe (blockPath ctx m)
        |> Task.map
            (\bytes ->
                case bytes |> Maybe.andThen (C.decode blockCodec) of
                    Just ( d, hashes, block ) ->
                        { emptyBlock | d = d, hashes = Array.fromList hashes, store = Vectors.fromBytes d (List.length hashes) (Array.repeat (List.length hashes) True) block }

                    Nothing ->
                        emptyBlock
            )
        |> Task.andThen
            (\block ->
                let
                    inBlock =
                        Array.foldl Set.insert Set.empty block.hashes

                    missing =
                        List.filter (\( h, _ ) -> not (Set.member h inBlock)) wanted
                in
                missing
                    |> List.map (\( h, t ) -> Embed.cachedVector ctx m h |> Task.map (\v -> ( h, t, v )))
                    |> sequenceChunked 500
                    |> Task.map
                        (\found ->
                            let
                                side =
                                    List.filterMap (\( h, _, v ) -> Maybe.map (\x -> ( h, x )) v) found

                                pending =
                                    List.filterMap
                                        (\( h, t, v ) ->
                                            case v of
                                                Just _ ->
                                                    Nothing

                                                Nothing ->
                                                    Just ( h, t )
                                        )
                                        found

                                d =
                                    if block.d > 0 then
                                        block.d

                                    else
                                        List.head side |> Maybe.map (Tuple.second >> List.length) |> Maybe.withDefault 0
                            in
                            { initial
                                | model = Just m
                                , scanBytes = ctx.vars |> Dict.get "ECO_KG_SCAN" |> (==) (Just "bytes")
                                , view = chunkMap chunks
                                , block = { block | d = d, side = side }
                                , known = Set.union inBlock (Set.fromList (List.map Tuple.first side))
                                , pending = pending
                            }
                        )
            )
        |> Task.andThen (\s -> Embed.available ctx m |> Task.map (\up -> { s | up = up }))


{-| Code docs, design docs, invariants and flags first; open plans next; the
rest of the plans last.
-}
priority : Chunk -> Int
priority c =
    if c.kind == "plan" then
        if List.member (Maybe.withDefault "" c.status) [ "partial", "not-started" ] then
            2

        else
            3

    else
        1


sequenceChunked : Int -> List (Task x a) -> Task x (List a)
sequenceChunked n tasks =
    if List.length tasks <= n then
        Task.sequence tasks

    else
        Task.sequence (List.take n tasks)
            |> Task.andThen (\first -> sequenceChunked n (List.drop n tasks) |> Task.map (\rest -> first ++ rest))


{-| Embeds the next 32 pending chunks and caches their vectors. -}
embedBatch : Context -> State -> Task String State
embedBatch ctx s =
    case ( s.model, s.pending ) of
        ( Just m, _ :: _ ) ->
            let
                batch =
                    List.take 32 s.pending
            in
            Embed.embed ctx m 120000 (List.map Tuple.second batch)
                |> Task.andThen
                    (\( vectors, stats ) ->
                        List.map2 (\( h, _ ) v -> Embed.saveVector ctx m h v |> Task.map (\_ -> ( h, v ))) batch vectors
                            |> Task.sequence
                            |> Task.map
                                (\added ->
                                    let
                                        block =
                                            s.block

                                        d =
                                            if block.d > 0 then
                                                block.d

                                            else
                                                List.head added |> Maybe.map (Tuple.second >> List.length) |> Maybe.withDefault 0
                                    in
                                    { s
                                        | block = { block | d = d, side = block.side ++ added }
                                        , known = List.foldl (\( h, _ ) k -> Set.insert h k) s.known added
                                        , pending = List.drop 32 s.pending
                                        , up = True
                                        , embedded = s.embedded + List.length added
                                        , tokens = s.tokens + stats.promptTokens
                                        , nanos = s.nanos + stats.durationNs
                                        , lastError = Nothing
                                    }
                                )
                    )
                |> Task.onError (\e -> Task.succeed { s | up = False, lastError = Just e })

        _ ->
            Task.succeed s


{-| Folds the side list into the block and writes it. -}
save : Context -> State -> Task String State
save ctx s =
    case s.model of
        Nothing ->
            Task.succeed s

        Just m ->
            let
                merged =
                    merge s.block
            in
            Fs.writeAtomic (blockPath ctx m) (C.encode blockCodec ( merged.d, Array.toList merged.hashes, Vectors.toBytes merged.store ))
                |> Task.map (\_ -> { s | block = merged })


merge : Block -> Block
merge block =
    if List.isEmpty block.side then
        block

    else
        let
            old =
                Array.toList block.hashes
                    |> List.indexedMap (\i h -> ( i, h ))

            oldVectors =
                Vectors.toList block.store

            all =
                List.map2 (\( _, h ) v -> ( h, v )) old oldVectors ++ block.side

            n =
                List.length all
        in
        { d = block.d
        , hashes = Array.fromList (List.map Tuple.first all)
        , store = Vectors.fromList block.d (List.indexedMap (\i ( _, v ) -> ( i, v )) all) n
        , side = []
        }



-- SEARCH


{-| The chunk ids of a view ranked by the query vector, best first, at most 50. -}
ranks : State -> List Chunk -> List Float -> List Int
ranks s chunks q =
    rankWith s (chunkMap chunks) q


{-| Text hash → the chunk ids of a view with that text. Made once per view. -}
chunkMap : List Chunk -> Dict String (List Int)
chunkMap chunks =
    List.foldl
        (\c d ->
            if c.embed then
                Dict.update c.textHash (\v -> Just (c.id :: Maybe.withDefault [] v)) d

            else
                d
        )
        Dict.empty
        chunks


rankWith : State -> Dict String (List Int) -> List Float -> List Int
rankWith s byHash q =
    let
        fromBlock =
            (if s.scanBytes then
                Vectors.searchBytes s.block.store (\_ -> True) 80 q

             else
                Vectors.search s.block.store (\_ -> True) 80 q
            )
                |> List.filterMap (\( i, score ) -> Array.get i s.block.hashes |> Maybe.map (\h -> ( h, score )))

        fromSide =
            s.block.side |> List.map (\( h, v ) -> ( h, List.sum (List.map2 (*) q v) ))
    in
    (fromBlock ++ fromSide)
        |> List.sortBy (\( h, score ) -> ( -score, h ))
        |> List.concatMap (\( h, _ ) -> Dict.get h byHash |> Maybe.withDefault [] |> List.sort)
        |> List.take 50


{-| For `locate`, when vectors and the server are there: the query embedded,
and the chunks ranked by it. Otherwise nothing, and `locate` is keyword-only.
-}
ranksFor : Context -> State -> Tools.View -> String -> E.Value -> Task x (List Int)
ranksFor ctx s view name arguments =
    case ( name, s.model, Set.isEmpty s.known ) of
        ( "locate", Just m, False ) ->
            case D.decodeValue (D.field "query" D.string) arguments of
                Ok query ->
                    Embed.embedQuery ctx m query
                        |> Task.map (rankWith s s.view)
                        |> Task.onError (\_ -> Task.succeed [])

                Err _ ->
                    Task.succeed []

        _ ->
            Task.succeed []


{-| The query's vector, for timing the parts of a vector search. -}
queryVector : Context -> State -> String -> Task String (List Float)
queryVector ctx s query =
    case s.model of
        Just m ->
            Embed.embedQuery ctx m query

        Nothing ->
            Task.fail "no model"
