module Kg.Args exposing (Args, parse, string, requiredString, int, bool, enum, enumList, stringList)

{-| Tool arguments, checked one field at a time so that a mistake gets a
message saying which argument is wrong and why, in words for the tool's
caller rather than a decoder's.
-}

import Dict exposing (Dict)
import Json.Decode as D
import Json.Encode as E


type alias Args =
    Dict String E.Value


{-| The arguments object; fails on a key the tool does not take. -}
parse : List String -> E.Value -> Result String Args
parse known value =
    case D.decodeValue (D.keyValuePairs D.value) value of
        Ok pairs ->
            case List.filter (\( k, _ ) -> not (List.member k known)) pairs of
                [] ->
                    Ok (Dict.fromList pairs)

                ( k, _ ) :: _ ->
                    Err ("unknown argument `" ++ k ++ "`; this tool takes " ++ String.join ", " (List.map (\x -> "`" ++ x ++ "`") known))

        Err _ ->
            if value == E.null then
                Ok Dict.empty

            else
                Err "the arguments must be a JSON object"


field : String -> D.Decoder a -> String -> Args -> Result String (Maybe a)
field name decoder what args =
    case Dict.get name args of
        Nothing ->
            Ok Nothing

        Just v ->
            case D.decodeValue decoder v of
                Ok a ->
                    Ok (Just a)

                Err _ ->
                    Err ("`" ++ name ++ "` must be " ++ what)


string : String -> Args -> Result String (Maybe String)
string name =
    field name D.string "a string"


requiredString : String -> Args -> Result String String
requiredString name args =
    string name args
        |> Result.andThen
            (\m ->
                case m of
                    Just s ->
                        if String.trim s == "" then
                            Err ("`" ++ name ++ "` must not be empty")

                        else
                            Ok s

                    Nothing ->
                        Err ("`" ++ name ++ "` is required")
            )


int : String -> Int -> Int -> Int -> Args -> Result String Int
int name lo hi default args =
    field name D.int ("an integer from " ++ String.fromInt lo ++ " to " ++ String.fromInt hi) args
        |> Result.andThen
            (\m ->
                case m of
                    Nothing ->
                        Ok default

                    Just n ->
                        if n < lo || n > hi then
                            Err ("`" ++ name ++ "` must be from " ++ String.fromInt lo ++ " to " ++ String.fromInt hi)

                        else
                            Ok n
            )


bool : String -> Bool -> Args -> Result String Bool
bool name default args =
    field name D.bool "true or false" args |> Result.map (Maybe.withDefault default)


enum : String -> List String -> String -> Args -> Result String String
enum name allowed default args =
    string name args
        |> Result.andThen
            (\m ->
                case m of
                    Nothing ->
                        Ok default

                    Just s ->
                        if List.member s allowed then
                            Ok s

                        else
                            Err ("`" ++ name ++ "` must be one of " ++ String.join ", " (List.map (\a -> "\"" ++ a ++ "\"") allowed))
            )


stringList : String -> Args -> Result String (List String)
stringList name args =
    field name (D.list D.string) "an array of strings" args |> Result.map (Maybe.withDefault [])


enumList : String -> List String -> Args -> Result String (List String)
enumList name allowed args =
    stringList name args
        |> Result.andThen
            (\xs ->
                case List.filter (\x -> not (List.member x allowed)) xs of
                    [] ->
                        Ok xs

                    bad :: _ ->
                        Err ("`" ++ name ++ "` has \"" ++ bad ++ "\"; allowed: " ++ String.join ", " allowed)
            )
