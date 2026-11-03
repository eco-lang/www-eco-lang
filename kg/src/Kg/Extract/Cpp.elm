module Kg.Extract.Cpp exposing (extract, stripCpp, withoutPreprocessor, scan, functionName, cleanHead, usesOf, comments)

{-| What a C++ file says: a port of `script/atlas-graph.py` (deleted once kg matched its output; see git history)'s `CppFile`,
`strip_cpp`, `without_preprocessor`, `scan` and `function_name`, keeping its
regular expressions (§8.2 of the plan).

Python's `re.S` has no equivalent in `elm/regex`, so `.` under it is written
`[\s\S]`. Patterns anchored at the end are run on the last 400 characters
only, which is as far as any qualifier list or name reaches.

`uses` is computed for every name in one pass, where the Python computed it on
demand: for each occurrence of a name not preceded by a word character, the
120 characters before it decide whether it is a use (and with which qualifier)
or a declaration.

-}

import Array exposing (Array)
import Dict exposing (Dict)
import Kg.Facts exposing (CppFacts, Uses)
import Kg.Re as Re exposing (Regex)
import Set exposing (Set)


extract : String -> String -> CppFacts
extract path text =
    let
        includes =
            Re.findAll includeRe text
                |> List.filterMap
                    (\m ->
                        case m.groups of
                            [ Just a, _ ] ->
                                Just a

                            [ _, Just b ] ->
                                Just b

                            _ ->
                                Nothing
                    )

        alternates =
            Re.findAll alternateRe text |> List.filterMap (\m -> List.head m.groups |> Maybe.andThen identity)
    in
    if String.endsWith ".td" path then
        { includes = includes, defs = [], classes = [], opened = [], tokens = [], uses = Dict.empty, comments = [] }

    else
        let
            code =
                stripCpp text

            s =
                scan (withoutPreprocessor code)

            occurrences =
                Re.findAll tokenRe code
        in
        { includes = includes
        , defs = s.defs ++ List.map (\a -> ( "", a )) alternates
        , classes = Set.toList s.classes
        , opened = Set.toList s.opened
        , tokens = occurrences |> List.map .match |> Set.fromList |> Set.toList
        , uses = usesOf code occurrences
        , comments = comments text
        }


includeRe : Regex
includeRe =
    Re.compileWith { caseInsensitive = False, multiline = True } "^\\s*#\\s*include\\s+\"([^\"]+)\"|^\\s*include\\s+\"([^\"]+)\""
        |> Maybe.withDefault (Re.unsafe "(?!)")


alternateRe : Regex
alternateRe =
    Re.unsafe "/alternatename:(\\w+)="


tokenRe : Regex
tokenRe =
    Re.unsafe "[A-Za-z_]\\w*"



-- STRIPPING


literalsRe : Regex
literalsRe =
    Re.unsafe
        ("//[^\\n]*|/\\*[\\s\\S]*?\\*/"
            ++ "|(?<![\\w])(?:u8|u|U|L)?R\"([^(\\s]{0,16})\\([\\s\\S]*?\\)\\1\""
            ++ "|\"(?:\\\\[\\s\\S]|[^\"\\\\\\n])*\""
            ++ "|(?<![\\w])'(?:\\\\[\\s\\S]|[^'\\\\\\n])*'"
        )


{-| Blanks comments and the insides of string and character literals, keeping
the quotes, the newlines and every offset.
-}
stripCpp : String -> String
stripCpp text =
    Re.replaceWith literalsRe (\m -> blank m.match) text


blank : String -> String
blank s =
    if String.startsWith "/" s then
        blankAll s

    else
        let
            close =
                String.right 1 s

            q =
                String.indexes close s |> List.head |> Maybe.withDefault 0
        in
        String.left (q + 1) s ++ blankAll (String.slice (q + 1) -1 s) ++ close


blankAll : String -> String
blankAll =
    String.map
        (\c ->
            if c == '\n' then
                c

            else
                ' '
        )


{-| Blanks preprocessor lines, with their continuations. -}
withoutPreprocessor : String -> String
withoutPreprocessor code =
    let
        step line ( cont, acc ) =
            if cont || String.startsWith "#" (String.trimLeft line) then
                ( String.endsWith "\\" (String.trimRight line), String.repeat (String.length line) " " :: acc )

            else
                ( False, line :: acc )
    in
    String.split "\n" code
        |> List.foldl step ( False, [] )
        |> Tuple.second
        |> List.reverse
        |> String.join "\n"



-- HEADS


keywords : Set String
keywords =
    Set.fromList
        [ "if", "for", "while", "switch", "catch", "return", "sizeof", "alignof", "decltype"
        , "static_assert", "alignas", "noexcept", "defined", "__attribute__", "else", "case"
        , "new", "delete", "throw", "co_return", "co_await", "operator", "typeid", "assert"
        ]


attrRe : Regex
attrRe =
    Re.unsafe "\\[\\[[\\s\\S]*?\\]\\]"


gnuAttrRe : Regex
gnuAttrRe =
    Re.unsafe "__attribute__\\s*\\(\\([\\s\\S]*?\\)\\)"


declspecRe : Regex
declspecRe =
    Re.unsafe "__declspec\\s*\\([^()]*\\)"


templateRe : Regex
templateRe =
    Re.unsafe "^\\s*template\\s*<[\\s\\S]*?>\\s*(?=[A-Za-z_])"


cleanHead : String -> String
cleanHead head =
    head
        |> Re.replace attrRe " "
        |> Re.replace gnuAttrRe " "
        |> Re.replace declspecRe " "
        |> replaceFirst templateRe ""
        |> String.trim


replaceFirst : Regex -> String -> String -> String
replaceFirst re by text =
    case Re.firstMatch re text of
        Just m ->
            String.left m.index text ++ by ++ String.dropLeft (m.index + String.length m.match) text

        Nothing ->
            text


{-| The last match of an end-anchored pattern, searched in the last 400
characters, with its index in the whole text.
-}
searchEnd : Regex -> String -> Maybe Re.Match
searchEnd re text =
    let
        cut =
            max 0 (String.length text - 400)

        tail =
            String.dropLeft cut text
    in
    Re.firstMatch re tail |> Maybe.map (\m -> { m | index = m.index + cut })


initCutRe : Regex
initCutRe =
    Re.unsafe "^\\s*(?:const|noexcept|override|final|\\s)*:(?!:)"


trailingReturnRe : Regex
trailingReturnRe =
    Re.unsafe "\\)\\s*->\\s*[^()]*$"


qualsRe : Regex
qualsRe =
    Re.unsafe "(?:\\s*(?:const|noexcept(?:\\s*\\([^()]*\\))?|override|final|volatile|&&|&|mutable|try))*\\s*$"


nameRe : Regex
nameRe =
    Re.unsafe "((?:[A-Za-z_]\\w*(?:<[^<>]*>)?\\s*::\\s*)*~?[A-Za-z_]\\w*)\\s*$"


operatorRe : Regex
operatorRe =
    Re.unsafe "operator\\s*\\S+"


templateArgsRe : Regex
templateArgsRe =
    Re.unsafe "<[^<>]*>"


whitespaceRe : Regex
whitespaceRe =
    Re.unsafe "\\s+"


staticRe : Regex
staticRe =
    Re.unsafe "\\bstatic\\b"


{-| The qualified name of a function definition whose head (the text before
the body's `{`) is given.
-}
functionName : String -> Maybe String
functionName head0 =
    let
        head1 =
            cutInitializers head0

        head2 =
            case searchEnd trailingReturnRe head1 of
                Just m ->
                    String.left m.index head1 ++ ")"

                Nothing ->
                    head1

        head =
            case searchEnd qualsRe head2 of
                Just m ->
                    String.left m.index head2

                Nothing ->
                    head2
    in
    if not (String.endsWith ")" head) then
        Nothing

    else
        let
            k =
                balancedTail head
        in
        if k <= 0 then
            Nothing

        else
            let
                before =
                    String.left k head
            in
            if String.contains "=" (Re.replace operatorRe "" before) then
                Nothing

            else
                case searchEnd nameRe before of
                    Nothing ->
                        Nothing

                    Just m ->
                        let
                            raw =
                                List.head m.groups |> Maybe.andThen identity |> Maybe.withDefault ""

                            name =
                                Re.replace templateArgsRe "" (Re.replace whitespaceRe "" raw)

                            simple =
                                String.split "::" name |> List.reverse |> List.head |> Maybe.withDefault name
                        in
                        if Set.member simple keywords || String.startsWith "~" simple then
                            Nothing

                        else if Re.contains staticRe (String.left m.index before) then
                            Nothing

                        else
                            Just name


{-| A constructor's member initializers: cut at the `:` after the parameters. -}
cutInitializers : String -> String
cutInitializers head =
    let
        chars =
            String.toList head

        go j depth cs =
            case cs of
                c :: rest ->
                    if c == '(' then
                        go (j + 1) (depth + 1) rest

                    else if c == ')' then
                        if depth - 1 == 0 && Re.contains initCutRe (String.dropLeft (j + 1) head) then
                            String.left (j + 1) head

                        else
                            go (j + 1) (depth - 1) rest

                    else
                        go (j + 1) depth rest

                [] ->
                    head
    in
    go 0 0 chars


balancedTail : String -> Int
balancedTail head =
    let
        go j depth cs =
            case cs of
                c :: rest ->
                    if c == ')' then
                        go (j - 1) (depth + 1) rest

                    else if c == '(' then
                        if depth - 1 == 0 then
                            j

                        else
                            go (j - 1) (depth - 1) rest

                    else
                        go (j - 1) depth rest

                [] ->
                    -1
    in
    go (String.length head - 1) 0 (List.reverse (String.toList head))



-- SCAN


type alias Scan =
    { defs : List ( String, String ), classes : Set String, opened : Set String }


namespaceRe : Regex
namespaceRe =
    Re.unsafe "(?:^|[\\s;)}])(?:inline\\s+)?namespace(?:\\s+([\\w:]+))?$"


externCRe : Regex
externCRe =
    Re.unsafe "^extern\\s*\"\\s*\"$"


classRe : Regex
classRe =
    Re.unsafe "^(?:typedef\\s+)?(class|struct|union)\\b([\\s\\S]*)$"


singleColonRe : Regex
singleColonRe =
    Re.unsafe "(?<!:):(?!:)"


alignasRe : Regex
alignasRe =
    Re.unsafe "alignas\\s*\\([^()]*\\)"


braceVarRe : Regex
braceVarRe =
    Re.unsafe "([A-Za-z_]\\w*)\\s*(?:\\[[^\\]]*\\]\\s*)*=?\\s*$"


usingNamespaceRe : Regex
usingNamespaceRe =
    Re.unsafe "^using\\s+namespace\\s+([\\w:]+)$"


declKeywordRe : Regex
declKeywordRe =
    Re.unsafe "^(using|typedef|template|friend|static_assert|class|struct|enum|union|extern|namespace)\\b"


semiVarRe : Regex
semiVarRe =
    Re.unsafe "([A-Za-z_]\\w*)\\s*(?:\\[[^\\]]*\\]\\s*)*$"


{-| What a file defines at namespace scope: `defs` are (namespace, name) for the
functions and variables it defines with external linkage; `classes` the classes
it defines; `opened` the namespaces it opens or brings in with
`using namespace`.
-}
scan : String -> Scan
scan code =
    let
        marks : Array ( Int, Char )
        marks =
            List.map (\i -> ( i, '{' )) (String.indexes "{" code)
                ++ List.map (\i -> ( i, '}' )) (String.indexes "}" code)
                ++ List.map (\i -> ( i, ';' )) (String.indexes ";" code)
                |> List.sortBy Tuple.first
                |> Array.fromList

        n =
            Array.length marks

        close : Dict Int Int
        close =
            Array.foldl
                (\( _, c ) ( k, stack, acc ) ->
                    if c == '{' then
                        ( k + 1, k :: stack, acc )

                    else if c == '}' then
                        case stack of
                            open :: rest ->
                                ( k + 1, rest, Dict.insert open k acc )

                            [] ->
                                ( k + 1, stack, acc )

                    else
                        ( k + 1, stack, acc )
                )
                ( 0, [], Dict.empty )
                marks
                |> (\( _, _, acc ) -> acc)

        closing k =
            Dict.get k close |> Maybe.withDefault (n - 1)

        markAt k =
            Array.get k marks |> Maybe.withDefault ( String.length code, ';' )

        here scope =
            List.reverse scope |> List.filterMap identity |> List.filter ((/=) "") |> String.join "::"

        inAnonymous scope =
            List.member (Just "") scope

        loop k start scope st =
            if k >= n then
                st

            else
                let
                    ( i, c ) =
                        markAt k
                in
                if c == '{' then
                    let
                        head =
                            cleanHead (String.slice start i code)
                    in
                    if countChar '(' head > countChar ')' head then
                        let
                            k2 =
                                closing k
                        in
                        loop (k2 + 1) (Tuple.first (markAt k2) + 1) scope st

                    else
                        case searchEnd namespaceRe head of
                            Just m ->
                                let
                                    name =
                                        List.head m.groups |> Maybe.andThen identity |> Maybe.withDefault ""

                                    scope2 =
                                        Just name :: scope
                                in
                                loop (k + 1) (i + 1) scope2 { st | opened = Set.insert (here scope2) st.opened }

                            Nothing ->
                                if Re.contains externCRe head then
                                    loop (k + 1) (i + 1) (Nothing :: scope) st

                                else
                                    let
                                        st2 =
                                            braceDef head scope st

                                        k2 =
                                            closing k
                                    in
                                    loop (k2 + 1) (Tuple.first (markAt k2) + 1) scope st2

                else if c == '}' then
                    loop (k + 1) (i + 1) (List.drop 1 scope) st

                else
                    let
                        stmt =
                            cleanHead (String.slice start i code)
                    in
                    loop (k + 1) (i + 1) scope (semiDef stmt scope st)

        braceDef head scope st =
            case Re.firstMatch classRe head of
                Just m ->
                    let
                        rest =
                            case m.groups of
                                [ _, Just r ] ->
                                    r

                                _ ->
                                    ""

                        firstPart =
                            Re.split singleColonRe rest |> List.head |> Maybe.withDefault ""

                        names =
                            Re.matches tokenRe (Re.replace alignasRe "" firstPart) |> List.filter ((/=) "final")
                    in
                    case List.reverse names of
                        last :: _ ->
                            { st | classes = Set.insert last st.classes }

                        [] ->
                            st

                Nothing ->
                    if not (inAnonymous scope) && not (List.any (\p -> String.startsWith p head) [ "enum", "using", "typedef" ]) then
                        case functionName head of
                            Just fn ->
                                let
                                    parts =
                                        String.split "::" fn

                                    ns =
                                        (if here scope == "" then
                                            []

                                         else
                                            [ here scope ]
                                        )
                                            ++ List.take (List.length parts - 1) parts
                                in
                                { st | defs = ( String.join "::" ns, List.reverse parts |> List.head |> Maybe.withDefault fn ) :: st.defs }

                            Nothing ->
                                if not (String.contains "(" head) && not (Re.contains staticRe head) then
                                    case searchEnd braceVarRe head of
                                        Just vm ->
                                            case List.head vm.groups |> Maybe.andThen identity of
                                                Just v ->
                                                    if not (Set.member v keywords) && List.length (String.words head) > 1 then
                                                        { st | defs = ( here scope, v ) :: st.defs }

                                                    else
                                                        st

                                                Nothing ->
                                                    st

                                        Nothing ->
                                            st

                                else
                                    st

                    else
                        st

        semiDef stmt scope st =
            case Re.firstMatch usingNamespaceRe stmt of
                Just m ->
                    case List.head m.groups |> Maybe.andThen identity of
                        Just ns ->
                            { st | opened = Set.insert (dropLeadingColons ns) st.opened }

                        Nothing ->
                            st

                Nothing ->
                    if not (inAnonymous scope) && stmt /= "" && not (Re.contains declKeywordRe stmt) && not (Re.contains staticRe stmt) then
                        let
                            lhs =
                                String.split "=" stmt |> List.head |> Maybe.withDefault ""
                        in
                        if not (String.contains "(" lhs) && List.length (String.words lhs) > 1 then
                            case searchEnd semiVarRe lhs |> Maybe.andThen (.groups >> List.head >> Maybe.andThen identity) of
                                Just v ->
                                    if Set.member v keywords then
                                        st

                                    else
                                        { st | defs = ( here scope, v ) :: st.defs }

                                Nothing ->
                                    st

                        else
                            st

                    else
                        st

        result =
            loop 0 0 [] { defs = [], classes = Set.empty, opened = Set.empty }
    in
    { result | defs = List.reverse result.defs }


dropLeadingColons : String -> String
dropLeadingColons s =
    if String.startsWith ":" s then
        dropLeadingColons (String.dropLeft 1 s)

    else
        s


countChar : Char -> String -> Int
countChar c s =
    String.foldl
        (\x n ->
            if x == c then
                n + 1

            else
                n
        )
        0
        s



-- USES


notACall : Set String
notACall =
    Set.fromList [ "return", "else", "case", "new", "delete", "throw", "co_return", "co_await", "co_yield", "do" ]


type Occurrence
    = Use String
    | Declaration
    | Skip


{-| For every name, the qualifiers it is used with and whether the file declares
it; names never used are left out.
-}
usesOf : String -> List Re.Match -> Dict String Uses
usesOf code occurrences =
    let
        step m acc =
            if m.index > 0 && isWordChar (charAt (m.index - 1) code) then
                acc

            else
                case occurrenceAt code m.index of
                    Skip ->
                        acc

                    Declaration ->
                        Dict.update m.match
                            (\u ->
                                case u of
                                    Just ( qs, _ ) ->
                                        Just ( qs, True )

                                    Nothing ->
                                        Just ( Set.empty, True )
                            )
                            acc

                    Use q ->
                        Dict.update m.match
                            (\u ->
                                case u of
                                    Just ( qs, d ) ->
                                        Just ( Set.insert q qs, d )

                                    Nothing ->
                                        Just ( Set.singleton q, False )
                            )
                            acc
    in
    List.foldl step Dict.empty occurrences
        |> Dict.toList
        |> List.filterMap
            (\( name, ( qs, d ) ) ->
                if Set.isEmpty qs then
                    Nothing

                else
                    Just ( name, { quals = Set.toList qs, declares = d } )
            )
        |> Dict.fromList


charAt : Int -> String -> Char
charAt i s =
    String.slice i (i + 1) s |> String.uncons |> Maybe.map Tuple.first |> Maybe.withDefault ' '


isWordChar : Char -> Bool
isWordChar c =
    Char.isAlphaNum c || c == '_'


isIdentStart : Char -> Bool
isIdentStart c =
    Char.isAlpha c || c == '_'


isSpace : Char -> Bool
isSpace c =
    c == ' ' || c == '\t' || c == '\n' || c == '\u{000D}' || c == '\u{000C}' || c == '\u{000B}'


{-| Python's `CppFile.uses` for one occurrence: the 120 characters before it,
right-stripped, decide.
-}
occurrenceAt : String -> Int -> Occurrence
occurrenceAt code index =
    let
        before =
            String.slice (max 0 (index - 120)) index code |> String.trimRight
    in
    if String.endsWith "." before || String.endsWith "->" before then
        Skip

    else
        let
            rev =
                List.reverse (String.toList before)
        in
        case qualifierChain rev of
            Just q ->
                Use q

            Nothing ->
                case rev of
                    c :: rest ->
                        if isWordChar c then
                            let
                                run =
                                    List.reverse (c :: takeWhile isWordChar rest)

                                ident =
                                    dropWhile (not << isIdentStart) run
                            in
                            if List.isEmpty ident then
                                Use ""

                            else if Set.member (String.fromList ident) notACall then
                                Use ""

                            else
                                Declaration

                        else if c == '*' || c == '&' then
                            case dropWhile isSpace (dropWhile (\x -> x == '*' || x == '&') rev) of
                                p :: _ ->
                                    if isWordChar p || p == '>' then
                                        Declaration

                                    else
                                        Use ""

                                [] ->
                                    Use ""

                        else if c == '>' then
                            Declaration

                        else
                            Use ""

                    [] ->
                        Use ""


{-| `((?:[A-Za-z_]\w*\s*::\s*)+)$` on the reversed text: the qualifier, with
whitespace removed and without the last `::`.
-}
qualifierChain : List Char -> Maybe String
qualifierChain rev =
    let
        segment cs =
            -- cs starts (reversed) at a `::`
            case cs of
                ':' :: ':' :: rest ->
                    let
                        afterWs =
                            dropWhile isSpace rest

                        run =
                            takeWhile isWordChar afterWs

                        forward =
                            List.reverse run

                        ident =
                            dropWhile (not << isIdentStart) forward
                    in
                    if List.isEmpty ident then
                        Nothing

                    else
                        Just
                            ( String.fromList ident
                            , if List.length ident == List.length forward then
                                Just (dropWhile isSpace (List.drop (List.length run) afterWs))

                              else
                                Nothing
                            )

                _ ->
                    Nothing

        go cs acc =
            case segment cs of
                Just ( ident, Just more ) ->
                    go more (ident :: acc)

                Just ( ident, Nothing ) ->
                    ident :: acc

                Nothing ->
                    acc
    in
    case go rev [] of
        [] ->
            Nothing

        segs ->
            Just (String.join "::" segs)


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


dropWhile : (a -> Bool) -> List a -> List a
dropWhile p xs =
    case xs of
        x :: rest ->
            if p x then
                dropWhile p rest

            else
                xs

        [] ->
            []



-- COMMENTS


commentRe : Regex
commentRe =
    Re.unsafe "/\\*[\\s\\S]*?\\*/|(?://[^\\n]*\\n\\s*)+"


{-| Comment blocks over 200 characters, with the line each starts on, for the
search chunks.
-}
comments : String -> List { line : Int, text : String }
comments text =
    Re.findAll commentRe text
        |> List.filter (\m -> String.length m.match > 200)
        |> List.map
            (\m ->
                { line = 1 + List.length (String.indexes "\n" (String.left m.index text))
                , text =
                    m.match
                        |> String.lines
                        |> List.map (String.trim >> stripCommentMarks)
                        |> String.join "\n"
                        |> String.trim
                }
            )


stripCommentMarks : String -> String
stripCommentMarks line =
    let
        drop prefix s =
            if String.startsWith prefix s then
                String.dropLeft (String.length prefix) s

            else
                s
    in
    line |> drop "///" |> drop "//" |> drop "/**" |> drop "/*" |> drop "*/" |> drop "*" |> (\s -> if String.endsWith "*/" s then String.dropRight 2 s else s) |> String.trim
