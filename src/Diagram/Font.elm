module Diagram.Font exposing
    ( Font
    , robotoMono, montserrat, inter
    , family
    )

{-| Fonts and their metrics.

Layout never asks a renderer to measure text. What it needs to know about a font is here: the ascent and descent,
from the font's `hhea` table in em, and for a monospaced font the advance of every glyph, so that text can be fitted to
a width.

@docs Font
@docs robotoMono, montserrat, inter
@docs family

-}


{-| A typeface at one weight.

  - `name` and `generic` are the family and the generic family to fall back to, as CSS and SVG name them.
  - `ascent` and `descent` are in em.
  - `advance` is the width of every glyph in em, for a monospaced font, and `Nothing` otherwise.

-}
type alias Font =
    { name : String
    , generic : String
    , weight : Int
    , ascent : Float
    , descent : Float
    , advance : Maybe Float
    }


{-| Roboto Mono, at a weight.
-}
robotoMono : Int -> Font
robotoMono weight =
    { name = "Roboto Mono"
    , generic = "monospace"
    , weight = weight
    , ascent = 1.048
    , descent = 0.271
    , advance = Just 0.6
    }


{-| Montserrat, at a weight.
-}
montserrat : Int -> Font
montserrat weight =
    { name = "Montserrat"
    , generic = "sans-serif"
    , weight = weight
    , ascent = 0.968
    , descent = 0.251
    , advance = Nothing
    }


{-| Inter, at a weight.
-}
inter : Int -> Font
inter weight =
    { name = "Inter"
    , generic = "sans-serif"
    , weight = weight
    , ascent = 0.96875
    , descent = 0.2421875
    , advance = Nothing
    }


{-| The font family list, as CSS and SVG `font-family` take it.
-}
family : Font -> String
family font =
    "'" ++ font.name ++ "', " ++ font.generic
