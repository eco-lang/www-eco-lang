module Style.Layout exposing
    ( reset
    , gap, padX, padY, padLeft, padTop, marginTop, marginBottom
    , row, column, grow, noShrink, alignItems, alignSelf, spaceBetween
    , textXs, textSm, textLg, text4xl, weight
    , fullWidth, fullHeight, minScreenHeight, maxWidth, height
    , rounded, roundedLg, relative, block, hidden, noUnderline, hoverUnderline, srOnly
    , mobile
    )

{-| Layout building blocks for the `eco-*` classes in `Style`.

These replace the Tailwind utilities the site used to put in its markup, with the same values: spacing is in steps of
0.25rem (`gap 7` is Tailwind's `gap-7`), and each text size sets its line height as Tailwind pairs them. Each function
returns a `Css.Style` for use inside a `Css.Global.class` rule.

In a rule, put these first and the class's own design properties after them, so that where both set a property, the
class's own value wins.

@docs reset
@docs gap, padX, padY, padLeft, padTop, marginTop, marginBottom
@docs row, column, grow, noShrink, alignItems, alignSelf, spaceBetween
@docs textXs, textSm, textLg, text4xl, weight
@docs fullWidth, fullHeight, minScreenHeight, maxWidth, height
@docs rounded, roundedLg, relative, block, hidden, noUnderline, hoverUnderline, srOnly
@docs mobile

-}

import Css
import Css.Global
import Css.Media



-- RESET


{-| The base styles every page starts from: the parts of Tailwind's Preflight reset that apply to this site, and the
page's default colours. Margins and padding start at zero, borders are solid and zero-width, sizes include padding and
border, headings and lists carry no styling of their own, and images are blocks.

It must come first in the stylesheet, so that any class rule overrides it.

-}
reset : List Css.Global.Snippet
reset =
    [ Css.Global.selector "*, ::after, ::before, ::backdrop, ::file-selector-button"
        [ Css.property "box-sizing" "border-box"
        , Css.property "border" "0 solid"
        , Css.property "margin" "0"
        , Css.property "padding" "0"
        , Css.property "border-color" "oklch(92.8% 0.006 264.531)"
        ]
    , Css.Global.selector "html, :host"
        [ Css.property "-webkit-text-size-adjust" "100%"
        , Css.property "tab-size" "4"
        , Css.property "line-height" "1.5"
        , Css.property "font-family" "ui-sans-serif, system-ui, sans-serif, \"Apple Color Emoji\", \"Segoe UI Emoji\", \"Segoe UI Symbol\", \"Noto Color Emoji\""
        , Css.property "font-feature-settings" "normal"
        , Css.property "font-variation-settings" "normal"
        , Css.property "-webkit-tap-highlight-color" "transparent"
        ]
    , Css.Global.selector "body"
        [ Css.property "background-color" "#fff"
        , Css.property "color" "oklch(55.4% 0.046 257.417)"
        , Css.property "-webkit-font-smoothing" "antialiased"
        , Css.property "-moz-osx-font-smoothing" "grayscale"
        ]
    , Css.Global.selector "hr"
        [ Css.property "height" "0"
        , Css.property "color" "inherit"
        , Css.property "border-top-width" "1px"
        ]
    , Css.Global.selector "abbr:where([title])"
        [ Css.property "text-decoration" "underline dotted"
        ]
    , Css.Global.selector "h1, h2, h3, h4, h5, h6"
        [ Css.property "font-size" "inherit"
        , Css.property "font-weight" "inherit"
        ]
    , Css.Global.selector "a"
        [ Css.property "color" "inherit"
        , Css.property "text-decoration" "inherit"
        ]
    , Css.Global.selector "b, strong"
        [ Css.property "font-weight" "bolder"
        ]
    , Css.Global.selector "code, kbd, samp, pre"
        [ Css.property "font-family" "ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, \"Liberation Mono\", \"Courier New\", monospace"
        , Css.property "font-feature-settings" "normal"
        , Css.property "font-variation-settings" "normal"
        , Css.property "font-size" "1em"
        ]
    , Css.Global.selector "small"
        [ Css.property "font-size" "80%"
        ]
    , Css.Global.selector "sub, sup"
        [ Css.property "vertical-align" "baseline"
        , Css.property "font-size" "75%"
        , Css.property "line-height" "0"
        , Css.property "position" "relative"
        ]
    , Css.Global.selector "sub"
        [ Css.property "bottom" "-0.25em"
        ]
    , Css.Global.selector "sup"
        [ Css.property "top" "-0.5em"
        ]
    , Css.Global.selector "table"
        [ Css.property "text-indent" "0"
        , Css.property "border-color" "inherit"
        , Css.property "border-collapse" "collapse"
        ]
    , Css.Global.selector "summary"
        [ Css.property "display" "list-item"
        ]
    , Css.Global.selector "ol, ul, menu"
        [ Css.property "list-style" "none"
        ]
    , Css.Global.selector "img, svg, video, canvas, audio, iframe, embed, object"
        [ Css.property "vertical-align" "middle"
        , Css.property "display" "block"
        ]
    , Css.Global.selector "img, video"
        [ Css.property "max-width" "100%"
        , Css.property "height" "auto"
        ]
    , Css.Global.selector "button, input, select, optgroup, textarea, ::file-selector-button"
        [ Css.property "font" "inherit"
        , Css.property "font-feature-settings" "inherit"
        , Css.property "font-variation-settings" "inherit"
        , Css.property "letter-spacing" "inherit"
        , Css.property "color" "inherit"
        , Css.property "opacity" "1"
        , Css.property "background-color" "transparent"
        , Css.property "border-radius" "0"
        ]
    , Css.Global.selector "[hidden]:where(:not([hidden=until-found]))"
        [ Css.property "display" "none !important"
        ]
    ]



-- SPACING


{-| A length on the spacing scale: `space 7` is `1.75rem`.
-}
space : Float -> String
space n =
    String.fromFloat (n * 0.25) ++ "rem"


{-| -}
gap : Float -> Css.Style
gap n =
    Css.property "gap" (space n)


{-| -}
padX : Float -> Css.Style
padX n =
    Css.property "padding-inline" (space n)


{-| -}
padY : Float -> Css.Style
padY n =
    Css.property "padding-block" (space n)


{-| -}
padLeft : Float -> Css.Style
padLeft n =
    Css.property "padding-left" (space n)


{-| -}
padTop : Float -> Css.Style
padTop n =
    Css.property "padding-top" (space n)


{-| -}
marginTop : Float -> Css.Style
marginTop n =
    Css.property "margin-top" (space n)


{-| -}
marginBottom : Float -> Css.Style
marginBottom n =
    Css.property "margin-bottom" (space n)



-- FLEX


{-| A flex container laying its children out in a row.
-}
row : Css.Style
row =
    Css.property "display" "flex"


{-| A flex container laying its children out in a column.
-}
column : Css.Style
column =
    Css.batch
        [ Css.property "display" "flex"
        , Css.property "flex-direction" "column"
        ]


{-| A flex item that takes the free space.
-}
grow : Css.Style
grow =
    Css.property "flex" "1"


{-| -}
noShrink : Css.Style
noShrink =
    Css.property "flex-shrink" "0"


{-| `alignItems "center"`, `"baseline"`, `"flex-end"`.
-}
alignItems : String -> Css.Style
alignItems =
    Css.property "align-items"


{-| -}
alignSelf : String -> Css.Style
alignSelf =
    Css.property "align-self"


{-| -}
spaceBetween : Css.Style
spaceBetween =
    Css.property "justify-content" "space-between"



-- TYPE


fontSize : String -> String -> Css.Style
fontSize size lineHeight =
    Css.batch
        [ Css.property "font-size" size
        , Css.property "line-height" lineHeight
        ]


{-| 12px on 16px.
-}
textXs : Css.Style
textXs =
    fontSize "0.75rem" "calc(1 / 0.75)"


{-| 14px on 20px.
-}
textSm : Css.Style
textSm =
    fontSize "0.875rem" "calc(1.25 / 0.875)"


{-| 18px on 28px.
-}
textLg : Css.Style
textLg =
    fontSize "1.125rem" "calc(1.75 / 1.125)"


{-| 36px on 40px.
-}
text4xl : Css.Style
text4xl =
    fontSize "2.25rem" "calc(2.5 / 2.25)"


{-| `weight 600`.
-}
weight : Int -> Css.Style
weight n =
    Css.property "font-weight" (String.fromInt n)



-- SIZING


{-| -}
fullWidth : Css.Style
fullWidth =
    Css.property "width" "100%"


{-| -}
fullHeight : Css.Style
fullHeight =
    Css.property "height" "100%"


{-| -}
minScreenHeight : Css.Style
minScreenHeight =
    Css.property "min-height" "100vh"


{-| `maxWidth "520px"`.
-}
maxWidth : String -> Css.Style
maxWidth =
    Css.property "max-width"


{-| A height on the spacing scale: `height 12` is `3rem`.
-}
height : Float -> Css.Style
height n =
    Css.property "height" (space n)



-- OTHER


{-| -}
rounded : Css.Style
rounded =
    Css.property "border-radius" "0.25rem"


{-| -}
roundedLg : Css.Style
roundedLg =
    Css.property "border-radius" "0.5rem"


{-| -}
relative : Css.Style
relative =
    Css.property "position" "relative"


{-| -}
block : Css.Style
block =
    Css.property "display" "block"


{-| -}
hidden : Css.Style
hidden =
    Css.property "display" "none"


{-| -}
noUnderline : Css.Style
noUnderline =
    Css.property "text-decoration-line" "none"


{-| Underline on hover, on devices that can hover.
-}
hoverUnderline : Css.Style
hoverUnderline =
    Css.Media.withMediaQuery [ "(hover: hover)" ]
        [ Css.hover [ Css.property "text-decoration-line" "underline" ] ]


{-| Hidden from sight but read by screen readers.
-}
srOnly : Css.Style
srOnly =
    Css.batch
        [ Css.property "clip-path" "inset(50%)"
        , Css.property "white-space" "nowrap"
        , Css.property "border-width" "0"
        , Css.property "width" "1px"
        , Css.property "height" "1px"
        , Css.property "margin" "-1px"
        , Css.property "padding" "0"
        , Css.property "position" "absolute"
        , Css.property "overflow" "hidden"
        ]



-- RESPONSIVE


{-| Styles for phones: screens narrower than 768px. Write them inside the class they change, after its desktop
styles, so desktop browsers never apply them.
-}
mobile : List Css.Style -> Css.Style
mobile =
    Css.Media.withMediaQuery [ "(max-width: 767.98px)" ]
