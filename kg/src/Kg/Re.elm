module Kg.Re exposing
    ( Regex, Match, compile, compileWith, unsafe
    , find, findAll, contains, replace, replaceWith, split, firstMatch, matches, fullMatch
    )

{-| Regular expressions, over `elm/regex`.

Under eco 0.2.0 the `Match` records `Regex.find` and `Regex.replace` hand back
are built by the kernel in a field order the compiled code does not read: `index`
and `submatches` are right, `number` is garbage and reading `match` crashes (see
the dogfooding log in plans/compiler-knowledge-graph.md). This module is the one
place that knows: it wraps every pattern in a capture group, so the matched text
is the first submatch, and it never reads `match` or `number`.

Backreferences in a pattern are renumbered to allow for the extra group.

The kernel also counts `index` in code points, where `String.slice` counts
UTF-16 units, as Elm does. `findAll` converts it when the text holds a
character outside the Basic Multilingual Plane.

-}

import Array exposing (Array)
import Regex


type Regex
    = Regex Regex.Regex


type alias Match =
    { index : Int, match : String, groups : List (Maybe String) }


compile : String -> Maybe Regex
compile pattern =
    compileWith { caseInsensitive = False, multiline = False } pattern


compileWith : Regex.Options -> String -> Maybe Regex
compileWith options pattern =
    Regex.fromStringWith options ("(" ++ renumber pattern ++ ")") |> Maybe.map Regex


{-| For patterns written in the source: a bad one gives a regex that never
matches, and a test catches it.
-}
unsafe : String -> Regex
unsafe pattern =
    compile pattern |> Maybe.withDefault never_


never_ : Regex
never_ =
    Regex (Maybe.withDefault Regex.never (Regex.fromString "(?!)"))


{-| Raises each `\N` backreference by one. A backslash escaping a backslash is
skipped over.
-}
renumber : String -> String
renumber pattern =
    renumberHelp (String.toList pattern) []


renumberHelp : List Char -> List String -> String
renumberHelp chars acc =
    case chars of
        '\\' :: c :: rest ->
            if Char.isDigit c && c /= '0' then
                let
                    digits =
                        c :: takeWhile Char.isDigit rest

                    n =
                        String.toInt (String.fromList digits) |> Maybe.withDefault 0
                in
                renumberHelp (List.drop (List.length digits - 1) rest) (("\\" ++ String.fromInt (n + 1)) :: acc)

            else
                renumberHelp rest (String.fromList [ '\\', c ] :: acc)

        c :: rest ->
            renumberHelp rest (String.fromChar c :: acc)

        [] ->
            String.concat (List.reverse acc)


takeWhile : (a -> Bool) -> List a -> List a
takeWhile p xs =
    case xs of
        x :: rest ->
            if p x then
                x :: takeWhile p rest

            else
                []

        [] ->
            []


toMatch : (Int -> Int) -> Regex.Match -> Match
toMatch index m =
    case m.submatches of
        whole :: groups ->
            { index = index m.index, match = Maybe.withDefault "" whole, groups = groups }

        [] ->
            { index = index m.index, match = "", groups = [] }


{-| Maps a code point index in the text to a UTF-16 index. Older eco (and
JavaScript) step `String.foldl` through UTF-16 units, so a character outside the
Basic Multilingual Plane arrives as two surrogates; eco 0.2.0 final steps by code
point, so it arrives as one `Char` above `0xFFFF`. Both are handled.
-}
indexer : String -> (Int -> Int)
indexer text =
    if not (String.any isAstralOrSurrogate text) then
        identity

    else
        let
            step c ( u, acc ) =
                if isLowSurrogate c then
                    ( u + 1, acc )

                else if Char.toCode c > 0xFFFF then
                    ( u + 2, Array.push u acc )

                else
                    ( u + 1, Array.push u acc )

            offsets : Array Int
            offsets =
                String.foldl step ( 0, Array.empty ) text
                    |> (\( u, acc ) -> Array.push u acc)
        in
        \i -> Array.get i offsets |> Maybe.withDefault (String.length text)


isAstralOrSurrogate : Char -> Bool
isAstralOrSurrogate c =
    Char.toCode c > 0xFFFF || isSurrogate c


isSurrogate : Char -> Bool
isSurrogate c =
    let
        n =
            Char.toCode c
    in
    n >= 0xD800 && n <= 0xDFFF


isLowSurrogate : Char -> Bool
isLowSurrogate c =
    let
        n =
            Char.toCode c
    in
    n >= 0xDC00 && n <= 0xDFFF


findAll : Regex -> String -> List Match
findAll (Regex re) text =
    case Regex.find re text of
        [] ->
            []

        found ->
            List.map (toMatch (indexer text)) found


find : Regex -> String -> Maybe Match
find re text =
    firstMatch re text


firstMatch : Regex -> String -> Maybe Match
firstMatch (Regex re) text =
    Regex.findAtMost 1 re text |> List.head |> Maybe.map (toMatch (indexer text))


matches : Regex -> String -> List String
matches re text =
    List.map .match (findAll re text)


contains : Regex -> String -> Bool
contains (Regex re) text =
    Regex.contains re text


{-| Whether the whole text matches. The pattern should not be anchored itself.
-}
fullMatch : Regex -> String -> Maybe Match
fullMatch re text =
    case firstMatch re text of
        Just m ->
            if m.index == 0 && String.length m.match == String.length text then
                Just m

            else
                Nothing

        Nothing ->
            Nothing


split : Regex -> String -> List String
split (Regex re) text =
    Regex.split re text


replace : Regex -> String -> String -> String
replace re by text =
    replaceWith re (\_ -> by) text


{-| Replaces each match with what the function makes of it. -}
replaceWith : Regex -> (Match -> String) -> String -> String
replaceWith re f text =
    let
        step m ( pos, acc ) =
            ( m.index + String.length m.match
            , f m :: String.slice pos m.index text :: acc
            )

        ( end, parts ) =
            List.foldl step ( 0, [] ) (findAll re text)
    in
    String.concat (List.reverse (String.dropLeft end text :: parts))
