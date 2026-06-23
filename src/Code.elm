module Code exposing (codeLine)

{-| Token-level syntax highlighting for short Elm/eco code samples.

The highlighter is intentionally lightweight: it splits a line into string
literals, keywords, symbols and everything else, then wraps each token in a
span carrying a CSS class. Colours are defined by the stylesheet (see
`src/Style.elm`):

  - `eco-home-code-keyword` for `import` / `module` / `exposing`
  - `eco-home-code-symbol` for `( ) { } \ , - > =`
  - `eco-home-code-string` for quoted string literals
  - `eco-home-code-default` for everything else

@docs codeLine

-}

import Char
import Html exposing (Html)
import Html.Attributes as Attrs


{-| Render a single line of example code with token-level syntax highlighting.
-}
codeLine : String -> Html msg
codeLine line =
    Html.div [ Attrs.class "eco-home-code-line" ]
        (line |> String.toList |> tokenize |> List.map renderToken)


type Token
    = TString String
    | TWord String
    | TSymbol String
    | TOther String


type Category
    = Word
    | Sym
    | Other


categoryOf : Char -> Category
categoryOf c =
    if Char.isAlphaNum c || c == '.' || c == '_' then
        Word

    else if String.any ((==) c) "(){}\\,->=" then
        Sym

    else
        Other


tokenize : List Char -> List Token
tokenize chars =
    case chars of
        [] ->
            []

        '"' :: rest ->
            let
                ( str, after ) =
                    takeString rest
            in
            TString (String.cons '"' str) :: tokenize after

        c :: _ ->
            let
                cat =
                    categoryOf c

                ( group, after ) =
                    spanCategory cat chars
            in
            makeToken cat (String.fromList group) :: tokenize after


{-| Consume characters up to and including the closing double quote.
-}
takeString : List Char -> ( String, List Char )
takeString chars =
    case chars of
        [] ->
            ( "", [] )

        '"' :: rest ->
            ( "\"", rest )

        c :: rest ->
            let
                ( str, after ) =
                    takeString rest
            in
            ( String.cons c str, after )


{-| Consume the run of consecutive characters sharing the given category.
-}
spanCategory : Category -> List Char -> ( List Char, List Char )
spanCategory cat chars =
    case chars of
        c :: rest ->
            if c /= '"' && categoryOf c == cat then
                let
                    ( group, after ) =
                        spanCategory cat rest
                in
                ( c :: group, after )

            else
                ( [], chars )

        [] ->
            ( [], [] )


makeToken : Category -> String -> Token
makeToken cat str =
    case cat of
        Word ->
            TWord str

        Sym ->
            TSymbol str

        Other ->
            TOther str


renderToken : Token -> Html msg
renderToken token =
    case token of
        TString str ->
            Html.span [ Attrs.class "eco-home-code-string" ] [ Html.text str ]

        TSymbol str ->
            Html.span [ Attrs.class "eco-home-code-symbol" ] [ Html.text str ]

        TWord str ->
            if List.member str [ "import", "module", "exposing" ] then
                Html.span [ Attrs.class "eco-home-code-keyword" ] [ Html.text str ]

            else
                Html.span [ Attrs.class "eco-home-code-default" ] [ Html.text str ]

        TOther str ->
            Html.span [ Attrs.class "eco-home-code-default" ] [ Html.text str ]
