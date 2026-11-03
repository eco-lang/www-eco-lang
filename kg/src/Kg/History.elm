module Kg.History exposing (History, CommitInfo, empty, fromReplay, truncateTo, coChangeFrom, codec, partners, isProse)

{-| The history the knowledge graph keeps (§10.2 of the plan), by node id and
commit index. Commit indices count the first-parent commits that touch kg's
paths, oldest first.

`coChange` is derived from `edits`: two module or component nodes edited by
the same commit, for commits that touch at most 50 of them. So truncating the
history to a merge base only has to drop later commit indices.

-}

import Array exposing (Array)
import Dict exposing (Dict)
import Kg.Codec as C exposing (Codec)
import Set


type alias CommitInfo =
    { hash : String, time : Int, subject : String }


type alias History =
    { commits : Array CommitInfo
    , lives : Dict String (List Int)
    , renames : Dict String (List ( Int, String ))
    , edits : Dict String (List Int)
    , coChange : Dict ( String, String ) Int
    , lastIndexed : String
    }


empty : History
empty =
    { commits = Array.empty, lives = Dict.empty, renames = Dict.empty, edits = Dict.empty, coChange = Dict.empty, lastIndexed = "" }


{-| Lists oldest first. -}
fromReplay : Array CommitInfo -> { a | lives : Dict String (List Int), renames : Dict String (List ( Int, String )), edits : Dict String (List Int), coChange : Dict ( String, String ) Int } -> History
fromReplay commits acc =
    { commits = commits
    , lives = Dict.map (\_ l -> List.reverse l) acc.lives
    , renames = Dict.map (\_ l -> List.reverse l) acc.renames
    , edits = Dict.map (\_ l -> List.reverse l) acc.edits
    , coChange = acc.coChange
    , lastIndexed = Array.get (Array.length commits - 1) commits |> Maybe.map .hash |> Maybe.withDefault ""
    }


isProse : String -> Bool
isProse id =
    String.startsWith "plan:" id || String.startsWith "doc:" id


{-| Keeps the first `n` commits. -}
truncateTo : Int -> History -> History
truncateTo n h =
    let
        keep l =
            List.filter (\i -> i < n) l

        nonEmpty d =
            Dict.filter (\_ l -> not (List.isEmpty l)) d

        edits =
            Dict.map (\_ l -> keep l) h.edits |> nonEmpty

        commits =
            Array.slice 0 n h.commits
    in
    { commits = commits
    , lives = Dict.map (\_ l -> keep l) h.lives |> nonEmpty
    , renames = Dict.map (\_ l -> List.filter (\( i, _ ) -> i < n) l) h.renames |> nonEmpty
    , edits = edits
    , coChange = coChangeFrom edits
    , lastIndexed = Array.get (n - 1) commits |> Maybe.map .hash |> Maybe.withDefault ""
    }


coChangeFrom : Dict String (List Int) -> Dict ( String, String ) Int
coChangeFrom edits =
    let
        byCommit =
            Dict.foldl
                (\id is acc ->
                    if isProse id then
                        acc

                    else
                        List.foldl (\i a -> Dict.update i (\v -> Just (id :: Maybe.withDefault [] v)) a) acc is
                )
                Dict.empty
                edits
    in
    Dict.foldl
        (\_ ids acc ->
            if List.length ids > 50 then
                acc

            else
                let
                    sorted =
                        List.sort ids
                in
                List.foldl
                    (\a acc2 -> List.foldl (\b acc3 -> if a < b then Dict.update ( a, b ) (\v -> Just (Maybe.withDefault 0 v + 1)) acc3 else acc3) acc2 sorted)
                    acc
                    sorted
        )
        Dict.empty
        byCommit


{-| The nodes a node changes with most, with counts, most first. -}
partners : String -> History -> List ( String, Int )
partners id h =
    Dict.foldl
        (\( a, b ) n acc ->
            if a == id then
                ( b, n ) :: acc

            else if b == id then
                ( a, n ) :: acc

            else
                acc
        )
        []
        h.coChange
        |> List.sortBy (\( other, n ) -> ( -n, other ))


codec : Codec History
codec =
    C.record History
        |> C.field .commits (C.array (C.record CommitInfo |> C.field .hash C.string |> C.field .time C.int |> C.field .subject C.string |> C.finish))
        |> C.field .lives (C.dict C.string (C.list C.int))
        |> C.field .renames (C.dict C.string (C.list (C.pair C.int C.string)))
        |> C.field .edits (C.dict C.string (C.list C.int))
        |> C.field .coChange (C.dict (C.pair C.string C.string) C.int)
        |> C.field .lastIndexed C.string
        |> C.finish
