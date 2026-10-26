module Code.Highlight exposing
    ( Kind(..), Token
    , toBlockHtml
    , push, takeWhile, takeQuoted, takeLine
    )

{-| Shared token type and renderer for the hand-written highlighters in
`Code.Mlir` and `Code.Cpp`, for languages that `elm-syntax-highlight` does not
support.

The rendered markup matches what `SyntaxHighlight.toBlockHtml (Just 1)`
produces (`pre.elmsh > code > div.elmsh-line`), so the theme installed with
`SyntaxHighlight.useTheme` and the line-number rules in `style.css` apply
unchanged. Kinds with no colour in the theme use `eco-hl-*` classes, which are
coloured in `style.css`.

@docs Kind, Token
@docs toBlockHtml
@docs push, takeWhile, takeQuoted, takeLine

-}

import Html exposing (Html)
import Html.Attributes as Attrs


{-| What a piece of source text is, for colouring.
-}
type Kind
    = Plain
    | Comment
    | Keyword
    | StringLit
    | Number
    | Type
    | Function
    | Variable
    | Label
    | Preprocessor


{-| A piece of source text and its kind. A token may span several lines.
-}
type alias Token =
    ( Kind, String )


{-| Render tokens as a block with line numbers starting at 1.
-}
toBlockHtml : List Token -> Html msg
toBlockHtml tokens =
    tokens
        |> toLines
        |> List.indexedMap lineView
        |> Html.code []
        |> List.singleton
        |> Html.pre [ Attrs.class "elmsh" ]


lineView : Int -> List Token -> Html msg
lineView index fragments =
    Html.div
        [ Attrs.class "elmsh-line"
        , Attrs.attribute "data-elmsh-lc" (String.fromInt (index + 1))
        ]
        (fragments
            |> List.filter (\( _, text ) -> text /= "")
            |> List.map fragmentView
        )


fragmentView : Token -> Html msg
fragmentView ( kind, text ) =
    case kindClass kind of
        Nothing ->
            Html.text text

        Just class ->
            Html.span [ Attrs.class class ] [ Html.text text ]


kindClass : Kind -> Maybe String
kindClass kind =
    case kind of
        Plain ->
            Nothing

        Comment ->
            Just "elmsh-comm"

        Keyword ->
            Just "elmsh3"

        StringLit ->
            Just "elmsh2"

        Number ->
            Just "elmsh1"

        Function ->
            Just "elmsh5"

        Preprocessor ->
            Just "elmsh4"

        Type ->
            Just "eco-hl-type"

        Variable ->
            Just "eco-hl-variable"

        Label ->
            Just "eco-hl-label"


{-| Split a token stream into lines, breaking tokens that contain newlines.
-}
toLines : List Token -> List (List Token)
toLines tokens =
    let
        startLine piece ( current, done ) =
            ( [ piece ], List.reverse current :: done )

        step ( kind, text ) ( current, done ) =
            case String.split "\n" text of
                [] ->
                    ( current, done )

                first :: rest ->
                    List.foldl startLine
                        ( ( kind, first ) :: current, done )
                        (List.map (Tuple.pair kind) rest)

        ( lastLine, lines ) =
            List.foldl step ( [], [] ) tokens
    in
    List.reverse (List.reverse lastLine :: lines)



-- LEXING HELPERS


{-| Add a token to a reversed token list, merging runs of plain text.
-}
push : Kind -> String -> List Token -> List Token
push kind text acc =
    case ( kind, acc ) of
        ( Plain, ( Plain, previous ) :: more ) ->
            ( Plain, previous ++ text ) :: more

        _ ->
            ( kind, text ) :: acc


{-| Take the longest prefix whose characters all satisfy the predicate.
-}
takeWhile : (Char -> Bool) -> List Char -> ( String, List Char )
takeWhile predicate chars =
    takeWhileHelp predicate [] chars


takeWhileHelp : (Char -> Bool) -> List Char -> List Char -> ( String, List Char )
takeWhileHelp predicate acc chars =
    case chars of
        c :: rest ->
            if predicate c then
                takeWhileHelp predicate (c :: acc) rest

            else
                ( String.fromList (List.reverse acc), chars )

        [] ->
            ( String.fromList (List.reverse acc), [] )


{-| Take the rest of a quoted literal, after its opening quote, up to and
including the closing quote. Backslash escapes are skipped, and an unclosed
literal stops at the end of the line.
-}
takeQuoted : Char -> List Char -> ( String, List Char )
takeQuoted quote chars =
    takeQuotedHelp quote [] chars


takeQuotedHelp : Char -> List Char -> List Char -> ( String, List Char )
takeQuotedHelp quote acc chars =
    case chars of
        '\\' :: c :: rest ->
            takeQuotedHelp quote (c :: '\\' :: acc) rest

        c :: rest ->
            if c == quote then
                ( String.fromList (List.reverse (c :: acc)), rest )

            else if c == '\n' then
                ( String.fromList (List.reverse acc), chars )

            else
                takeQuotedHelp quote (c :: acc) rest

        [] ->
            ( String.fromList (List.reverse acc), [] )


{-| Take everything up to, but not including, the next newline.
-}
takeLine : List Char -> ( String, List Char )
takeLine =
    takeWhile ((/=) '\n')
