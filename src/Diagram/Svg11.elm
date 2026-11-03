module Diagram.Svg11 exposing (document)

{-| Write a diagram as a standalone SVG 1.1 document, for drawing programs such as Inkscape and Illustrator.

The document has no CSS, no scripts and no `data-*` attributes: every visual property is a presentation attribute, the
same ones `Diagram.Svg` draws with in a browser, so the file looks as the page does. Groups that carry a key become
`<g>` elements with an `id` made from the key, so drawing programs can name them.

Text is kept as text, so the fonts it names must be installed for a drawing program to show it as the page does.

@docs document

-}

import BoundingBox2d
import Diagram exposing (Diagram)
import Diagram.Camera exposing (ScreenCoordinates)
import Diagram.Svg.Node as Node exposing (Node(..))
import Dict exposing (Dict)
import Pixels


{-| A diagram as an SVG 1.1 document, its size the size of the diagram's bounds. Draw the diagram with
`Diagram.Camera.project Diagram.Camera.identity` for a file at the diagram's own size.
-}
document : { title : String, description : String } -> Diagram ScreenCoordinates -> String
document meta d =
    let
        e =
            BoundingBox2d.extrema d.bounds

        minX =
            Pixels.toFloat e.minX

        minY =
            Pixels.toFloat e.minY

        w =
            Pixels.toFloat e.maxX - minX

        h =
            Pixels.toFloat e.maxY - minY

        ( body, _ ) =
            List.foldl
                (\el ( acc, ids ) ->
                    let
                        ( s, ids2 ) =
                            write ids (Node.fromElement el)
                    in
                    ( s :: acc, ids2 )
                )
                ( [], Dict.empty )
                d.elements
    in
    String.join "\n"
        [ "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>"
        , "<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\" \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">"
        , "<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\""
            ++ attrs
                [ ( "width", Node.number w )
                , ( "height", Node.number h )
                , ( "viewBox", String.join " " (List.map Node.number [ minX, minY, w, h ]) )
                ]
            ++ ">"
        , "<title>" ++ escape meta.title ++ "</title>"
        , "<desc>" ++ escape meta.description ++ "</desc>"
        , String.join "\n" (List.reverse body)
        , "</svg>"
        , ""
        ]


{-| Write a node, keeping count of the ids used so far so that every id in the document is different.
-}
write : Dict String Int -> Node -> ( String, Dict String Int )
write ids node =
    case node of
        Node name attributes [] ->
            ( "<" ++ name ++ attrs attributes ++ "/>", ids )

        Node name attributes children ->
            let
                ( inner, ids2 ) =
                    writeAll ids children
            in
            ( "<" ++ name ++ attrs attributes ++ ">" ++ inner ++ "</" ++ name ++ ">", ids2 )

        Content s ->
            ( escape s, ids )

        Group g presentation children ->
            let
                ( idAttr, ids2 ) =
                    case g.key of
                        Just key ->
                            let
                                base =
                                    identifier key

                                n =
                                    Dict.get base ids |> Maybe.withDefault 0
                            in
                            ( [ ( "id"
                                , if n == 0 then
                                    base

                                  else
                                    base ++ "-" ++ String.fromInt (n + 1)
                                )
                              ]
                            , Dict.insert base (n + 1) ids
                            )

                        Nothing ->
                            ( [], ids )

                ( inner, ids3 ) =
                    writeAll ids2 children
            in
            ( "<g" ++ attrs (idAttr ++ presentation) ++ ">\n" ++ inner ++ "\n</g>", ids3 )


writeAll : Dict String Int -> List Node -> ( String, Dict String Int )
writeAll ids children =
    List.foldl
        (\child ( acc, ids2 ) ->
            let
                ( s, ids3 ) =
                    write ids2 child
            in
            ( s :: acc, ids3 )
        )
        ( [], ids )
        children
        |> Tuple.mapFirst (List.reverse >> String.join "\n")


attrs : List ( String, String ) -> String
attrs =
    List.map (\( k, v ) -> " " ++ k ++ "=\"" ++ escape v ++ "\"") >> String.concat


{-| An XML name made from a key: letters, digits, `-`, `_` and `.` are kept and anything else becomes `_`. It always
starts with a letter.
-}
identifier : String -> String
identifier key =
    "k-"
        ++ String.map
            (\c ->
                if Char.isAlphaNum c || c == '-' || c == '_' || c == '.' then
                    c

                else
                    '_'
            )
            key


escape : String -> String
escape =
    String.replace "&" "&amp;"
        >> String.replace "<" "&lt;"
        >> String.replace ">" "&gt;"
        >> String.replace "\"" "&quot;"
