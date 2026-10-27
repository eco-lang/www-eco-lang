module Style.Packages exposing (styleNode, highlightTheme)

{-| The stylesheet of the packages pages, under `/packages`.

It is separate from the site's stylesheet in `Style`, because the packages pages are laid out as a site of their own,
modelled on package.elm-lang.org, and will move to one: a solid band of colour across the top, the content on the
left and the package's menu on the right, and each declaration flush left with its doc comment inset below it, so the
eye can run down the left edge from one declaration to the next. Every class here starts `pkg-`.

`Shared.view` renders this stylesheet in place of the site's one on the packages pages.

@docs styleNode, highlightTheme

-}

import Css
import Css.Global
import Html
import Html.Styled
import Style.Layout
    exposing
        ( alignItems
        , block
        , column
        , gap
        , grow
        , hidden
        , hoverUnderline
        , minScreenHeight
        , mobile
        , noShrink
        , noUnderline
        , relative
        , reset
        , row
        , spaceBetween
        , weight
        )
import SyntaxHighlight



-- DESIGN TOKENS


colors :
    { band : String
    , text : String
    , muted : String
    , link : String
    , rule : String
    , codeBg : String
    , codeBorder : String
    }
colors =
    { band = "#4CAF50"
    , text = "#242424"
    , muted = "#8A8A8A"
    , link = "#2E7D32"
    , rule = "#EEEEEE"
    , codeBg = "#FFFFFF"
    , codeBorder = "#F0F0F0"
    }


fontBody : String
fontBody =
    "Inter, sans-serif"


fontLogo : String
fontLogo =
    "Montserrat, sans-serif"


fontCode : String
fontCode =
    "Roboto Mono, monospace"


{-| The width of the page body's contents, as on package.elm-lang.org. The band's contents have the same width, so
the logo lines up with the left edge of the content below it.
-}
contentWidth : String
contentWidth =
    "920px"



-- STYLE NODE


{-| The stylesheet, as a `<style>` element. Like `Style.styleNode` it is a constant, so Elm builds it once.
-}
styleNode : Html.Html msg
styleNode =
    Css.Global.global style
        |> Html.Styled.toUnstyled


{-| The colours of highlighted code: light, as on package.elm-lang.org.
-}
highlightTheme : Html.Html msg
highlightTheme =
    SyntaxHighlight.useTheme SyntaxHighlight.gitHub


style : List Css.Global.Snippet
style =
    List.concat
        [ reset
        , pageStyles
        , bandStyles
        , menuStyles
        , navStyles
        , catalogStyles
        , declarationStyles
        , markdownStyles
        , footerStyles
        ]



-- PAGE


pageStyles : List Css.Global.Snippet
pageStyles =
    [ Css.Global.class "pkg-page"
        [ minScreenHeight
        , column
        , Css.property "background-color" "#FFFFFF"
        , Css.property "color" colors.text
        , Css.property "font-family" fontBody
        , Css.property "font-size" "16px"
        ]
    , Css.Global.class "pkg-body"
        [ row
        , grow
        , alignItems "flex-start"
        , Css.property "width" "100%"
        , Css.property "max-width" ("calc(" ++ contentWidth ++ " + 40px)")
        , Css.property "margin" "0 auto"
        , Css.property "padding" "0 20px"
        , mobile [ Css.property "padding" "0 16px" ]
        ]
    , Css.Global.class "pkg-main"
        [ grow
        , Css.property "flex-basis" "0"
        , Css.property "min-width" "0"
        , Css.property "padding-bottom" "40px"
        ]
    , Css.Global.class "pkg-title"
        [ Css.property "font-size" "44px"
        , Css.property "line-height" "1.2"
        , weight 400
        , Css.property "margin" "32px 0 16px 0"
        , Css.property "overflow-wrap" "anywhere"
        , mobile [ Css.property "font-size" "32px", Css.property "margin" "24px 0 12px 0" ]
        ]
    , Css.Global.class "pkg-subtitle"
        [ Css.property "font-size" "18px"
        , Css.property "line-height" "1.5"
        , Css.property "color" colors.muted
        , Css.property "margin" "0 0 16px 0"
        ]
    ]



-- BAND


bandStyles : List Css.Global.Snippet
bandStyles =
    [ Css.Global.class "pkg-band"
        [ relative
        , Css.property "background-color" colors.band
        , Css.property "color" "#FFFFFF"
        , Css.property "padding" "0 20px"
        , mobile [ Css.property "padding" "0 16px" ]
        ]
    , Css.Global.class "pkg-band-inner"
        [ row
        , alignItems "center"
        , spaceBetween
        , gap 4
        , Css.property "max-width" contentWidth
        , Css.property "height" "64px"
        , Css.property "margin" "0 auto"
        ]
    , Css.Global.class "pkg-band-start"
        [ row
        , alignItems "baseline"
        , Css.property "min-width" "0"
        , Css.property "white-space" "nowrap"
        , Css.property "overflow" "hidden"
        ]
    , Css.Global.class "pkg-logo"
        [ row
        , alignItems "baseline"
        , gap 2
        , noUnderline
        , noShrink
        , Css.property "color" "#FFFFFF"
        ]
    , Css.Global.class "pkg-logo-mark"
        [ weight 700
        , Css.property "font-family" fontLogo
        , Css.property "font-size" "26px"
        , Css.property "letter-spacing" "1px"
        ]
    , Css.Global.class "pkg-logo-word"
        [ Css.property "font-size" "20px"
        ]
    , Css.Global.class "pkg-crumbs"
        [ row
        , alignItems "baseline"
        , Css.property "font-size" "20px"
        , Css.property "min-width" "0"
        , mobile [ hidden ]
        ]
    , Css.Global.class "pkg-crumb-sep"
        [ Css.property "margin" "0 10px"
        , Css.property "opacity" "0.7"
        ]
    , Css.Global.class "pkg-crumb"
        [ noUnderline
        , hoverUnderline
        , Css.property "color" "#FFFFFF"
        ]
    , Css.Global.class "pkg-crumb-current"
        [ Css.property "overflow" "hidden"
        , Css.property "text-overflow" "ellipsis"
        ]
    , Css.Global.class "pkg-band-end"
        [ row
        , alignItems "center"
        , gap 3
        , noShrink
        ]
    , Css.Global.class "pkg-band-home"
        [ row
        , alignItems "center"
        , gap 1.5
        , noUnderline
        , hoverUnderline
        , Css.property "color" "#FFFFFF"
        , Css.property "font-size" "15px"
        , weight 500
        ]
    ]



-- PHONE MENU


{-| On a phone the right-hand menu does not fit beside the content, so it moves into a menu that opens from the band:
a `<details>` element, which opens and closes without any Elm state.
-}
menuStyles : List Css.Global.Snippet
menuStyles =
    [ Css.Global.class "pkg-menu"
        [ hidden
        , mobile [ block ]
        ]
    , Css.Global.class "pkg-menu-button"
        [ row
        , alignItems "center"
        , Css.property "justify-content" "center"
        , Css.property "width" "40px"
        , Css.property "height" "40px"
        , Css.property "margin-right" "-8px"
        , Css.property "cursor" "pointer"
        , Css.property "list-style" "none"
        , Css.property "color" "#FFFFFF"
        ]
    , Css.Global.selector ".pkg-menu-button::-webkit-details-marker"
        [ hidden
        ]
    , Css.Global.class "pkg-menu-icon-close"
        [ hidden
        ]
    , Css.Global.selector ".pkg-menu[open] .pkg-menu-icon-open"
        [ hidden
        ]
    , Css.Global.selector ".pkg-menu[open] .pkg-menu-icon-close"
        [ block
        ]
    , Css.Global.class "pkg-menu-panel"
        [ Css.property "position" "absolute"
        , Css.property "top" "100%"
        , Css.property "left" "0"
        , Css.property "right" "0"
        , Css.property "z-index" "10"
        , Css.property "max-height" "calc(100vh - 64px)"
        , Css.property "overflow-y" "auto"
        , Css.property "padding" "8px 16px 20px"
        , Css.property "background-color" "#FFFFFF"
        , Css.property "color" colors.text
        , Css.property "border-bottom" ("1px solid " ++ colors.rule)
        , Css.property "box-shadow" "0 12px 24px rgba(0, 0, 0, 0.08)"
        ]
    ]



-- RIGHT-HAND MENU


navStyles : List Css.Global.Snippet
navStyles =
    [ Css.Global.class "pkg-side"
        [ noShrink
        , Css.property "width" "240px"
        , Css.property "margin" "32px 0 32px 40px"
        , Css.property "padding" "0 0 0 20px"
        , Css.property "border-left" ("1px solid " ++ colors.rule)
        , Css.property "position" "sticky"
        , Css.property "top" "0"
        , Css.property "max-height" "100vh"
        , Css.property "overflow-y" "auto"
        , mobile [ hidden ]
        ]
    , Css.Global.class "pkg-nav-heading"
        [ Css.property "font-size" "20px"
        , weight 400
        , Css.property "margin" "20px 0 8px 0"
        ]
    , Css.Global.selector ".pkg-nav > .pkg-nav-heading:first-child"
        [ Css.property "margin-top" "0"
        ]
    , Css.Global.class "pkg-nav-list"
        [ column
        ]
    , Css.Global.class "pkg-nav-link"
        [ block
        , noUnderline
        , hoverUnderline
        , Css.property "padding" "2px 0"
        , Css.property "color" colors.link
        , Css.property "font-size" "15px"
        , Css.property "overflow" "hidden"
        , Css.property "text-overflow" "ellipsis"
        , Css.property "white-space" "nowrap"
        ]
    , Css.Global.class "pkg-nav-link-current"
        [ block
        , Css.property "padding" "2px 0"
        , Css.property "color" colors.text
        , Css.property "font-size" "15px"
        , weight 600
        ]
    , Css.Global.class "pkg-nav-module"
        [ block
        , noUnderline
        , hoverUnderline
        , Css.property "padding" "2px 0"
        , Css.property "color" colors.link
        , Css.property "font-family" fontCode
        , Css.property "font-size" "14px"
        , Css.property "overflow" "hidden"
        , Css.property "text-overflow" "ellipsis"
        , Css.property "white-space" "nowrap"
        ]
    , Css.Global.class "pkg-nav-module-current"
        [ block
        , Css.property "padding" "2px 0"
        , Css.property "color" colors.text
        , Css.property "font-family" fontCode
        , Css.property "font-size" "14px"
        , weight 500
        ]
    , Css.Global.class "pkg-about"
        [ column
        , gap 1
        , Css.property "font-size" "14px"
        , Css.property "line-height" "1.5"
        ]
    , Css.Global.class "pkg-about-row"
        [ row
        , gap 2
        , alignItems "baseline"
        ]
    , Css.Global.class "pkg-about-label"
        [ Css.property "color" colors.muted
        , Css.property "width" "64px"
        , noShrink
        ]
    , Css.Global.class "pkg-about-code"
        [ Css.property "font-family" fontCode
        , Css.property "font-size" "13px"
        ]
    ]



-- PACKAGE LIST


catalogStyles : List Css.Global.Snippet
catalogStyles =
    [ Css.Global.class "pkg-summary"
        [ Css.property "padding" "20px 0"
        , Css.property "border-bottom" ("1px solid " ++ colors.rule)
        ]
    , Css.Global.class "pkg-summary-head"
        [ row
        , alignItems "baseline"
        , spaceBetween
        , gap 4
        ]
    , Css.Global.class "pkg-summary-name"
        [ noUnderline
        , hoverUnderline
        , Css.property "font-size" "24px"
        , Css.property "color" colors.link
        ]
    , Css.Global.class "pkg-summary-version"
        [ Css.property "color" colors.muted
        , Css.property "font-size" "15px"
        ]
    , Css.Global.class "pkg-summary-desc"
        [ Css.property "margin" "8px 0 0 0"
        , Css.property "line-height" "1.5"
        ]
    , Css.Global.class "pkg-dependency-version"
        [ Css.property "margin-left" "12px"
        , Css.property "color" colors.muted
        , Css.property "font-family" fontCode
        , Css.property "font-size" "13px"
        ]
    ]



-- DECLARATIONS


{-| A declaration's header sits on the left edge, in line with the section headings, and its doc comment is inset
below it, so the declarations stand out down the left of the page.
-}
declarationStyles : List Css.Global.Snippet
declarationStyles =
    [ Css.Global.class "pkg-decl"
        [ Css.property "margin" "16px 0 32px 0"
        , Css.property "border-top" ("1px solid " ++ colors.rule)
        , Css.property "scroll-margin-top" "8px"
        ]
    , Css.Global.class "pkg-decl-header"
        [ Css.property "margin" "0"
        , Css.property "padding" "10px 0"
        , Css.property "overflow-x" "auto"
        , Css.property "contain" "inline-size"
        , Css.property "white-space" "pre"
        , Css.property "font-family" fontCode
        , Css.property "font-size" "16px"
        , Css.property "line-height" "1.5"
        , Css.property "color" colors.text
        , mobile [ Css.property "font-size" "14px" ]
        ]
    , Css.Global.class "pkg-decl-name"
        [ weight 600
        , noUnderline
        , hoverUnderline
        , Css.property "color" colors.link
        ]
    , Css.Global.class "pkg-decl-keyword"
        [ Css.property "color" colors.muted
        ]
    , Css.Global.class "pkg-decl-type"
        [ noUnderline
        , hoverUnderline
        , Css.property "color" colors.link
        ]
    , Css.Global.class "pkg-decl-comment"
        [ Css.property "padding-left" "36px"
        , Css.property "min-width" "0"
        , mobile [ Css.property "padding-left" "16px" ]
        ]
    , Css.Global.selector ".pkg-decl-comment > :first-child"
        [ Css.property "margin-top" "4px"
        ]
    ]



-- MARKDOWN


markdownStyles : List Css.Global.Snippet
markdownStyles =
    [ Css.Global.class "pkg-md-h1"
        [ Css.property "font-size" "32px"
        , Css.property "line-height" "1.25"
        , weight 400
        , Css.property "margin" "48px 0 12px 0"
        , mobile [ Css.property "font-size" "26px", Css.property "margin-top" "36px" ]
        ]
    , Css.Global.class "pkg-md-h2"
        [ Css.property "font-size" "24px"
        , Css.property "line-height" "1.3"
        , weight 400
        , Css.property "margin" "36px 0 10px 0"
        ]
    , Css.Global.class "pkg-md-h3"
        [ Css.property "font-size" "19px"
        , Css.property "line-height" "1.4"
        , weight 600
        , Css.property "margin" "28px 0 8px 0"
        ]
    , Css.Global.class "pkg-md-h4"
        [ Css.property "font-size" "16px"
        , weight 600
        , Css.property "margin" "20px 0 8px 0"
        ]
    , Css.Global.class "pkg-md-p"
        [ Css.property "line-height" "1.6"
        , Css.property "margin" "12px 0"
        ]
    , Css.Global.class "pkg-md-ul"
        [ Css.property "list-style" "disc"
        , Css.property "padding-left" "28px"
        , Css.property "margin" "12px 0"
        ]
    , Css.Global.class "pkg-md-ol"
        [ Css.property "list-style" "decimal"
        , Css.property "padding-left" "28px"
        , Css.property "margin" "12px 0"
        ]
    , Css.Global.class "pkg-md-li"
        [ Css.property "line-height" "1.6"
        , Css.property "margin" "4px 0"
        ]
    , Css.Global.class "pkg-md-blockquote"
        [ Css.property "margin" "12px 0"
        , Css.property "padding" "0 16px"
        , Css.property "border-left" ("4px solid " ++ colors.rule)
        , Css.property "color" "#555555"
        ]
    , Css.Global.class "pkg-md-code"
        [ Css.property "font-family" fontCode
        , Css.property "font-size" "0.85em"
        , Css.property "padding" "0.1em 0.25em"
        , Css.property "background-color" "rgba(0, 0, 0, 0.045)"
        , Css.property "border-radius" "3px"
        , Css.property "overflow-wrap" "anywhere"
        ]
    , Css.Global.class "pkg-md-pre"
        [ Css.property "margin" "12px 0"
        , Css.property "contain" "inline-size"
        ]

    -- More specific than the highlight theme's `.elmsh`, so that the block keeps this background and border.
    , Css.Global.selector ".pkg-md-pre pre"
        [ Css.property "margin" "0"
        , Css.property "padding" "10px 12px"
        , Css.property "overflow-x" "auto"
        , Css.property "background-color" colors.codeBg
        , Css.property "border" ("1px solid " ++ colors.codeBorder)
        , Css.property "border-radius" "6px"
        , Css.property "font-family" fontCode
        , Css.property "font-size" "14px"
        , Css.property "line-height" "1.5"
        ]
    , Css.Global.selector ".pkg-md-pre code"
        [ Css.property "font-family" fontCode
        ]
    , Css.Global.class "pkg-md-link"
        [ noUnderline
        , hoverUnderline
        , Css.property "color" colors.link
        ]
    , Css.Global.class "pkg-md-strong"
        [ weight 600
        ]
    , Css.Global.class "pkg-md-hr"
        [ Css.property "height" "1px"
        , Css.property "background-color" colors.rule
        , Css.property "margin" "24px 0"
        ]
    , Css.Global.class "pkg-md-img"
        [ Css.property "max-width" "100%"
        , Css.property "height" "auto"
        ]
    , Css.Global.class "pkg-md-table-wrap"
        [ Css.property "margin" "12px 0"
        , Css.property "overflow-x" "auto"
        , Css.property "contain" "inline-size"
        ]
    , Css.Global.class "pkg-md-table"
        [ Css.property "border-collapse" "collapse"
        ]
    , Css.Global.class "pkg-md-cell"
        [ Css.property "padding" "6px 12px"
        , Css.property "border" ("1px solid " ++ colors.rule)
        , Css.property "text-align" "left"
        , Css.property "line-height" "1.5"
        ]
    ]



-- FOOTER


footerStyles : List Css.Global.Snippet
footerStyles =
    [ Css.Global.class "pkg-footer"
        [ row
        , Css.property "justify-content" "center"
        , Css.property "flex-wrap" "wrap"
        , Css.property "gap" "4px 20px"
        , Css.property "margin-top" "48px"
        , Css.property "padding" "28px 16px"
        , Css.property "border-top" ("1px solid " ++ colors.rule)
        , Css.property "color" "#AAAAAA"
        , Css.property "font-size" "14px"
        ]
    , Css.Global.class "pkg-footer-link"
        [ Css.property "color" "#AAAAAA"
        , Css.property "text-decoration" "underline"
        ]
    ]
