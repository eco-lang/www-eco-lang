module Kg.Atlas exposing (encode)

{-| The website's `content/atlas/history.json`, from a finished replay: the same
fields the Python `main` wrote (§17 of the plan).
-}

import Array
import Dict
import Json.Encode as E
import Kg.Replay exposing (Recorder)
import Kg.Layout exposing (Layout)
import Kg.Stages as Stages


encode : Layout -> Recorder -> E.Value
encode layout rec =
    let
        frames =
            List.reverse rec.frames

        start =
            List.head frames |> Maybe.map (\( _, t, _ ) -> t) |> Maybe.withDefault 0

        deltas times =
            List.map2 (-) times (start :: times)

        nodeCount =
            Array.length layout.uids

        ints =
            E.list E.int

        node u =
            let
                id =
                    Array.get u layout.uids |> Maybe.withDefault ""
            in
            E.object
                [ ( "lang"
                  , E.string
                        (if String.startsWith "cpp:" id then
                            "cpp"

                         else
                            "elm"
                        )
                  )
                , ( "life", ints (List.reverse (Dict.get u rec.lives |> Maybe.withDefault [])) )
                , ( "pos", E.list (\( f, x, y ) -> ints [ f, x, y ]) (List.reverse (Dict.get u rec.tracks |> Maybe.withDefault [])) )
                , ( "info"
                  , E.list
                        (\( f, ( si, nid ), ( label, path ) ) -> E.list identity [ E.int f, E.int si, E.string nid, E.string label, E.string path ])
                        (List.reverse (Dict.get u rec.infos |> Maybe.withDefault []))
                  )
                , ( "edits", ints (deltas (List.reverse (Dict.get u rec.edits |> Maybe.withDefault []))) )
                ]
    in
    E.object
        [ ( "stages"
          , E.list
                (\s -> E.object [ ( "key", E.string s.key ), ( "title", E.string s.title ), ( "blurb", E.string s.blurb ), ( "lang", E.string s.lang ), ( "row", E.int s.row ) ])
                Stages.stages
          )
        , ( "branch", E.list E.string [ Stages.branchFrom, Stages.branchTo ] )
        , ( "sections", E.list (\( k, t, _ ) -> E.object [ ( "key", E.string k ), ( "title", E.string t ) ]) Stages.cppFound )
        , ( "nodeW", E.int Kg.Layout.nodeW )
        , ( "nodeH", E.int Kg.Layout.nodeH )
        , ( "frames", E.list (\( h, t, s ) -> E.list identity [ E.string h, E.int t, E.string s ]) frames )
        , ( "nodes", E.list node (List.range 0 (nodeCount - 1)) )
        , ( "edges", E.list (\( ( a, b ), lives ) -> ints (a :: b :: List.reverse lives)) (Dict.toList rec.edgeLives) )
        , ( "stageTracks", E.object (Dict.toList rec.stageTracks |> List.map (\( k, v ) -> ( k, E.list ints (List.reverse v) ))) )
        , ( "world", E.list ints (List.reverse rec.world) )
        , ( "kernelBands"
          , E.list
                (\( f, bands ) ->
                    E.list identity
                        [ E.int f
                        , E.list
                            (\( ( title, gx, cols ), secs ) ->
                                E.list identity [ E.string title, E.int gx, E.int cols, E.list (\( t, x ) -> E.list identity [ E.string t, E.int x ]) secs ]
                            )
                            bands
                        ]
                )
                (List.reverse rec.kernelSections)
          )
        ]
