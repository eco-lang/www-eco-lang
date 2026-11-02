module Diagram.Grid exposing
    ( Grid, default
    , WorldCoordinates, Cells
    , rhythm, point, vOffset, hInset
    , frame, footprint
    , leftAnchor, rightAnchor, topAnchor, bottomAnchor
    , guides
    )

{-| The double grid.

Text sits on the main grid: every line of text fills a whole number of grid rows and its baseline is placed relative to
the grid line that closes its last row (see `Diagram.Text`). Frames, the boxes drawn around text, sit on the in-between
grid. A frame is shifted down from its footprint by `vGridAdjust` of a grid unit, so that there is a little more space
below the text it holds than above it; text that is perfectly centred in a box looks as if it is about to fall out of
the bottom. A frame is also inset from both sides of its footprint by `widthAdjust` of a grid unit. The inset is the
margin outside the frame and what remains of the unit is the padding inside it, so margin and padding together always
take one grid unit and text inside the frame still starts on a grid column.

Everything here is pure geometry, in pixels in world coordinates. Rendering it is the job of `Diagram.Camera` and the
renderers.

@docs Grid, default
@docs WorldCoordinates, Cells
@docs rhythm, point, vOffset, hInset
@docs frame, footprint
@docs leftAnchor, rightAnchor, topAnchor, bottomAnchor
@docs guides

-}

import BoundingBox2d exposing (BoundingBox2d)
import Diagram exposing (Element)
import Diagram.Paint as Paint
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Quantity


{-| The grid size in pixels and the two in-between grid adjustments, each a fraction of a grid unit.

  - `vGridAdjust` is how far down a frame is shifted from the grid. It should be over a half, so that there is more
    space below text than above it.
  - `widthAdjust` is the margin outside the left and right sides of a frame. One minus it is the padding inside.

-}
type alias Grid =
    { size : Float
    , vGridAdjust : Float
    , widthAdjust : Float
    }


{-| The values the eco atlas uses.
-}
default : Grid
default =
    { size = 18
    , vGridAdjust = 0.55
    , widthAdjust = 0.45
    }


{-| The coordinate system a diagram is laid out in, before a camera maps it to a screen or a page.
-}
type WorldCoordinates
    = WorldCoordinates


{-| A footprint on the grid: the cells a component of a diagram takes, counted in whole grid units. Its frame is drawn
on the in-between grid inside it, and the space left between neighbouring frames is their margins.
-}
type alias Cells =
    { col : Int
    , row : Int
    , cols : Int
    , rows : Int
    }


{-| A number of grid units, in pixels.
-}
rhythm : Grid -> Float -> Float
rhythm grid units =
    grid.size * units


{-| A point on the grid, given in grid units, which may be fractional.
-}
point : Grid -> Float -> Float -> Point2d Pixels WorldCoordinates
point grid col row =
    Point2d.pixels (rhythm grid col) (rhythm grid row)


{-| How far frames sit below the main grid, rounded to a whole pixel so that the edges of frames land on whole pixels
whenever the grid does. This is `plusGridFraction` in stackwhack.
-}
vOffset : Grid -> Float
vOffset grid =
    toFloat (round (grid.size * grid.vGridAdjust))


{-| How far frames are inset from the sides of their footprints, rounded to a whole pixel.
-}
hInset : Grid -> Float
hInset grid =
    toFloat (round (grid.size * grid.widthAdjust))


{-| The frame for a footprint, on the in-between grid. It is inset by `hInset` on both sides and shifted down by
`vOffset`, and it is one row shorter than the footprint, so the row it gives up is shared out as the space above and
below it.
-}
frame : Grid -> Cells -> BoundingBox2d Pixels WorldCoordinates
frame grid cells =
    let
        x =
            rhythm grid (toFloat cells.col) + hInset grid

        y =
            rhythm grid (toFloat cells.row) + vOffset grid
    in
    BoundingBox2d.fromExtrema
        { minX = Pixels.pixels x
        , minY = Pixels.pixels y
        , maxX = Pixels.pixels (rhythm grid (toFloat (cells.col + cells.cols)) - hInset grid)
        , maxY = Pixels.pixels (y + rhythm grid (toFloat (cells.rows - 1)))
        }


{-| The whole footprint, on the main grid.
-}
footprint : Grid -> Cells -> BoundingBox2d Pixels WorldCoordinates
footprint grid cells =
    BoundingBox2d.from
        (point grid (toFloat cells.col) (toFloat cells.row))
        (point grid (toFloat (cells.col + cells.cols)) (toFloat (cells.row + cells.rows)))



-- ANCHORS


{-| Where a line meets the left edge of a frame, level with the middle of the text row `textRow` of its footprint (0
is the first row).
-}
leftAnchor : Grid -> Cells -> Int -> Point2d Pixels WorldCoordinates
leftAnchor grid cells textRow =
    Point2d.pixels
        (rhythm grid (toFloat cells.col) + hInset grid)
        (rhythm grid (toFloat cells.row + toFloat textRow + 0.5))


{-| Where a line meets the right edge of a frame, level with the middle of text row `textRow`.
-}
rightAnchor : Grid -> Cells -> Int -> Point2d Pixels WorldCoordinates
rightAnchor grid cells textRow =
    Point2d.pixels
        (rhythm grid (toFloat (cells.col + cells.cols)) - hInset grid)
        (rhythm grid (toFloat cells.row + toFloat textRow + 0.5))


{-| The middle of the top edge of a frame.
-}
topAnchor : Grid -> Cells -> Point2d Pixels WorldCoordinates
topAnchor grid cells =
    BoundingBox2d.extrema (frame grid cells)
        |> (\e -> Point2d.xy (Quantity.half (Quantity.plus e.minX e.maxX)) e.minY)


{-| The middle of the bottom edge of a frame.
-}
bottomAnchor : Grid -> Cells -> Point2d Pixels WorldCoordinates
bottomAnchor grid cells =
    BoundingBox2d.extrema (frame grid cells)
        |> (\e -> Point2d.xy (Quantity.half (Quantity.plus e.minX e.maxX)) e.maxY)



-- GUIDES


{-| Guide lines for both grids over a region, to see how a diagram sits on them: the main grid that text sits on, in
`text` paint, and the in-between grid that frames sit on, in `frames` paint. Only the region is covered, and nothing is
drawn when the lines would be closer together than `minGap` pixels at the scale `scale` it will be shown at.
-}
guides :
    { grid : Grid
    , region : BoundingBox2d Pixels WorldCoordinates
    , scale : Float
    , minGap : Float
    , text : Paint.Stroke
    , frames : Paint.Stroke
    }
    -> List (Element WorldCoordinates)
guides { grid, region, scale, minGap, text, frames } =
    if grid.size * scale < minGap then
        []

    else
        let
            e =
                BoundingBox2d.extrema region

            minX =
                Pixels.toFloat e.minX

            maxX =
                Pixels.toFloat e.maxX

            minY =
                Pixels.toFloat e.minY

            maxY =
                Pixels.toFloat e.maxY

            steps lo hi offset =
                List.range (floor ((lo - offset) / grid.size)) (ceiling ((hi - offset) / grid.size))
                    |> List.map (\i -> toFloat i * grid.size + offset)

            vertical paint offset =
                steps minX maxX offset
                    |> List.map (\x -> Diagram.line paint [ Point2d.pixels x minY, Point2d.pixels x maxY ])

            horizontal paint offset =
                steps minY maxY offset
                    |> List.map (\y -> Diagram.line paint [ Point2d.pixels minX y, Point2d.pixels maxX y ])
        in
        List.concat
            [ horizontal frames (vOffset grid)
            , vertical frames (hInset grid)
            , vertical frames (grid.size - hInset grid)
            , horizontal text 0
            , vertical text 0
            ]
