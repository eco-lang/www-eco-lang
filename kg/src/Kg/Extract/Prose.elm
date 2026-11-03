module Kg.Extract.Prose exposing (markdown, invariants, frontMatter, isProse)

{-| Prose facts (§8.4 of the plan): plans, design docs, THEORY.md and
`design_docs/invariants.csv`.
-}

import Dict exposing (Dict)
import Kg.Facts exposing (Invariant, MarkdownFacts, Mention, Section)
import Kg.PathUtil as P
import Kg.Re as Re exposing (Regex)


{-| Only these files are prose: top-level plans, design docs (Markdown, at any
depth), the invariants and THEORY.md.
-}
isProse : String -> Bool
isProse path =
    (String.startsWith "plans/" path && String.endsWith ".md" path && List.length (String.split "/" path) == 2)
        || (String.startsWith "design_docs/" path && String.endsWith ".md" path)
        || path == "design_docs/invariants.csv"
        || path == "THEORY.md"


markdown : String -> String -> MarkdownFacts
markdown path text =
    let
        ( fm, bodyStart ) =
            frontMatter text

        bodyLines =
            String.lines text |> List.drop bodyStart

        sections =
            splitSections bodyStart bodyLines

        title =
            sections
                |> List.filterMap
                    (\s ->
                        case s.path of
                            [ t ] ->
                                Just t

                            _ ->
                                Nothing
                    )
                |> List.head
                |> Maybe.withDefault (P.stripExtension (P.basename path))
    in
    { frontMatter = fm
    , title = title
    , sections = sections
    , mentions = mentions bodyStart (String.join "\n" bodyLines)
    }


{-| The front matter, and the number of lines it takes (0 when there is none).
A `key: value` line gives one entry; a quoted value is unquoted; other lines
are added to the previous value with a space.
-}
frontMatter : String -> ( Dict String String, Int )
frontMatter text =
    if not (String.startsWith "---\n" text || String.startsWith "---\u{000D}\n" text) then
        ( Dict.empty, 0 )

    else
        let
            lines =
                String.lines text |> List.drop 1

            go ls n last acc =
                case ls of
                    l :: rest ->
                        if String.trim l == "---" then
                            ( acc, n + 2 )

                        else
                            case keyValue l of
                                Just ( k, v ) ->
                                    go rest (n + 1) (Just k) (Dict.insert k v acc)

                                Nothing ->
                                    case last of
                                        Just k ->
                                            go rest (n + 1) last (Dict.update k (Maybe.map (\v -> String.trim (v ++ " " ++ String.trim l))) acc)

                                        Nothing ->
                                            go rest (n + 1) last acc

                    [] ->
                        ( Dict.empty, 0 )
        in
        go lines 0 Nothing Dict.empty


keyValueRe : Regex
keyValueRe =
    Re.unsafe "^([A-Za-z_][\\w-]*):\\s*(.*)$"


keyValue : String -> Maybe ( String, String )
keyValue line =
    Re.firstMatch keyValueRe line
        |> Maybe.andThen
            (\m ->
                case m.groups of
                    [ Just k, v ] ->
                        Just ( k, unquote (String.trim (Maybe.withDefault "" v)) )

                    _ ->
                        Nothing
            )


unquote : String -> String
unquote v =
    if String.length v >= 2 && String.startsWith "\"" v && String.endsWith "\"" v then
        String.slice 1 -1 v |> String.replace "\\\"" "\""

    else
        v


headingRe : Regex
headingRe =
    Re.unsafe "^(#{1,6}) +(.*?)\\s*#*\\s*$"


{-| Splits at every heading outside fenced code. `startLine` counts from 1 in
the whole file.
-}
splitSections : Int -> List String -> List Section
splitSections offset lines =
    let
        flush cur acc =
            case cur of
                Just s ->
                    { s | text = String.trim (String.join "\n" (List.reverse (String.split "\n" s.text))) } :: acc

                Nothing ->
                    acc

        step ( i, line ) ( st, cur, acc ) =
            let
                fence =
                    String.startsWith "```" (String.trimLeft line) || String.startsWith "~~~" (String.trimLeft line)

                inFence =
                    if fence then
                        not st.inFence

                    else
                        st.inFence
            in
            case ( st.inFence || fence, Re.firstMatch headingRe line ) of
                ( False, Just m ) ->
                    case m.groups of
                        [ Just hashes, Just title ] ->
                            let
                                level =
                                    String.length hashes

                                stack =
                                    List.take (level - 1) st.stack ++ List.repeat (max 0 (level - 1 - List.length st.stack)) "" ++ [ title ]
                            in
                            ( { st | stack = stack, inFence = inFence }
                            , Just { path = List.filter ((/=) "") stack, startLine = offset + i + 1, text = "" }
                            , flush cur acc
                            )

                        _ ->
                            ( { st | inFence = inFence }, cur, acc )

                _ ->
                    let
                        cur2 =
                            case cur of
                                Just s ->
                                    -- lines are kept newest first, and reversed on flush
                                    Just { s | text = line ++ "\n" ++ s.text }

                                Nothing ->
                                    Just { path = [], startLine = offset + i + 1, text = line }
                    in
                    ( { st | inFence = inFence }, cur2, acc )

        ( _, last, done ) =
            List.foldl step ( { stack = [], inFence = False }, Nothing, [] ) (List.indexedMap Tuple.pair lines)
    in
    flush last done
        |> List.reverse
        |> List.filter (\s -> not (List.isEmpty s.path) || String.trim s.text /= "")


backtickRe : Regex
backtickRe =
    Re.unsafe "`([^`\\n]+)`"


moduleOrValueRe : Regex
moduleOrValueRe =
    Re.unsafe "^[A-Z][A-Za-z0-9_]*(?:\\.[A-Z][A-Za-z0-9_]*)*(?:\\.[a-z][A-Za-z0-9_]*)?$"


pathRe : Regex
pathRe =
    Re.unsafe "(?<![\\w./-])[\\w./-]+\\.(?:elm|cpp|hpp|h|td|md)(?::\\d+)?(?![\\w/-])"


mentions : Int -> String -> List Mention
mentions offset body =
    let
        lineAt index =
            offset + 1 + List.length (String.indexes "\n" (String.left index body))

        spans =
            Re.findAll backtickRe body
                |> List.filterMap
                    (\m ->
                        case m.groups of
                            [ Just inner ] ->
                                if Re.contains moduleOrValueRe inner then
                                    Just { target = inner, line = lineAt m.index }

                                else
                                    Nothing

                            _ ->
                                Nothing
                    )

        paths =
            Re.findAll pathRe body |> List.map (\m -> { target = m.match, line = lineAt m.index })
    in
    spans ++ paths


rowIdRe : Regex
rowIdRe =
    Re.unsafe "^[A-Z][A-Z0-9_]*;"


{-| `design_docs/invariants.csv`: `id;phase;category;status;description…;source`,
where the description may itself hold `;`.
-}
invariants : String -> List Invariant
invariants text =
    String.lines text
        |> List.indexedMap Tuple.pair
        |> List.filterMap
            (\( i, line ) ->
                if String.trim line == "" || String.startsWith "#" line || not (Re.contains rowIdRe line) then
                    Nothing

                else
                    case String.split ";" line of
                        id :: phase :: category :: status :: rest ->
                            case List.reverse rest of
                                source :: descRev ->
                                    Just
                                        { id = String.trim id
                                        , phase = String.trim phase
                                        , category = String.trim category
                                        , status = String.trim status
                                        , description = String.trim (String.join ";" (List.reverse descRev))
                                        , source = String.trim source
                                        , line = i + 1
                                        }

                                [] ->
                                    Nothing

                        _ ->
                            Nothing
            )
