module Diagram.Svg.Node exposing (Node(..), fromElement, number)

{-| The SVG for a diagram, as a tree of elements and their presentation attributes. Both renderers draw from this
tree, so a diagram drawn in a browser by `Diagram.Svg` and written to a file by `Diagram.Svg11` look the same: every
visual property is an SVG 1.1 presentation attribute here, and neither renderer adds any of its own.

@docs Node, fromElement, number

-}

import BoundingBox2d
import Diagram exposing (Anchor(..), Element(..))
import Diagram.Camera exposing (ScreenCoordinates)
import Diagram.Font as Font
import Diagram.Paint exposing (Paint, Stroke, Width(..))
import Pixels
import Point2d exposing (Point2d)
import Polygon2d
import Polyline2d


{-| An SVG element with its attributes and children, some text, or a group, which keeps the key and data of the
diagram's group for the renderer to use as it sees fit.
-}
type Node
    = Node String (List ( String, String )) (List Node)
    | Content String
    | Group Diagram.Group (List Node)


{-| The SVG for an element of a diagram on the screen.
-}
fromElement : Element ScreenCoordinates -> Node
fromElement element =
    case element of
        BoxElement b ->
            let
                e =
                    BoundingBox2d.extrema b.box

                minX =
                    Pixels.toFloat e.minX

                minY =
                    Pixels.toFloat e.minY

                w =
                    Pixels.toFloat e.maxX - minX

                h =
                    Pixels.toFloat e.maxY - minY

                r =
                    min b.radius (min w h / 2)
            in
            Node "rect"
                ([ ( "x", number minX )
                 , ( "y", number minY )
                 , ( "width", number (max 0 w) )
                 , ( "height", number (max 0 h) )
                 ]
                    ++ (if r > 0 then
                            [ ( "rx", number r ), ( "ry", number r ) ]

                        else
                            []
                       )
                    ++ paint b.paint
                )
                []

        LineElement l ->
            Node "polyline"
                (( "points", points (Polyline2d.vertices l.points) )
                    :: ( "fill", "none" )
                    :: stroke l.stroke
                )
                []

        PolygonElement p ->
            Node "polygon"
                (( "points", points (Polygon2d.outerLoop p.polygon) ) :: paint p.paint)
                []

        TextElement t ->
            let
                { x, y } =
                    Point2d.toPixels t.baseline
            in
            Node "text"
                ([ ( "x", number x )
                 , ( "y", number y )
                 , ( "font-family", Font.family t.font )
                 , ( "font-size", number t.size )
                 , ( "font-weight", String.fromInt t.font.weight )
                 , ( "fill", t.color )
                 ]
                    ++ (case t.anchor of
                            Start ->
                                []

                            Middle ->
                                [ ( "text-anchor", "middle" ) ]

                            End ->
                                [ ( "text-anchor", "end" ) ]
                       )
                )
                [ Content t.content ]

        GroupElement g children ->
            Group g (List.map fromElement children)


paint : Paint -> List ( String, String )
paint p =
    ( "fill", Maybe.withDefault "none" p.fill )
        :: (case p.stroke of
                Just s ->
                    stroke s

                Nothing ->
                    []
           )


stroke : Stroke -> List ( String, String )
stroke s =
    [ ( "stroke", s.color )
    , ( "stroke-width"
      , number
            (case s.width of
                Hairline w ->
                    w

                Scaled w ->
                    w
            )
      )
    ]
        ++ (if s.opacity < 1 then
                [ ( "stroke-opacity", number s.opacity ) ]

            else
                []
           )
        ++ (if List.isEmpty s.dash then
                []

            else
                [ ( "stroke-dasharray", String.join "," (List.map number s.dash) ) ]
           )


points : List (Point2d Pixels.Pixels ScreenCoordinates) -> String
points ps =
    ps
        |> List.map (\p -> Point2d.toPixels p |> (\{ x, y } -> number x ++ "," ++ number y))
        |> String.join " "


{-| A number as SVG writes it, to a thousandth of a pixel.
-}
number : Float -> String
number v =
    String.fromFloat (toFloat (round (v * 1000)) / 1000)
