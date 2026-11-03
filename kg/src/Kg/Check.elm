module Kg.Check exposing (references, determinism, ReferenceReport)

{-| `kg check` (§19.2 of the plan).

  - **References**: stage entries that name no node and concept links to
    missing nodes fail the check; unresolved mentions in open plans and
    invariant sources that resolve to nothing are listed.
  - **Determinism**: a snapshot built at `HEAD~N` and updated commit by commit
    to `HEAD` must equal a full build at `HEAD`, apart from the build time.

-}

import Bytes exposing (Bytes)
import Dict exposing (Dict)
import Kg.Assemble as Assemble exposing (ConceptSpec)
import Kg.Codec as Codec
import Kg.Facts exposing (FileFacts(..))
import Kg.Graph as G exposing (Graph, NodeKind(..))
import Kg.History as History
import Kg.Search.Bm25 as Bm25
import Kg.Search.Chunks as Chunks
import Kg.Snapshot as Snapshot exposing (Snapshot)
import Kg.Stages as Stages
import Kg.Tools as Tools


type alias ReferenceReport =
    { failures : List String
    , listed : List String
    }


references : Graph -> Dict String FileFacts -> List ConceptSpec -> ReferenceReport
references g files concepts =
    let
        index =
            Assemble.mentionIndex g

        entries =
            Stages.stages
                |> List.filterMap
                    (\s ->
                        s.entry
                            |> Maybe.andThen
                                (\e ->
                                    if Dict.member e g.nodes then
                                        Nothing

                                    else
                                        Just ("stage `" ++ s.key ++ "`: entry `" ++ e ++ "` is not a module")
                                )
                    )

        conceptLinks =
            concepts
                |> List.concatMap
                    (\c ->
                        c.links
                            |> List.filter (\l -> not (Dict.member l.node g.nodes))
                            |> List.map (\l -> "concept `" ++ c.slug ++ "`: link to `" ++ l.node ++ "`, which is not a node")
                    )

        instructions =
            let
                n =
                    String.length (Tools.instructions g)
            in
            if n > 4000 then
                [ "the instructions are " ++ String.fromInt n ++ " characters, over 4,000" ]

            else
                []

        openPlans =
            Dict.toList files
                |> List.filterMap
                    (\( p, f ) ->
                        case f of
                            Markdown md ->
                                if String.startsWith "plans/" p && List.member (Dict.get "status" md.frontMatter |> Maybe.withDefault "") [ "partial", "not-started" ] then
                                    Just ( p, md )

                                else
                                    Nothing

                            _ ->
                                Nothing
                    )

        namespaces =
            G.nodes g
                |> List.filter (\n -> n.kind == Module)
                |> List.filterMap (\n -> String.split "." n.id |> List.head)
                |> List.foldl (\x acc -> if List.member x acc then acc else x :: acc) []

        isPath t =
            String.contains "/" t || List.any (\e -> String.endsWith e (stripLine t)) [ ".elm", ".cpp", ".hpp", ".h", ".td", ".md" ]

        worth t =
            if isPath t then
                not (String.contains "/" t) || List.any (\root -> String.startsWith root t) readRoots

            else
                String.contains "." t && List.member (String.split "." t |> List.head |> Maybe.withDefault "") namespaces

        why t =
            if isPath t then
                case Dict.get (stripLine t) index.pathSuffix of
                    Just ps ->
                        if List.length ps > 1 then
                            "is ambiguous: " ++ String.fromInt (List.length ps) ++ " files end so"

                        else
                            "resolves to nothing"

                    Nothing ->
                        "names no file"

            else
                "names no module or definition"

        unresolvedMentions =
            openPlans
                |> List.concatMap
                    (\( p, md ) ->
                        md.mentions
                            |> List.filter (\m -> worth m.target && Assemble.resolveMention index m.target == Nothing)
                            |> List.map (\m -> p ++ ":" ++ String.fromInt m.line ++ ": `" ++ m.target ++ "` " ++ why m.target)
                            |> dedupe
                    )

        invariantSources =
            G.nodes g
                |> List.filter (\n -> n.kind == Invariant)
                |> List.concatMap
                    (\n ->
                        Dict.get "source" n.props
                            |> Maybe.withDefault ""
                            |> String.words
                            |> List.concatMap (String.split "|")
                            |> List.concatMap (String.split ",")
                            |> List.map (String.trim >> trimPunctuation)
                            |> List.filter (\t -> t /= "" && worth t && Assemble.resolveMention index t == Nothing)
                            |> List.map (\t -> n.label ++ ": source `" ++ t ++ "` " ++ why t)
                    )
    in
    { failures = entries ++ conceptLinks ++ instructions
    , listed = unresolvedMentions ++ invariantSources
    }


{-| The directories kg reads; a path elsewhere (`test/`, `docs/`) is not
something kg can resolve, so it is not listed.
-}
readRoots : List String
readRoots =
    Stages.logPaths |> List.map (\p -> if String.contains "." p then p else p ++ "/")


trimPunctuation : String -> String
trimPunctuation t =
    let
        strip c =
            List.member c [ '(', ')', '`', ';', '.' ]
    in
    t |> String.toList |> dropWhileList strip |> List.reverse |> dropWhileList strip |> List.reverse |> String.fromList


dropWhileList : (a -> Bool) -> List a -> List a
dropWhileList f xs =
    case xs of
        x :: rest ->
            if f x then
                dropWhileList f rest

            else
                xs

        [] ->
            []


stripLine : String -> String
stripLine t =
    case String.split ":" t of
        p :: _ ->
            p

        [] ->
            t


dedupe : List String -> List String
dedupe xs =
    List.foldl (\x acc -> if List.member x acc then acc else acc ++ [ x ]) [] xs


{-| The parts of two snapshots the determinism check compares, encoded: equal
bytes mean equal values. The header's build time and the dirty fingerprint
are left out.
-}
determinism : Snapshot -> Snapshot -> List String
determinism a b =
    let
        same name codec get =
            if Codec.encode codec (get a) == Codec.encode codec (get b) then
                []

            else
                [ name ]

        bytesEq : Bytes -> Bytes -> Bool
        bytesEq x y =
            x == y
    in
    same "graph" G.codec .graph
        ++ same "history" History.codec .history
        ++ same "chunks" (Codec.list Chunks.codec) .chunks
        ++ same "bm25" Bm25.codec .bm25
        ++ (if a.header.commit == b.header.commit then
                []

            else
                [ "commit" ]
           )
        ++ (if bytesEq (Codec.encode (Codec.dict Codec.string Codec.string) a.base.shaOf) (Codec.encode (Codec.dict Codec.string Codec.string) b.base.shaOf) then
                []

            else
                [ "base" ]
           )
