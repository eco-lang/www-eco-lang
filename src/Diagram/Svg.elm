module Diagram.Svg exposing (Config, config, view, elements)

{-| Draw a diagram in a browser, as SVG.

The drawing is the same as the one `Diagram.Svg11` writes to a file, so what is seen on the page is what a drawing
program opens. On top of the drawing, a page can add what only makes sense in a browser: attributes and CSS on the
`<svg>` element, and event handlers and `data-*` attributes on the groups that carry a key.

Project the diagram onto the screen with `Diagram.Camera.project` first, so that it lands on device pixels.

@docs Config, config, view, elements

-}

import BoundingBox2d
import Diagram exposing (Diagram, Element)
import Diagram.Camera exposing (ScreenCoordinates)
import Diagram.Svg.Node as Node exposing (Node(..))
import Html exposing (Html)
import Html.Attributes
import Pixels
import Svg exposing (Svg)
import Svg.Attributes


{-| What a page adds to the drawing.

  - `attributes` go on the `<svg>` element, for CSS and rendering hints.
  - `group` gives the attributes for a group with a key, such as event handlers. Each such group also gets
    `data-key`, and a `data-*` attribute for each piece of its data.

-}
type alias Config msg =
    { attributes : List (Svg.Attribute msg)
    , group : String -> List (Svg.Attribute msg)
    }


{-| A drawing with nothing added.
-}
config : Config msg
config =
    { attributes = [], group = \_ -> [] }


{-| A diagram on the screen, as an `<svg>` element the size of its bounds.
-}
view : Config msg -> Diagram ScreenCoordinates -> Html msg
view cfg d =
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
    in
    Svg.svg
        ([ Svg.Attributes.width (Node.number w)
         , Svg.Attributes.height (Node.number h)
         , Svg.Attributes.viewBox (String.join " " (List.map Node.number [ minX, minY, w, h ]))
         ]
            ++ cfg.attributes
        )
        (elements cfg d.elements)


{-| The elements of a diagram on the screen, to place inside an `<svg>` element of a page's own.
-}
elements : Config msg -> List (Element ScreenCoordinates) -> List (Svg msg)
elements cfg =
    List.map (Node.fromElement >> toSvg cfg)


toSvg : Config msg -> Node -> Svg msg
toSvg cfg node =
    case node of
        Node name attrs children ->
            Svg.node name (List.map attribute attrs) (List.map (toSvg cfg) children)

        Content s ->
            Svg.text s

        Group g children ->
            Svg.g
                (case g.key of
                    Just key ->
                        Html.Attributes.attribute "data-key" key
                            :: List.map (\( k, v ) -> Html.Attributes.attribute ("data-" ++ k) v) g.data
                            ++ cfg.group key

                    Nothing ->
                        List.map (\( k, v ) -> Html.Attributes.attribute ("data-" ++ k) v) g.data
                )
                (List.map (toSvg cfg) children)


attribute : ( String, String ) -> Svg.Attribute msg
attribute ( name, value ) =
    Html.Attributes.attribute name value
