module Code.Cpp exposing (tokenize)

{-| A lexical highlighter for C and C++.

It colours comments, string and character literals, numbers, preprocessor
lines, keywords and builtin types. Beyond that it uses two conventions rather
than a parser: a word followed directly by `(` is a function name, and a word
starting with a capital letter is a type, unless it is all capitals, in which
case it is a constant.

@docs tokenize

-}

import Code.Highlight exposing (Kind(..), Token, push, takeLine, takeQuoted, takeWhile)


{-| Split C or C++ source into highlighted tokens.
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

        '/' :: '*' :: rest ->
            let
                ( body, after ) =
                    takeBlockComment [] rest
            in
            lex (push Comment ("/*" ++ body) acc) after

        '"' :: rest ->
            let
                ( body, after ) =
                    takeQuoted '"' rest
            in
            lex (push StringLit (String.cons '"' body) acc) after

        '\'' :: rest ->
            let
                ( body, after ) =
                    takeQuoted '\'' rest
            in
            lex (push StringLit (String.cons '\'' body) acc) after

        '#' :: _ ->
            let
                ( text, rest ) =
                    takeLine chars
            in
            lex (push Preprocessor text acc) rest

        c :: rest ->
            if Char.isDigit c then
                let
                    ( text, after ) =
                        takeWhile (\ch -> Char.isAlphaNum ch || ch == '.' || ch == '\'') chars
                in
                lex (push Number text acc) after

            else if Char.isAlpha c || c == '_' then
                let
                    ( word, after ) =
                        takeWhile (\ch -> Char.isAlphaNum ch || ch == '_') chars
                in
                lex (push (classify word after) word acc) after

            else
                lex (push Plain (String.fromChar c) acc) rest


{-| Take the rest of a block comment, up to and including the closing `*/`.
-}
takeBlockComment : List Char -> List Char -> ( String, List Char )
takeBlockComment acc chars =
    case chars of
        '*' :: '/' :: rest ->
            ( String.fromList (List.reverse ('/' :: '*' :: acc)), rest )

        c :: rest ->
            takeBlockComment (c :: acc) rest

        [] ->
            ( String.fromList (List.reverse acc), [] )


classify : String -> List Char -> Kind
classify word after =
    if List.member word keywords then
        Keyword

    else if List.member word [ "true", "false", "nullptr", "NULL" ] then
        Number

    else if List.member word builtinTypes || String.endsWith "_t" word then
        Type

    else if List.head after == Just '(' then
        Function

    else if String.all (\c -> Char.isUpper c || Char.isDigit c || c == '_') word && String.length word > 1 then
        Number

    else if String.left 1 word |> String.any Char.isUpper then
        Type

    else
        Plain


keywords : List String
keywords =
    [ "alignas", "alignof", "auto", "break", "case", "catch", "class", "const", "constexpr", "consteval", "constinit", "const_cast", "continue", "co_await", "co_return", "co_yield", "decltype", "default", "delete", "do", "dynamic_cast", "else", "enum", "explicit", "export", "extern", "final", "for", "friend", "goto", "if", "inline", "mutable", "namespace", "new", "noexcept", "operator", "override", "private", "protected", "public", "register", "reinterpret_cast", "requires", "return", "sizeof", "static", "static_assert", "static_cast", "struct", "switch", "template", "this", "thread_local", "throw", "try", "typedef", "typeid", "typename", "union", "using", "virtual", "volatile", "while" ]


builtinTypes : List String
builtinTypes =
    [ "void", "bool", "char", "short", "int", "long", "float", "double", "signed", "unsigned", "u8", "u16", "u32", "u64", "i8", "i16", "i32", "i64", "f32", "f64" ]
