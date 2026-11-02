module Diagram.Paint exposing
    ( Paint, Stroke, Width(..)
    , filled, outlined, filledAndOutlined
    , hairline, scaled
    )

{-| How the elements of a diagram are painted. Colours are CSS colour strings that SVG 1.1 also accepts, such as
`"#242424"`, so they mean the same in a browser and in a drawing program.

@docs Paint, Stroke, Width
@docs filled, outlined, filledAndOutlined
@docs hairline, scaled

-}


{-| The fill and outline of a shape.
-}
type alias Paint =
    { fill : Maybe String
    , stroke : Maybe Stroke
    }


{-| A line: its colour, width and opacity, and a dash pattern in pixels, empty for a solid line.
-}
type alias Stroke =
    { color : String
    , width : Width
    , opacity : Float
    , dash : List Float
    }


{-| The width of a line.

  - `Hairline` lines keep their width in pixels whatever the scale a diagram is shown at, as a border on a web page
    does. These are the lines that are aligned to physical pixels.
  - `Scaled` lines are part of the drawing and grow and shrink with it.

-}
type Width
    = Hairline Float
    | Scaled Float


{-| A shape filled with a colour and not outlined.
-}
filled : String -> Paint
filled color =
    { fill = Just color, stroke = Nothing }


{-| A shape outlined and not filled.
-}
outlined : Stroke -> Paint
outlined stroke =
    { fill = Nothing, stroke = Just stroke }


{-| A shape filled with a colour and outlined.
-}
filledAndOutlined : String -> Stroke -> Paint
filledAndOutlined color stroke =
    { fill = Just color, stroke = Just stroke }


{-| A solid hairline of a given colour and width.
-}
hairline : String -> Float -> Stroke
hairline color width =
    { color = color, width = Hairline width, opacity = 1, dash = [] }


{-| A solid line that scales with the diagram.
-}
scaled : String -> Float -> Stroke
scaled color width =
    { color = color, width = Scaled width, opacity = 1, dash = [] }
