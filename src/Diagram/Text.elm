module Diagram.Text exposing
    ( Style
    , size, lift, lineHeight
    , onGrid, inFrame
    , width, fit
    )

{-| Text on the main grid.

A style takes a whole number of grid rows, `units`, and sets its type at `units * grid / spacing` pixels, so `spacing`
is the line spacing: 1.5 means the type is two thirds of the height of its rows. Its baseline rests a little above the
grid line that closes its last row, `(rowsHeight - size) * 0.7` above it, which leaves the descenders inside the rows.
This is `fontSizePx` and `fontGridFraction` in stackwhack.

@docs Style
@docs size, lift, lineHeight
@docs onGrid, inFrame
@docs width, fit

-}

import Diagram exposing (Anchor, Element)
import Diagram.Font exposing (Font)
import Diagram.Grid as Grid exposing (Cells, Grid, WorldCoordinates)
import Point2d


{-| A text style: its font and colour, how many grid rows it takes and its line spacing.
-}
type alias Style =
    { font : Font
    , color : String
    , units : Float
    , spacing : Float
    }


{-| The type size in pixels.
-}
size : Grid -> Style -> Float
size grid style =
    grid.size * style.units / style.spacing


{-| How far the baseline sits above the grid line closing the text's last row.
-}
lift : Grid -> Style -> Float
lift grid style =
    (Grid.rhythm grid style.units - size grid style) * 0.7


{-| The height of the rows the text takes.
-}
lineHeight : Grid -> Style -> Float
lineHeight grid style =
    Grid.rhythm grid style.units


{-| Text whose rows end on grid line `row`, starting, centred on or ending at column `col`, which may be fractional to
centre text over a region.
-}
onGrid : Grid -> Style -> Anchor -> { col : Float, row : Int } -> String -> Element WorldCoordinates
onGrid grid style anchor at content =
    Diagram.text
        { baseline = Point2d.pixels (Grid.rhythm grid at.col) (Grid.rhythm grid (toFloat at.row) - lift grid style)
        , anchor = anchor
        , content = content
        , font = style.font
        , size = size grid style
        , color = style.color
        }


{-| Text inside a frame, starting on the first grid column inside it and ending on the grid line `row` rows below the
top of its footprint. The text is cut to fit the frame, if the font says how wide its text is.
-}
inFrame : Grid -> Style -> Cells -> Int -> String -> Element WorldCoordinates
inFrame grid style cells row content =
    onGrid grid
        style
        Diagram.Start
        { col = toFloat (cells.col + 1), row = cells.row + row }
        (fit grid style (Grid.rhythm grid (toFloat (cells.cols - 2))) content)


{-| How wide text is, if the font says.
-}
width : Grid -> Style -> String -> Maybe Float
width grid style content =
    style.font.advance
        |> Maybe.map (\advance -> advance * size grid style * toFloat (String.length content))


{-| Text cut to fit a width, ending in an ellipsis where it is cut. Text in a font that does not say how wide its text
is is left as it is.
-}
fit : Grid -> Style -> Float -> String -> String
fit grid style available content =
    case style.font.advance of
        Just advance ->
            let
                chars =
                    floor (available / (advance * size grid style))
            in
            if String.length content <= chars then
                content

            else
                String.left (max 0 (chars - 1)) content ++ "…"

        Nothing ->
            content
