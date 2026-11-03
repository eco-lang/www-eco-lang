module Kg.Search.Chunks exposing (Chunk, build, withHashes, codec, kindOfNode, maxChars)

{-| The text that search reads, in chunks (§13.1 of the plan). Each chunk
belongs to one node, and its first line names what it is.

| source | one chunk per |
|---|---|
| Elm definition | definition |
| Elm module | module |
| C++ component | component, plus one per comment block over 200 characters |
| plan | section |
| design doc, THEORY.md | section |
| invariant | invariant |
| config flag | flag |
| concept | concept |

A chunk over 2,000 characters is split at paragraph boundaries; each piece
repeats the header. Ids are assigned by sorting on (node, text), so the same
facts give the same ids.

Chunks whose only text is their header (definitions and modules with no doc)
are for keyword search only: `embed` is False.

-}

import Dict exposing (Dict)
import Kg.Codec as C exposing (Codec)
import Kg.Facts exposing (FileFacts(..))
import Kg.Graph as G exposing (Graph, Node, NodeKind(..))
import Kg.Sha256 as Sha256


type alias Chunk =
    { id : Int
    , node : String
    , kind : String
    , status : Maybe String
    , stage : Maybe String
    , text : String
    , embed : Bool
    , textHash : String
    }


maxChars : Int
maxChars =
    2000


{-| The `kinds` filter of `locate`: code, plan, doc, invariant, flag, concept. -}
kindOfNode : NodeKind -> String
kindOfNode k =
    case k of
        Plan ->
            "plan"

        DocSection ->
            "doc"

        Invariant ->
            "invariant"

        Flag ->
            "flag"

        Concept ->
            "concept"

        Stage ->
            "code"

        _ ->
            "code"


build : Graph -> Dict String FileFacts -> List Chunk
build g files =
    let
        raw =
            G.nodes g |> List.concatMap (chunksOf g files)
    in
    raw
        |> List.concatMap (\c -> split c)
        |> List.sortBy (\c -> ( c.node, c.text ))
        |> List.indexedMap (\i c -> { c | id = i })


mk : Node -> String -> String -> Bool -> Chunk
mk n header body embed =
    { id = 0
    , node = n.id
    , kind = kindOfNode n.kind
    , status = Dict.get "status" n.props
    , stage = n.stage
    , text =
        if String.trim body == "" then
            header

        else
            header ++ "\n" ++ String.trim body
    , embed = embed && String.trim body /= ""
    , textHash = ""
    }


chunksOf : Graph -> Dict String FileFacts -> Node -> List Chunk
chunksOf g files n =
    let
        prop k =
            Dict.get k n.props |> Maybe.withDefault ""

        doc =
            Maybe.withDefault "" n.doc
    in
    case n.kind of
        Definition ->
            if prop "declKind" == "c++" then
                [ mk n ("c++ " ++ prop "module" ++ " " ++ n.label) "" False ]

            else
                [ mk n (prop "declKind" ++ " " ++ prop "module" ++ "." ++ n.label ++ (if prop "signature" /= "" then " : " ++ prop "signature" else "")) doc True ]

        Module ->
            [ mk n ("module " ++ n.id) doc True ]

        Component ->
            let
                comments =
                    n.paths
                        |> List.concatMap
                            (\p ->
                                case Dict.get p files of
                                    Just (CppFile c) ->
                                        List.map (\cm -> ( p, cm )) c.comments

                                    _ ->
                                        []
                            )

                header =
                    "component " ++ n.label ++ " (" ++ String.join ", " n.paths ++ ")"
            in
            mk n header "" False :: List.map (\( p, cm ) -> mk n (header ++ " " ++ p ++ ":" ++ String.fromInt cm.line) cm.text True) comments

        Plan ->
            let
                path =
                    List.head n.paths |> Maybe.withDefault ""
            in
            case Dict.get path files of
                Just (Markdown md) ->
                    md.sections
                        |> List.map
                            (\s ->
                                mk n ("plan " ++ n.label ++ " [" ++ prop "status" ++ "] > " ++ String.join " > " s.path) s.text True
                            )

                _ ->
                    [ mk n ("plan " ++ n.label ++ " [" ++ prop "status" ++ "]") doc True ]

        DocSection ->
            [ mk n ("doc " ++ prop "title" ++ " > " ++ n.label) doc True ]

        Invariant ->
            [ mk n ("invariant " ++ n.label ++ " [" ++ prop "category" ++ ", " ++ prop "status" ++ "]") doc True ]

        Flag ->
            [ mk n ("flag " ++ n.label ++ " = " ++ prop "default") doc True ]

        Concept ->
            [ mk n ("concept " ++ n.label ++ (if prop "aliases" /= "" then " (" ++ prop "aliases" ++ ")" else "")) doc True ]

        Stage ->
            [ mk n ("stage " ++ n.label ++ (if prop "entry" /= "" then " (entry " ++ prop "entry" ++ ")" else "")) doc True ]


{-| Splits at paragraph boundaries into pieces of at most `maxChars`, each
repeating the header line.
-}
split : Chunk -> List Chunk
split c =
    if String.length c.text <= maxChars then
        [ c ]

    else
        let
            ( header, body ) =
                case String.split "\n" c.text of
                    h :: rest ->
                        ( h, String.join "\n" rest )

                    [] ->
                        ( c.text, "" )

            room =
                max 200 (maxChars - String.length header - 1)

            paragraphs =
                String.split "\n\n" body |> List.concatMap (hardSplit room)

            pieces =
                List.foldl
                    (\p ( cur, acc ) ->
                        if cur == "" then
                            ( p, acc )

                        else if String.length cur + 2 + String.length p <= room then
                            ( cur ++ "\n\n" ++ p, acc )

                        else
                            ( p, cur :: acc )
                    )
                    ( "", [] )
                    paragraphs
                    |> (\( cur, acc ) -> List.reverse (cur :: acc))
                    |> List.filter (\p -> String.trim p /= "")
        in
        List.map (\p -> { c | text = header ++ "\n" ++ p }) pieces


{-| Splits a paragraph too long for one piece at the last space that fits. -}
hardSplit : Int -> String -> List String
hardSplit room p =
    if String.length p <= room then
        [ p ]

    else
        let
            head =
                String.left room p

            cut =
                case List.reverse (String.indexes " " head) of
                    i :: _ ->
                        if i > room // 2 then
                            i

                        else
                            room

                    [] ->
                        room
        in
        String.left cut p :: hardSplit room (String.trimLeft (String.dropLeft cut p))


codec : Codec Chunk
codec =
    C.record Chunk
        |> C.field .id C.int
        |> C.field .node C.string
        |> C.field .kind C.string
        |> C.field .status (C.maybe C.string)
        |> C.field .stage (C.maybe C.string)
        |> C.field .text C.string
        |> C.field .embed C.bool
        |> C.field .textHash C.string
        |> C.finish


{-| Fills in the SHA-256 of each embeddable chunk's text, reusing the hashes of
identical chunks from a previous list.
-}
withHashes : Maybe (List Chunk) -> List Chunk -> List Chunk
withHashes previous chunks =
    let
        known =
            previous
                |> Maybe.withDefault []
                |> List.foldl
                    (\c d ->
                        if c.textHash /= "" then
                            Dict.insert ( c.node, c.text ) c.textHash d

                        else
                            d
                    )
                    Dict.empty
    in
    List.map
        (\c ->
            if not c.embed then
                c

            else
                case Dict.get ( c.node, c.text ) known of
                    Just h ->
                        { c | textHash = h }

                    Nothing ->
                        { c | textHash = Sha256.sha256 c.text }
        )
        chunks
