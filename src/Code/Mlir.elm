module Code.Mlir exposing (tokenize)

{-| A lexical highlighter for MLIR, in both the generic form
(`%1 = "eco.int.add"(%a, %b) : (i64, i64) -> i64`) and the custom form
(`func.func @main(...)`).

MLIR is regular enough at the lexical level that no parser is needed:

  - `%name` is an SSA value, `^name` a block label, `@name` a symbol and
    `!dialect.type` a dialect type.
  - A quoted string followed directly by `(` is a generic-form op name; any
    other quoted string is an attribute value.
  - A bare dotted word such as `func.func` is a custom-form op name.
  - `i64`, `f64`, `index` and the other builtin type words are types.

@docs tokenize

-}

import Code.Highlight exposing (Kind(..), Token, push, takeLine, takeQuoted, takeWhile)


{-| Split MLIR source into highlighted tokens.
-}
tokenize : String -> List Token
tokenize source =
    lex [] (String.toList source)


lex : List Token -> List Char -> List Token
lex acc chars =
    case chars of
        [] ->
            List.reverse acc

        '/' :: '/' :: _ ->
            let
                ( text, rest ) =
                    takeLine chars
            in
            lex (push Comment text acc) rest

        '"' :: rest ->
            let
                ( body, after ) =
                    takeQuoted '"' rest

                kind =
                    if List.head after == Just '(' then
                        Keyword

                    else
                        StringLit
            in
            lex (push kind ("\"" ++ body) acc) after

        '%' :: rest ->
            let
                ( kind, text, after ) =
                    sigil Variable '%' rest
            in
            lex (push kind text acc) after

        '^' :: rest ->
            let
                ( kind, text, after ) =
                    sigil Label '^' rest
            in
            lex (push kind text acc) after

        '@' :: rest ->
            let
                ( kind, text, after ) =
                    sigil Function '@' rest
            in
            lex (push kind text acc) after

        '!' :: rest ->
            let
                ( kind, text, after ) =
                    sigil Type '!' rest
            in
            lex (push kind text acc) after

        '#' :: rest ->
            let
                ( kind, text, after ) =
                    sigil Type '#' rest
            in
            lex (push kind text acc) after

        c :: rest ->
            if Char.isDigit c then
                let
                    ( text, after ) =
                        takeWhile (\ch -> Char.isAlphaNum ch || ch == '.') chars
                in
                lex (push Number text acc) after

            else if Char.isAlpha c || c == '_' then
                let
                    ( word, after ) =
                        takeWhile isIdChar chars
                in
                lex (push (classify word) word acc) after

            else
                lex (push Plain (String.fromChar c) acc) rest


{-| A sigil followed by a name, or the sigil alone as plain text when no name
follows it.
-}
sigil : Kind -> Char -> List Char -> ( Kind, String, List Char )
sigil kind c rest =
    case rest of
        '"' :: quoted ->
            let
                ( body, after ) =
                    takeQuoted '"' quoted
            in
            ( kind, String.fromList [ c, '"' ] ++ body, after )

        _ ->
            let
                ( name, after ) =
                    takeWhile isIdChar rest
            in
            if name == "" then
                ( Plain, String.fromChar c, rest )

            else
                ( kind, String.cons c name, after )


isIdChar : Char -> Bool
isIdChar c =
    Char.isAlphaNum c || c == '_' || c == '.' || c == '$'


classify : String -> Kind
classify word =
    if isBuiltinType word then
        Type

    else if List.member word [ "true", "false", "unit" ] then
        Number

    else if String.contains "." word then
        Keyword

    else
        Plain


isBuiltinType : String -> Bool
isBuiltinType word =
    List.member word builtinTypes
        || (String.startsWith "si" word && isDigits (String.dropLeft 2 word))
        || (String.startsWith "ui" word && isDigits (String.dropLeft 2 word))
        || (String.startsWith "i" word && isDigits (String.dropLeft 1 word))


builtinTypes : List String
builtinTypes =
    [ "index", "none", "f16", "bf16", "tf32", "f32", "f64", "f80", "f128", "array", "dense", "tensor", "memref", "vector", "tuple", "complex" ]


isDigits : String -> Bool
isDigits s =
    s /= "" && String.all Char.isDigit s
