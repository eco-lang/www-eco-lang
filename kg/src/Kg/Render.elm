module Kg.Render exposing (budget, hardMax, defaultBudget, clip, lines, cutLines)

{-| Tool output: Markdown text within a budget (§14.4 of the plan). A result is
cut to 8,000 characters, about 2,000 tokens; items cut are replaced by
`… N more (raise limit)`. Nothing is ever longer than 20,000 characters.
-}


defaultBudget : Int
defaultBudget =
    8000


hardMax : Int
hardMax =
    20000


{-| The budget for a call: the default, or more when the caller raised a limit
above its default, up to the hard maximum.
-}
budget : Int -> Int -> Int
budget limit default =
    if limit > default then
        min hardMax (defaultBudget * limit // max 1 default)

    else
        defaultBudget


{-| Joins lines, stopping before the budget is reached; what is cut is counted. -}
cutLines : Int -> List String -> String
cutLines room ls =
    let
        go left xs acc =
            case xs of
                x :: rest ->
                    if String.length x + 1 > left then
                        List.reverse (("… " ++ String.fromInt (List.length xs) ++ " more (raise limit)") :: acc)

                    else
                        go (left - String.length x - 1) rest (x :: acc)

                [] ->
                    List.reverse acc
    in
    String.join "\n" (go room ls [])


lines : List String -> String
lines =
    String.join "\n"


{-| The last guard: no text over the hard maximum. -}
clip : String -> String
clip text =
    if String.length text <= hardMax then
        text

    else
        String.left (hardMax - 40) text ++ "\n… (cut at " ++ String.fromInt hardMax ++ " characters)"
