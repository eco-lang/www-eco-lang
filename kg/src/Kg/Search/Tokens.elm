module Kg.Search.Tokens exposing (tokenize, stopWords)

{-| The tokenizer for keyword search (§13.2 of the plan): lowercase words of
letters and digits; an identifier also gives its camelCase and digit pieces,
so `aggPromote` gives `aggpromote`, `agg` and `promote`. Tokens under two
characters and a short English stop list are dropped.
-}

import Regex
import Set exposing (Set)


stopWords : Set String
stopWords =
    Set.fromList
        [ "the", "and", "of", "to", "in", "is", "it", "that", "for", "on", "as", "with", "by", "be", "this"
        , "are", "an", "or", "at", "from", "its", "was", "which", "but", "not", "if", "so", "we", "can", "has"
        ]


tokenize : String -> List String
tokenize text =
    Regex.split nonWord text
        |> List.concatMap
            (\w ->
                let
                    whole =
                        String.toLower w
                in
                if String.length w < 2 then
                    []

                else if whole == w && not (Regex.contains digit w) then
                    -- all lower case, no digits: nothing to split
                    [ whole ]

                else
                    let
                        pieces =
                            camelPieces w |> List.map String.toLower
                    in
                    if List.length pieces > 1 then
                        whole :: pieces

                    else
                        [ whole ]
            )
        |> List.filter (\t -> String.length t >= 2 && not (Set.member t stopWords))


nonWord : Regex.Regex
nonWord =
    Regex.fromString "[^A-Za-z0-9]+" |> Maybe.withDefault Regex.never


digit : Regex.Regex
digit =
    Regex.fromString "[0-9]" |> Maybe.withDefault Regex.never


type CharClass
    = Upper
    | Lower
    | Digit


classOf : Char -> CharClass
classOf c =
    if Char.isUpper c then
        Upper

    else if Char.isDigit c then
        Digit

    else
        Lower


{-| `aggPromote` → agg, Promote; `HTTPServer` → HTTP, Server; `utf8Decode` →
utf, 8, Decode.
-}
camelPieces : String -> List String
camelPieces w =
    let
        chars =
            String.toList w

        go cs cur acc =
            case cs of
                c :: rest ->
                    case cur of
                        [] ->
                            go rest [ c ] acc

                        prev :: _ ->
                            let
                                pc =
                                    classOf prev

                                cc =
                                    classOf c

                                nextLower =
                                    case rest of
                                        n :: _ ->
                                            classOf n == Lower

                                        [] ->
                                            False

                                boundary =
                                    (pc == Lower && cc == Upper)
                                        || (pc /= Digit && cc == Digit)
                                        || (pc == Digit && cc /= Digit)
                                        || (pc == Upper && cc == Upper && nextLower)
                            in
                            if boundary then
                                go rest [ c ] (String.fromList (List.reverse cur) :: acc)

                            else
                                go rest (c :: cur) acc

                [] ->
                    List.reverse (String.fromList (List.reverse cur) :: acc)
    in
    go chars [] [] |> List.filter ((/=) "")
