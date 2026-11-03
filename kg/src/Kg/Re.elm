module Kg.Re exposing
    ( Regex, Match, compile, compileWith, unsafe
    , find, findAll, contains, replace, replaceWith, split, firstMatch, matches, fullMatch
    )

{-| Regular expressions, over `elm/regex`, with the few helpers kg uses:
`unsafe` for patterns written in the source, `fullMatch`, and a `Match` whose
submatches are called `groups`.
-}

import Regex


type Regex
    = Regex Regex.Regex


type alias Match =
    { index : Int, match : String, groups : List (Maybe String) }


compile : String -> Maybe Regex
compile pattern =
    Regex.fromString pattern |> Maybe.map Regex


compileWith : Regex.Options -> String -> Maybe Regex
compileWith options pattern =
    Regex.fromStringWith options pattern |> Maybe.map Regex


{-| For patterns written in the source: a bad one gives a regex that never
matches, and a test catches it.
-}
unsafe : String -> Regex
unsafe pattern =
    compile pattern |> Maybe.withDefault (Regex Regex.never)


toMatch : Regex.Match -> Match
toMatch m =
    { index = m.index, match = m.match, groups = m.submatches }


findAll : Regex -> String -> List Match
findAll (Regex re) text =
    List.map toMatch (Regex.find re text)


find : Regex -> String -> Maybe Match
find re text =
    firstMatch re text


firstMatch : Regex -> String -> Maybe Match
firstMatch (Regex re) text =
    Regex.findAtMost 1 re text |> List.head |> Maybe.map toMatch


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
replace (Regex re) by text =
    Regex.replace re (\_ -> by) text


{-| Replaces each match with what the function makes of it. -}
replaceWith : Regex -> (Match -> String) -> String -> String
replaceWith (Regex re) f text =
    Regex.replace re (toMatch >> f) text
