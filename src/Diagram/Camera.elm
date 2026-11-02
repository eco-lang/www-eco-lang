module Diagram.Camera exposing
    ( Camera, ScreenCoordinates
    , identity, fit, zoomAbout, panBy, relative
    , toScreen, fromScreen, visibleRegion
    , project
    )

{-| A camera maps a diagram from the world it was laid out in to the screen, or the page, it will be drawn on, and
lines it up with the device's pixels as it goes.

Scaling a finished drawing, as a CSS transform or an SVG `viewBox` does, blurs it: the edges of boxes fall between
pixels, and text is set at one size and stretched to another. `project` does not scale a drawing. It works out where
every point lands on the screen and rounds it to a device pixel: the edges of boxes, the ends of lines and the
baselines of text. Hairlines are moved half a pixel where their width needs it, so that they cover whole pixels. Text
is set at the size it will be seen at, so the browser hints it at that size. The result is a new diagram, in screen
coordinates, that a renderer draws without any further scaling.

@docs Camera, ScreenCoordinates
@docs identity, fit, zoomAbout, panBy, relative
@docs toScreen, fromScreen, visibleRegion
@docs project

-}

import BoundingBox2d exposing (BoundingBox2d)
import Diagram exposing (Diagram, Element(..))
import Diagram.Paint exposing (Paint, Width(..))
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Polygon2d
import Polyline2d


{-| A camera: a point on the screen `x`, `y` where the world's origin appears, the scale, and how many device pixels
there are to a pixel on the screen.
-}
type alias Camera =
    { x : Float
    , y : Float
    , scale : Float
    , pixelRatio : Float
    }


{-| The coordinate system of a screen or page.
-}
type ScreenCoordinates
    = ScreenCoordinates


{-| The camera that leaves a world as it is, on a device with one device pixel to a pixel. A diagram exported to a
file is drawn with this.
-}
identity : Camera
identity =
    { x = 0, y = 0, scale = 1, pixelRatio = 1 }


{-| A camera showing all of a region in a screen of the given size, centred, with a margin round it.
-}
fit : { width : Float, height : Float, margin : Float, pixelRatio : Float } -> BoundingBox2d Pixels c -> Camera
fit screen region =
    let
        e =
            BoundingBox2d.extrema region

        w =
            Pixels.toFloat e.maxX - Pixels.toFloat e.minX

        h =
            Pixels.toFloat e.maxY - Pixels.toFloat e.minY

        scale =
            min ((screen.width - 2 * screen.margin) / w) ((screen.height - 2 * screen.margin) / h)
    in
    { x = (screen.width - w * scale) / 2 - Pixels.toFloat e.minX * scale
    , y = (screen.height - h * scale) / 2 - Pixels.toFloat e.minY * scale
    , scale = scale
    , pixelRatio = screen.pixelRatio
    }


{-| Zoom by a factor, keeping the world point under the screen point `x`, `y` where it is.
-}
zoomAbout : Float -> { x : Float, y : Float } -> Camera -> Camera
zoomAbout factor at camera =
    { camera
        | scale = camera.scale * factor
        , x = at.x - (at.x - camera.x) * factor
        , y = at.y - (at.y - camera.y) * factor
    }


{-| Move the view by an amount on the screen.
-}
panBy : Float -> Float -> Camera -> Camera
panBy dx dy camera =
    { camera | x = camera.x + dx, y = camera.y + dy }


{-| The translation and scale that take a drawing made for one camera to where another camera would draw it. While
the view is moving, a renderer can apply this to the drawing it already has, as a cheap transform, and project the
diagram again once the view settles.
-}
relative : { from : Camera, to : Camera } -> { dx : Float, dy : Float, scale : Float }
relative { from, to } =
    let
        r =
            to.scale / from.scale
    in
    { dx = to.x - from.x * r, dy = to.y - from.y * r, scale = r }


{-| Where a world point appears on the screen, without rounding.
-}
toScreen : Camera -> Point2d Pixels c -> Point2d Pixels ScreenCoordinates
toScreen camera p =
    let
        { x, y } =
            Point2d.toPixels p
    in
    Point2d.pixels (camera.x + x * camera.scale) (camera.y + y * camera.scale)


{-| The world point under a screen point.
-}
fromScreen : Camera -> Point2d Pixels ScreenCoordinates -> Point2d Pixels c
fromScreen camera p =
    let
        { x, y } =
            Point2d.toPixels p
    in
    Point2d.pixels ((x - camera.x) / camera.scale) ((y - camera.y) / camera.scale)


{-| The region of the world a screen of the given size shows.
-}
visibleRegion : Camera -> { width : Float, height : Float } -> BoundingBox2d Pixels c
visibleRegion camera screen =
    BoundingBox2d.from
        (fromScreen camera (Point2d.pixels 0 0))
        (fromScreen camera (Point2d.pixels screen.width screen.height))



-- PROJECTION


{-| A diagram on the screen, every edge, line end and baseline on a device pixel.
-}
project : Camera -> Diagram c -> Diagram ScreenCoordinates
project camera d =
    { bounds = projectBox camera 0 d.bounds
    , elements = List.map (projectElement camera) d.elements
    }


projectElement : Camera -> Element c -> Element ScreenCoordinates
projectElement camera element =
    case element of
        BoxElement b ->
            BoxElement
                { box = projectBox camera (strokeWidth camera b.paint) b.box
                , radius = b.radius
                , paint = projectPaint camera b.paint
                }

        LineElement l ->
            let
                w =
                    width camera l.stroke.width
            in
            LineElement
                { points = Polyline2d.mapVertices (snapPoint camera (offsetFor camera w)) l.points
                , stroke = { color = l.stroke.color, width = Hairline w, opacity = l.stroke.opacity, dash = l.stroke.dash }
                }

        PolygonElement p ->
            PolygonElement
                { polygon =
                    Polygon2d.withHoles
                        (List.map (List.map (toScreen camera)) (Polygon2d.innerLoops p.polygon))
                        (List.map (toScreen camera) (Polygon2d.outerLoop p.polygon))
                , paint = projectPaint camera p.paint
                }

        TextElement t ->
            TextElement
                { baseline = snapPoint camera 0 t.baseline
                , anchor = t.anchor
                , content = t.content
                , font = t.font
                , size = toFloat (round (t.size * camera.scale * 100)) / 100
                , color = t.color
                }

        GroupElement g children ->
            GroupElement g (List.map (projectElement camera) children)


{-| Snap both corners of a box to device pixels, so that neighbouring boxes never disagree by a pixel, then pull them in
by half the outline width, so the outline is drawn just inside the box and covers whole pixels.
-}
projectBox : Camera -> Float -> BoundingBox2d Pixels c -> BoundingBox2d Pixels ScreenCoordinates
projectBox camera outline bounds =
    let
        e =
            BoundingBox2d.extrema bounds

        sx v =
            snap camera (camera.x + Pixels.toFloat v * camera.scale)

        sy v =
            snap camera (camera.y + Pixels.toFloat v * camera.scale)

        half =
            outline / 2
    in
    BoundingBox2d.fromExtrema
        { minX = Pixels.pixels (sx e.minX + half)
        , minY = Pixels.pixels (sy e.minY + half)
        , maxX = Pixels.pixels (sx e.maxX - half)
        , maxY = Pixels.pixels (sy e.maxY - half)
        }


projectPaint : Camera -> Paint -> Paint
projectPaint camera paint =
    { fill = paint.fill
    , stroke =
        Maybe.map
            (\s -> { color = s.color, width = Hairline (width camera s.width), opacity = s.opacity, dash = s.dash })
            paint.stroke
    }


strokeWidth : Camera -> Paint -> Float
strokeWidth camera paint =
    paint.stroke |> Maybe.map (.width >> width camera) |> Maybe.withDefault 0


{-| A line's width on the screen. Scaled lines are rounded to device pixels, and never thinner than one.
-}
width : Camera -> Width -> Float
width camera w =
    case w of
        Hairline px ->
            px

        Scaled px ->
            max 1 (toFloat (round (px * camera.scale * camera.pixelRatio))) / camera.pixelRatio


{-| How far off the device pixel grid the centre of a line must be for it to cover whole device pixels: half a device
pixel for a line an odd number of device pixels wide.
-}
offsetFor : Camera -> Float -> Float
offsetFor camera w =
    if modBy 2 (round (w * camera.pixelRatio)) == 1 then
        0.5 / camera.pixelRatio

    else
        0


snapPoint : Camera -> Float -> Point2d Pixels c -> Point2d Pixels ScreenCoordinates
snapPoint camera offset p =
    let
        { x, y } =
            Point2d.toPixels p
    in
    Point2d.pixels
        (snap camera (camera.x + x * camera.scale - offset) + offset)
        (snap camera (camera.y + y * camera.scale - offset) + offset)


snap : Camera -> Float -> Float
snap camera v =
    toFloat (round (v * camera.pixelRatio)) / camera.pixelRatio
