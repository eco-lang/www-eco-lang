module Kg.Embed exposing (Model, Stats, model, embed, embedWith, embedQuery, cachedVector, saveVector, available)

{-| The embedding server: Ollama's `/api/embed` (§13.3–§13.4 of the plan),
through `elm/http`, which eco runs natively.

Vectors are normalised again on arrival, whatever the server did. Each vector
is cached by (model slug, SHA-256 of the text), where the slug includes the
`dimensions` setting; a prefix the model needs is part of the text sent, not
of the key.

-}

import Bytes exposing (Bytes)
import Http
import Json.Decode as D
import Json.Encode as E
import Kg.Context exposing (Context)
import Kg.Fs as Fs
import Kg.Search.Vectors as Vectors
import Task exposing (Task)


type alias Model =
    { name : String
    , slug : String
    , dimensions : Maybe Int
    , queryPrefix : String
    , documentPrefix : String
    }


{-| The prefixes each model was trained with. -}
model : String -> Maybe Int -> Model
model name dimensions =
    let
        slug =
            String.replace ":" "-" (String.replace "/" "-" name)
                ++ (dimensions |> Maybe.map (\d -> "-d" ++ String.fromInt d) |> Maybe.withDefault "")
    in
    if String.startsWith "nomic-embed-text" name then
        { name = name, slug = slug, dimensions = dimensions, queryPrefix = "search_query: ", documentPrefix = "search_document: " }

    else if String.startsWith "snowflake-arctic-embed" name then
        { name = name, slug = slug, dimensions = dimensions, queryPrefix = "Represent this sentence for searching relevant passages: ", documentPrefix = "" }

    else
        { name = name, slug = slug, dimensions = dimensions, queryPrefix = "", documentPrefix = "" }


type alias Stats =
    { promptTokens : Int, durationNs : Int }


responseDecoder : D.Decoder ( List (List Float), Stats )
responseDecoder =
    D.map3 (\es tokens ns -> ( es, { promptTokens = tokens, durationNs = ns } ))
        (D.field "embeddings" (D.list (D.list D.float)))
        (D.oneOf [ D.field "prompt_eval_count" D.int, D.succeed 0 ])
        (D.oneOf [ D.field "total_duration" D.int, D.succeed 0 ])


{-| Embeds texts as documents, with a timeout in milliseconds. -}
embed : Context -> Model -> Float -> List String -> Task String ( List (List Float), Stats )
embed ctx m timeout texts =
    request ctx m timeout [] (List.map (\t -> m.documentPrefix ++ t) texts)


{-| As `embed`, with Ollama options (`num_gpu = 0` runs on the CPU). -}
embedWith : Context -> Model -> List ( String, E.Value ) -> List String -> Task String ( List (List Float), Stats )
embedWith ctx m opts texts =
    request ctx m 600000 opts (List.map (\t -> m.documentPrefix ++ t) texts)


embedQuery : Context -> Model -> String -> Task String (List Float)
embedQuery ctx m query =
    request ctx m 5000 [] [ m.queryPrefix ++ query ]
        |> Task.andThen
            (\( es, _ ) ->
                case es of
                    [ v ] ->
                        Task.succeed v

                    _ ->
                        Task.fail "the embedding server gave no vector"
            )


request : Context -> Model -> Float -> List ( String, E.Value ) -> List String -> Task String ( List (List Float), Stats )
request ctx m timeout opts inputs =
    Http.task
        { method = "POST"
        , headers = []
        , url = ctx.ollama ++ "/api/embed"
        , body =
            Http.jsonBody
                (E.object
                    ([ ( "model", E.string m.name ), ( "input", E.list E.string inputs ), ( "truncate", E.bool True ) ]
                        ++ (m.dimensions |> Maybe.map (\d -> [ ( "dimensions", E.int d ) ]) |> Maybe.withDefault [])
                        ++ (if List.isEmpty opts then [] else [ ( "options", E.object opts ) ])
                    )
                )
        , resolver =
            Http.stringResolver
                (\response ->
                    case response of
                        Http.GoodStatus_ _ body ->
                            case D.decodeString responseDecoder body of
                                Ok ( es, stats ) ->
                                    if List.length es == List.length inputs then
                                        Ok ( List.map Vectors.normalise es, stats )

                                    else
                                        Err "the embedding server gave the wrong number of vectors"

                                Err _ ->
                                    Err "the embedding server's answer is not what /api/embed gives"

                        Http.BadStatus_ meta body ->
                            Err ("the embedding server answered " ++ String.fromInt meta.statusCode ++ ": " ++ String.left 200 body)

                        Http.Timeout_ ->
                            Err "the embedding server timed out"

                        Http.NetworkError_ ->
                            Err ("no embedding server at " ++ ctx.ollama)

                        Http.BadUrl_ u ->
                            Err ("bad embedding server URL " ++ u)
                )
        , timeout = Just timeout
        }


{-| Whether the server answers, and has the model. -}
available : Context -> Model -> Task x Bool
available ctx m =
    request ctx m 5000 [] [ "ping" ]
        |> Task.map (\_ -> True)
        |> Task.onError (\_ -> Task.succeed False)


cachedVector : Context -> Model -> String -> Task x (Maybe (List Float))
cachedVector ctx m hash =
    Fs.readBytesMaybe (ctx.paths.vector m.slug hash)
        |> Task.map (Maybe.andThen Vectors.decodeVector)


saveVector : Context -> Model -> String -> List Float -> Task String ()
saveVector ctx m hash v =
    Fs.writeAtomic (ctx.paths.vector m.slug hash) (Vectors.encodeVector v)
