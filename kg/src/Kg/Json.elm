module Kg.Json exposing (Json(..), decoder, parse, firstDifference)

{-| JSON as a plain Elm value, for comparing documents: key order and
whitespace do not matter, and `==` works.
-}

import Dict exposing (Dict)
import Json.Decode as D


type Json
    = JNull
    | JBool Bool
    | JNum Float
    | JStr String
    | JArr (List Json)
    | JObj (Dict String Json)


decoder : D.Decoder Json
decoder =
    D.oneOf
        [ D.null JNull
        , D.map JBool D.bool
        , D.map JNum D.float
        , D.map JStr D.string
        , D.map JArr (D.list (D.lazy (\_ -> decoder)))
        , D.map JObj (D.dict (D.lazy (\_ -> decoder)))
        ]


parse : String -> Maybe Json
parse text =
    D.decodeString decoder text |> Result.toMaybe


{-| The path to the first place two documents differ, with both values shown
briefly; Nothing when they are equal.
-}
firstDifference : Json -> Json -> Maybe String
firstDifference a b =
    diff "" a b


diff : String -> Json -> Json -> Maybe String
diff path a b =
    if a == b then
        Nothing

    else
        case ( a, b ) of
            ( JArr xs, JArr ys ) ->
                if List.length xs /= List.length ys then
                    Just (path ++ ": " ++ String.fromInt (List.length xs) ++ " items vs " ++ String.fromInt (List.length ys) ++ firstItemDiff path xs ys)

                else
                    firstItemDiff path xs ys |> nonEmpty

            ( JObj dx, JObj dy ) ->
                let
                    keys =
                        Dict.keys (Dict.union dx dy)
                in
                keys
                    |> List.filterMap
                        (\k ->
                            case ( Dict.get k dx, Dict.get k dy ) of
                                ( Just x, Just y ) ->
                                    diff (path ++ "." ++ k) x y

                                ( Just _, Nothing ) ->
                                    Just (path ++ "." ++ k ++ ": only in the first")

                                ( Nothing, Just _ ) ->
                                    Just (path ++ "." ++ k ++ ": only in the second")

                                _ ->
                                    Nothing
                        )
                    |> List.head

            _ ->
                Just (path ++ ": " ++ brief a ++ " vs " ++ brief b)


nonEmpty : String -> Maybe String
nonEmpty s =
    if s == "" then
        Nothing

    else
        Just s


firstItemDiff : String -> List Json -> List Json -> String
firstItemDiff path xs ys =
    List.map2 Tuple.pair (List.indexedMap Tuple.pair xs) ys
        |> List.filterMap (\( ( i, x ), y ) -> diff (path ++ "[" ++ String.fromInt i ++ "]") x y)
        |> List.head
        |> Maybe.map (\s -> "; first difference at " ++ s)
        |> Maybe.withDefault ""


brief : Json -> String
brief j =
    case j of
        JNull ->
            "null"

        JBool b ->
            if b then
                "true"

            else
                "false"

        JNum n ->
            String.fromFloat n

        JStr s ->
            "\"" ++ String.left 60 s ++ "\""

        JArr xs ->
            "[" ++ (List.take 6 xs |> List.map brief |> String.join ",") ++ (if List.length xs > 6 then ",…]" else "]")

        JObj d ->
            "{" ++ String.join "," (List.take 6 (Dict.keys d)) ++ "}"
