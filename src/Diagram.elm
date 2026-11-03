module Diagram exposing
    ( Diagram, Element(..), Anchor(..)
    , diagram, box, line, polygon, text, group, faded
    , Group, Box, Line, Polygon, Text
    )

{-| A diagram as pure geometry: boxes, lines, filled shapes and text, each with the paint to draw it with. It says
nothing about how it will be drawn. `Diagram.Camera` maps a diagram from the world it was laid out in to a screen or a
page, and `Diagram.Svg` and `Diagram.Svg11` draw it.

Diagrams are built on the double grid with `Diagram.Grid` and `Diagram.Text`.

@docs Diagram, Element, Anchor
@docs diagram, box, line, polygon, text, group, faded
@docs Group, Box, Line, Polygon, Text

-}

import BoundingBox2d exposing (BoundingBox2d)
import Diagram.Font exposing (Font)
import Diagram.Paint exposing (Paint, Stroke)
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Polygon2d exposing (Polygon2d)
import Polyline2d exposing (Polyline2d)


{-| The elements of a diagram, drawn in order, and the region it covers.
-}
type alias Diagram coordinates =
    { bounds : BoundingBox2d Pixels coordinates
    , elements : List (Element coordinates)
    }


{-| One element of a diagram.

A `Group` collects elements and can carry a `key`, which names the thing the group draws, and `data`, a list of
named values about it. A renderer that handles events uses the key to say which thing an event happened on, and a web
renderer can write the data into the page for scripts and styles to use. Neither changes how the group looks. Its
`opacity`, from 0 to 1, fades the group as a whole, as when something fades in or out.

-}
type Element coordinates
    = BoxElement (Box coordinates)
    | LineElement (Line coordinates)
    | PolygonElement (Polygon coordinates)
    | TextElement (Text coordinates)
    | GroupElement Group (List (Element coordinates))


{-| A rectangle with optionally rounded corners. A box's outline is drawn inside it, so that its outer edge is the
edge of the box.
-}
type alias Box coordinates =
    { box : BoundingBox2d Pixels coordinates
    , radius : Float
    , paint : Paint
    }


{-| A line through a list of points.
-}
type alias Line coordinates =
    { points : Polyline2d Pixels coordinates
    , stroke : Stroke
    }


{-| A filled shape, such as an arrow head.
-}
type alias Polygon coordinates =
    { polygon : Polygon2d Pixels coordinates
    , paint : Paint
    }


{-| A line of text, placed by its baseline. `anchor` says which end of the text, or its middle, is at the point. Its
`size` is in pixels.
-}
type alias Text coordinates =
    { baseline : Point2d Pixels coordinates
    , anchor : Anchor
    , content : String
    , font : Font
    , size : Float
    , color : String
    }


{-| The name of the thing a group draws, and data about it.
-}
type alias Group =
    { key : Maybe String
    , data : List ( String, String )
    , opacity : Float
    }


{-| Where text is placed relative to its point.
-}
type Anchor
    = Start
    | Middle
    | End


{-| A diagram covering a region.
-}
diagram : BoundingBox2d Pixels coordinates -> List (Element coordinates) -> Diagram coordinates
diagram bounds elements =
    { bounds = bounds, elements = elements }


{-| A box with corners of a radius, in pixels.
-}
box : Paint -> Float -> BoundingBox2d Pixels coordinates -> Element coordinates
box paint radius bounds =
    BoxElement { box = bounds, radius = radius, paint = paint }


{-| A line through points.
-}
line : Stroke -> List (Point2d Pixels coordinates) -> Element coordinates
line stroke points =
    LineElement { points = Polyline2d.fromVertices points, stroke = stroke }


{-| A filled shape through points.
-}
polygon : Paint -> List (Point2d Pixels coordinates) -> Element coordinates
polygon paint points =
    PolygonElement { polygon = Polygon2d.singleLoop points, paint = paint }


{-| Text, placed by its baseline. `Diagram.Text` places text on the grid.
-}
text : Text coordinates -> Element coordinates
text =
    TextElement


{-| A group of elements.
-}
group : Group -> List (Element coordinates) -> Element coordinates
group =
    GroupElement


{-| Elements faded together to an opacity, from 0 to 1.
-}
faded : Float -> List (Element coordinates) -> Element coordinates
faded opacity =
    GroupElement { key = Nothing, data = [], opacity = opacity }
