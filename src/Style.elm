module Style exposing (Colors, colors, styleNode)

import Css
import Css.Global
import Html
import Html.Styled



-- DESIGN TOKENS


type alias Colors =
    { accent : String
    , text : String
    , heading : String
    , muted : String
    , border : String
    , bg : String
    , bgWhite : String
    , bgCode : String
    , currentBlue : String
    , currentBlueBg : String
    , currentBlueBadge : String
    , futureGray : String
    , futureGrayBg : String
    , releasedGreenBg : String
    , editorBg : String
    , editorDotRed : String
    , editorDotYellow : String
    , editorDotGreen : String
    , editorFilename : String
    , syntaxKeyword : String
    , syntaxFunction : String
    , syntaxString : String
    , syntaxComment : String
    , syntaxSymbol : String
    , syntaxDefault : String
    , tableBg : String
    , tableHeaderBg : String
    }


colors : Colors
colors =
    quietWarmth


original : Colors
original =
    { accent = "#4CAF50"
    , text = "#242424"
    , heading = "#646464"
    , muted = "#999999"
    , border = "#E0E0E0"
    , bg = "#F8F8F8"
    , bgWhite = "#FFFFFF"
    , bgCode = "#2D2D2D"
    , currentBlue = "#2E86FF"
    , currentBlueBg = "#F5F8FF"
    , currentBlueBadge = "#DBEAFE"
    , futureGray = "#CCCCCC"
    , futureGrayBg = "#F0F0F0"
    , releasedGreenBg = "#E8F5E9"
    , editorBg = "#1E1E1E"
    , editorDotRed = "#FF5F57"
    , editorDotYellow = "#FEBC2E"
    , editorDotGreen = "#28C840"
    , editorFilename = "#888888"
    , syntaxKeyword = "#E5994A"
    , syntaxFunction = "#DCDCAA"
    , syntaxString = "#7FC777"
    , syntaxComment = "#6A9955"
    , syntaxSymbol = "#82D4F0"
    , syntaxDefault = "#E8E8E8"
    , tableBg = "#F2F2F2"
    , tableHeaderBg = "#FAFAFA"
    }


warmLinen : Colors
warmLinen =
    { accent = "#4CAF50"
    , text = "#2D2D2D"
    , heading = "#4A453C"
    , muted = "#A09A92"
    , border = "#E8E4DC"
    , bg = "#FCFBF9"
    , bgWhite = "#F5F2EC"
    , bgCode = "#2D2D2D"
    , currentBlue = "#2E86FF"
    , currentBlueBg = "#F5F8FF"
    , currentBlueBadge = "#DBEAFE"
    , futureGray = "#CCCCCC"
    , futureGrayBg = "#EEEAE4"
    , releasedGreenBg = "#E8F5E9"
    , editorBg = "#1E1E1E"
    , editorDotRed = "#FF5F57"
    , editorDotYellow = "#FEBC2E"
    , editorDotGreen = "#28C840"
    , editorFilename = "#888888"
    , syntaxKeyword = "#E5994A"
    , syntaxFunction = "#DCDCAA"
    , syntaxString = "#7FC777"
    , syntaxComment = "#6A9955"
    , syntaxSymbol = "#82D4F0"
    , syntaxDefault = "#E8E8E8"
    , tableBg = "#EEEAE4"
    , tableHeaderBg = "#F5F2EC"
    }


quietWarmth : Colors
quietWarmth =
    { accent = "#4CAF50"
    , text = "#1C1917"
    , heading = "#44403C"
    , muted = "#9E9890"
    , border = "#DDD8CE"
    , bg = "#FDFCFA"
    , bgWhite = "#FFFFFF"
    , bgCode = "#2D2D2D"
    , currentBlue = "#2E86FF"
    , currentBlueBg = "#F5F8FF"
    , currentBlueBadge = "#DBEAFE"
    , futureGray = "#CCCCCC"
    , futureGrayBg = "#F0EDE7"
    , releasedGreenBg = "#E8F5E9"
    , editorBg = "#1E1E1E"
    , editorDotRed = "#FF5F57"
    , editorDotYellow = "#FEBC2E"
    , editorDotGreen = "#28C840"
    , editorFilename = "#888888"
    , syntaxKeyword = "#E5994A"
    , syntaxFunction = "#DCDCAA"
    , syntaxString = "#7FC777"
    , syntaxComment = "#6A9955"
    , syntaxSymbol = "#82D4F0"
    , syntaxDefault = "#E8E8E8"
    , tableBg = "#F0EDE7"
    , tableHeaderBg = "#F7F4EF"
    }


fontHeading : String
fontHeading =
    "Montserrat, sans-serif"


fontBody : String
fontBody =
    "Inter, sans-serif"


fontCode : String
fontCode =
    "Roboto Mono, monospace"



-- STYLE NODE


styleNode : Html.Html msg
styleNode =
    Css.Global.global style
        |> Html.Styled.toUnstyled


style : List Css.Global.Snippet
style =
    List.concat
        [ pageStyles
        , typographyStyles
        , headerFooterStyles
        , heroStyles
        , sectionStyles
        , codeBlockStyles
        , buttonStyles
        , sidebarStyles
        , contentAreaStyles
        , docStyles
        , aboutStyles
        , roadmapStyles
        , homepageStyles
        ]



-- PAGE-LEVEL


pageStyles : List Css.Global.Snippet
pageStyles =
    [ Css.Global.class "eco-page"
        [ Css.property "background-color" colors.bg
        , Css.property "font-family" fontBody
        ]
    , Css.Global.class "eco-section-white"
        [ Css.property "background-color" colors.bgWhite
        ]
    , Css.Global.class "eco-content-wrapper"
        [ Css.property "max-width" "1200px"
        , Css.property "margin" "0 auto"
        ]
    , Css.Global.class "eco-content-wrapper-full"
        [ Css.property "max-width" "1200px"
        , Css.property "margin" "0 auto"
        , Css.property "width" "100%"
        ]
    , Css.Global.class "eco-divider"
        [ Css.property "height" "1px"
        , Css.property "background-color" colors.border
        ]
    ]



-- TYPOGRAPHY UTILITIES


typographyStyles : List Css.Global.Snippet
typographyStyles =
    [ Css.Global.class "eco-text"
        [ Css.property "color" colors.text
        ]
    , Css.Global.class "eco-text-heading"
        [ Css.property "color" colors.heading
        ]
    , Css.Global.class "eco-text-muted"
        [ Css.property "color" colors.muted
        ]
    , Css.Global.class "eco-text-accent"
        [ Css.property "color" colors.accent
        ]
    , Css.Global.class "eco-text-light"
        [ Css.property "color" colors.border
        ]
    , Css.Global.class "eco-font-heading"
        [ Css.property "font-family" fontHeading
        ]
    , Css.Global.class "eco-font-body"
        [ Css.property "font-family" fontBody
        ]
    , Css.Global.class "eco-font-code"
        [ Css.property "font-family" fontCode
        ]
    ]



-- HEADER & FOOTER


headerFooterStyles : List Css.Global.Snippet
headerFooterStyles =
    [ Css.Global.class "eco-header"
        [ Css.property "background-color" colors.bg
        ]
    , Css.Global.class "eco-header-logo"
        [ Css.property "color" colors.accent
        , Css.property "font-family" fontHeading
        , Css.property "letter-spacing" "1px"
        ]
    , Css.Global.class "eco-header-badge"
        [ Css.property "color" colors.accent
        , Css.property "background-color" "rgba(76, 175, 80, 0.1)"
        , Css.property "letter-spacing" "0.5px"
        ]
    , Css.Global.class "eco-nav-link"
        [ Css.property "font-family" fontBody
        , Css.property "color" colors.heading
        ]
    , Css.Global.class "eco-nav-link-active"
        [ Css.property "font-family" fontBody
        , Css.property "color" colors.text
        , Css.property "font-weight" "600"
        ]
    , Css.Global.class "eco-footer"
        [ Css.property "max-width" "1200px"
        , Css.property "margin" "0 auto"
        , Css.property "width" "100%"
        ]
    , Css.Global.class "eco-footer-logo"
        [ Css.property "color" colors.accent
        , Css.property "font-family" fontHeading
        , Css.property "letter-spacing" "0.5px"
        ]
    ]



-- HERO


heroStyles : List Css.Global.Snippet
heroStyles =
    [ Css.Global.class "eco-hero"
        [ Css.property "background-color" colors.bgWhite
        , Css.property "height" "420px"
        ]
    , Css.Global.class "eco-hero-title"
        [ Css.property "color" colors.text
        , Css.property "font-family" fontHeading
        , Css.property "letter-spacing" "-2px"
        ]
    , Css.Global.class "eco-hero-subtitle"
        [ Css.property "color" colors.heading
        , Css.property "font-family" fontHeading
        , Css.property "letter-spacing" "3px"
        ]
    , Css.Global.class "eco-hero-accent-bar"
        [ Css.property "width" "64px"
        , Css.property "height" "3px"
        , Css.property "background-color" colors.accent
        ]
    , Css.Global.class "eco-hero-sparkle-text"
        [ Css.property "color" colors.accent
        , Css.property "letter-spacing" "0.5px"
        ]
    ]



-- SECTIONS


sectionStyles : List Css.Global.Snippet
sectionStyles =
    [ Css.Global.class "eco-section-heading"
        [ Css.property "color" colors.heading
        , Css.property "font-family" fontHeading
        , Css.property "letter-spacing" "-0.5px"
        ]
    , Css.Global.class "eco-section-desc"
        [ Css.property "color" colors.muted
        , Css.property "max-width" "620px"
        , Css.property "line-height" "1.6"
        ]
    , Css.Global.class "eco-feature-card"
        [ Css.property "background-color" colors.bgWhite
        , Css.property "border" ("1px solid " ++ colors.border)
        ]
    , Css.Global.class "eco-feature-card-title"
        [ Css.property "color" colors.text
        , Css.property "font-family" fontHeading
        ]
    , Css.Global.class "eco-feature-card-desc"
        [ Css.property "color" colors.heading
        , Css.property "line-height" "1.7"
        ]
    ]



-- CODE BLOCKS


codeBlockStyles : List Css.Global.Snippet
codeBlockStyles =
    [ Css.Global.class "eco-code-block"
        [ Css.property "background-color" colors.bgCode
        , Css.property "font-family" fontCode
        , Css.property "font-size" "14px"
        , Css.property "line-height" "1.6"
        ]
    , Css.Global.class "eco-code-comment"
        [ Css.property "color" colors.muted
        ]
    , Css.Global.class "eco-code-text"
        [ Css.property "color" colors.border
        ]
    , Css.Global.class "eco-code-empty"
        [ Css.property "color" colors.border
        , Css.property "line-height" "1"
        ]
    , Css.Global.class "eco-code-output"
        [ Css.property "color" colors.accent
        ]
    ]



-- BUTTONS


buttonStyles : List Css.Global.Snippet
buttonStyles =
    [ Css.Global.class "eco-btn-primary"
        [ Css.property "background-color" colors.accent
        ]
    , Css.Global.class "eco-btn-secondary"
        [ Css.property "color" colors.heading
        , Css.property "border" ("1px solid " ++ colors.border)
        ]
    ]



-- SIDEBAR


sidebarStyles : List Css.Global.Snippet
sidebarStyles =
    [ Css.Global.class "eco-sidebar"
        [ Css.property "width" "280px"
        , Css.property "background-color" colors.bgWhite
        , Css.property "border-right" ("1px solid " ++ colors.border)
        , Css.property "padding" "32px 0 32px 72px"
        ]
    , Css.Global.class "eco-sidebar-title"
        [ Css.property "color" colors.muted
        , Css.property "font-family" fontHeading
        , Css.property "letter-spacing" "1.5px"
        ]
    , Css.Global.class "eco-sidebar-spacer"
        [ Css.property "height" "20px"
        ]
    , Css.Global.class "eco-toc-section"
        [ Css.property "padding" "10px 0"
        ]
    , Css.Global.class "eco-toc-section-name"
        [ Css.property "color" colors.text
        , Css.property "font-family" fontBody
        , Css.property "font-size" "13px"
        ]
    , Css.Global.class "eco-toc-items"
        [ Css.property "padding-left" "12px"
        ]
    , Css.Global.class "eco-toc-gap"
        [ Css.property "height" "8px"
        ]
    , Css.Global.class "eco-toc-item"
        [ Css.property "padding" "7px 12px"
        , Css.property "font-size" "13px"
        , Css.property "font-family" fontBody
        , Css.property "text-decoration" "none"
        , Css.property "color" colors.heading
        ]
    , Css.Global.class "eco-toc-item-active"
        [ Css.property "padding" "7px 12px"
        , Css.property "font-size" "13px"
        , Css.property "font-family" fontBody
        , Css.property "text-decoration" "none"
        , Css.property "color" colors.accent
        , Css.property "font-weight" "500"
        , Css.property "border-left" ("2px solid " ++ colors.accent)
        ]
    ]



-- CONTENT AREA


contentAreaStyles : List Css.Global.Snippet
contentAreaStyles =
    [ Css.Global.class "eco-content-area"
        [ Css.property "background-color" colors.bg
        , Css.property "padding" "48px 80px 64px 64px"
        ]
    , Css.Global.class "eco-breadcrumb"
        [ Css.property "margin-bottom" "32px"
        ]
    , Css.Global.class "eco-breadcrumb-text"
        [ Css.property "color" colors.muted
        , Css.property "font-size" "13px"
        ]
    , Css.Global.class "eco-breadcrumb-active"
        [ Css.property "color" colors.text
        , Css.property "font-size" "13px"
        ]
    , Css.Global.class "eco-page-header"
        [ Css.property "margin-bottom" "32px"
        ]
    , Css.Global.class "eco-page-title"
        [ Css.property "color" colors.heading
        , Css.property "font-family" fontHeading
        , Css.property "letter-spacing" "-0.5px"
        , Css.property "font-size" "36px"
        ]
    , Css.Global.class "eco-page-desc"
        [ Css.property "color" colors.heading
        , Css.property "font-family" fontBody
        , Css.property "font-size" "17px"
        , Css.property "line-height" "1.7"
        ]
    , Css.Global.class "eco-article-body"
        [ Css.property "color" colors.text
        , Css.property "font-family" fontBody
        ]
    , Css.Global.class "eco-content-divider"
        [ Css.property "height" "1px"
        , Css.property "background-color" colors.border
        , Css.property "margin" "32px 0"
        ]
    , Css.Global.class "eco-page-nav-label"
        [ Css.property "color" colors.muted
        ]
    , Css.Global.class "eco-page-nav-title"
        [ Css.property "color" colors.accent
        , Css.property "font-size" "15px"
        ]
    ]



-- DOCS / MARKDOWN


docStyles : List Css.Global.Snippet
docStyles =
    [ Css.Global.class "eco-doc-code-block"
        [ Css.property "background-color" colors.bgCode
        , Css.property "padding" "24px"
        , Css.property "margin" "18px 0"
        , Css.property "overflow-x" "auto"
        ]
    , Css.Global.class "eco-doc-code-fallback"
        [ Css.property "margin" "0"
        , Css.property "font-family" fontCode
        , Css.property "font-size" "14px"
        , Css.property "line-height" "24px"
        , Css.property "color" colors.border
        ]
    , Css.Global.class "eco-doc-h1"
        [ Css.property "font-family" fontHeading
        , Css.property "font-weight" "600"
        , Css.property "color" colors.heading
        , Css.property "font-size" "36px"
        , Css.property "line-height" "48px"
        , Css.property "margin" "0 0 18px 0"
        ]
    , Css.Global.class "eco-doc-h2"
        [ Css.property "font-family" fontHeading
        , Css.property "font-weight" "600"
        , Css.property "color" colors.heading
        , Css.property "font-size" "24px"
        , Css.property "line-height" "30px"
        , Css.property "margin" "30px 0 18px 0"
        ]
    , Css.Global.class "eco-doc-h3"
        [ Css.property "font-family" fontHeading
        , Css.property "font-weight" "600"
        , Css.property "color" colors.heading
        , Css.property "font-size" "20px"
        , Css.property "line-height" "24px"
        , Css.property "margin" "24px 0 12px 0"
        ]
    , Css.Global.class "eco-doc-h4"
        [ Css.property "font-family" fontHeading
        , Css.property "font-weight" "600"
        , Css.property "color" colors.heading
        , Css.property "font-size" "18px"
        , Css.property "line-height" "24px"
        , Css.property "margin" "18px 0 12px 0"
        ]
    , Css.Global.class "eco-doc-paragraph"
        [ Css.property "font-family" fontBody
        , Css.property "font-size" "17.5px"
        , Css.property "line-height" "30px"
        , Css.property "color" colors.text
        , Css.property "margin" "0 0 18px 0"
        ]
    , Css.Global.class "eco-doc-blockquote"
        [ Css.property "border-left" ("3px solid " ++ colors.accent)
        , Css.property "background-color" "rgba(76, 175, 80, 0.04)"
        , Css.property "padding" "18px 24px 6px 24px"
        , Css.property "margin" "24px 0 18px 0"
        ]
    , Css.Global.class "eco-doc-code-inline"
        [ Css.property "font-family" fontCode
        , Css.property "font-size" "0.9em"
        , Css.property "background-color" "rgba(76, 175, 80, 0.08)"
        , Css.property "padding" "2px 6px"
        , Css.property "border-radius" "3px"
        , Css.property "color" colors.text
        ]
    , Css.Global.class "eco-doc-ul"
        [ Css.property "list-style" "none"
        , Css.property "padding-left" "4px"
        , Css.property "margin" "6px 0 18px 0"
        ]
    , Css.Global.class "eco-doc-li"
        [ Css.property "display" "flex"
        , Css.property "align-items" "baseline"
        , Css.property "gap" "12px"
        , Css.property "font-family" fontBody
        , Css.property "font-size" "16.5px"
        , Css.property "line-height" "30px"
        , Css.property "color" colors.text
        , Css.property "margin-bottom" "6px"
        ]
    , Css.Global.class "eco-doc-bullet"
        [ Css.property "width" "5px"
        , Css.property "height" "5px"
        , Css.property "min-width" "5px"
        , Css.property "background-color" colors.accent
        , Css.property "border-radius" "3px"
        , Css.property "display" "inline-block"
        , Css.property "margin-top" "6px"
        , Css.property "flex-shrink" "0"
        ]
    , Css.Global.class "eco-doc-bullet-text"
        [ Css.property "flex" "1"
        ]
    , Css.Global.class "eco-doc-ol"
        [ Css.property "padding-left" "18px"
        , Css.property "margin" "6px 0 18px 0"
        ]
    , Css.Global.class "eco-doc-ol-li"
        [ Css.property "font-family" fontBody
        , Css.property "font-size" "16.5px"
        , Css.property "line-height" "30px"
        , Css.property "color" colors.text
        , Css.property "margin-bottom" "6px"
        ]
    , Css.Global.class "eco-doc-table"
        [ Css.property "width" "100%"
        , Css.property "border-collapse" "collapse"
        , Css.property "border" ("1px solid " ++ colors.border)
        , Css.property "margin" "18px 0"
        ]
    , Css.Global.class "eco-doc-thead"
        [ Css.property "background-color" colors.tableBg
        ]
    , Css.Global.class "eco-doc-tr"
        [ Css.property "border-top" ("1px solid " ++ colors.border)
        ]
    , Css.Global.class "eco-doc-th"
        [ Css.property "padding" "12px 16px"
        , Css.property "text-align" "left"
        , Css.property "font-family" fontBody
        , Css.property "font-size" "13px"
        , Css.property "font-weight" "600"
        , Css.property "color" colors.text
        ]
    , Css.Global.class "eco-doc-td"
        [ Css.property "padding" "12px 16px"
        , Css.property "font-family" fontBody
        , Css.property "font-size" "14px"
        , Css.property "color" colors.text
        ]
    , Css.Global.class "eco-doc-hr"
        [ Css.property "border" "none"
        , Css.property "height" "1px"
        , Css.property "background-color" colors.border
        , Css.property "margin" "30px 0"
        ]
    , Css.Global.class "eco-doc-strong"
        [ Css.property "font-weight" "600"
        ]
    , Css.Global.class "eco-doc-link"
        [ Css.property "color" colors.accent
        , Css.property "text-decoration" "none"
        ]
    ]



-- ABOUT PAGE


aboutStyles : List Css.Global.Snippet
aboutStyles =
    [ Css.Global.class "eco-about-container"
        [ Css.property "max-width" "1200px"
        , Css.property "margin" "0 auto"
        , Css.property "padding" "56px 24px"
        , Css.property "font-family" fontBody
        ]
    , Css.Global.class "eco-about-title"
        [ Css.property "font-family" fontHeading
        , Css.property "font-size" "42px"
        , Css.property "font-weight" "700"
        , Css.property "color" colors.text
        , Css.property "margin" "0 0 24px 0"
        ]
    , Css.Global.class "eco-about-divider"
        [ Css.property "height" "1px"
        , Css.property "background-color" colors.border
        , Css.property "margin-bottom" "48px"
        ]
    , Css.Global.class "eco-about-layout"
        [ Css.property "display" "flex"
        , Css.property "gap" "56px"
        , Css.property "align-items" "flex-start"
        ]
    , Css.Global.class "eco-profile-card"
        [ Css.property "display" "flex"
        , Css.property "flex-direction" "column"
        , Css.property "align-items" "center"
        , Css.property "gap" "4px"
        , Css.property "min-width" "220px"
        , Css.property "width" "220px"
        , Css.property "padding-top" "8px"
        ]
    , Css.Global.class "eco-avatar"
        [ Css.property "width" "140px"
        , Css.property "height" "140px"
        , Css.property "border-radius" "70px"
        , Css.property "overflow" "hidden"
        , Css.property "margin-bottom" "16px"
        ]
    , Css.Global.class "eco-avatar-img"
        [ Css.property "width" "100%"
        , Css.property "height" "100%"
        , Css.property "object-fit" "cover"
        ]
    , Css.Global.class "eco-profile-name"
        [ Css.property "font-family" fontHeading
        , Css.property "font-size" "18px"
        , Css.property "font-weight" "600"
        , Css.property "color" colors.text
        , Css.property "text-align" "center"
        ]
    , Css.Global.class "eco-profile-occupation"
        [ Css.property "font-size" "13px"
        , Css.property "color" colors.heading
        , Css.property "text-align" "center"
        ]
    , Css.Global.class "eco-profile-company"
        [ Css.property "font-size" "13px"
        , Css.property "color" colors.muted
        , Css.property "text-align" "center"
        ]
    , Css.Global.class "eco-profile-accent"
        [ Css.property "width" "40px"
        , Css.property "height" "2px"
        , Css.property "background-color" colors.accent
        , Css.property "margin" "12px 0"
        ]
    , Css.Global.class "eco-social-link"
        [ Css.property "color" colors.muted
        , Css.property "transition" "color 0.2s"
        ]
    , Css.Global.class "eco-socials"
        [ Css.property "display" "flex"
        , Css.property "gap" "12px"
        , Css.property "align-items" "center"
        ]
    , Css.Global.class "eco-bio-content"
        [ Css.property "flex" "1"
        , Css.property "min-width" "0"
        ]
    ]



-- ROADMAP PAGE


roadmapStyles : List Css.Global.Snippet
roadmapStyles =
    [ -- Content area
      Css.Global.class "eco-roadmap-content"
        [ Css.property "padding" "48px 64px 64px 0"
        ]
    , Css.Global.class "eco-roadmap-title"
        [ Css.property "font-family" fontHeading
        , Css.property "font-size" "36px"
        , Css.property "font-weight" "700"
        , Css.property "color" colors.text
        , Css.property "letter-spacing" "-1px"
        ]
    , Css.Global.class "eco-roadmap-subtitle"
        [ Css.property "font-family" fontBody
        , Css.property "font-size" "17px"
        , Css.property "color" colors.heading
        , Css.property "line-height" "1.6"
        ]

    -- Sidebar nav items
    , Css.Global.class "eco-roadmap-nav-released"
        [ Css.property "padding" "7px 12px"
        , Css.property "font-family" fontBody
        , Css.property "font-size" "13px"
        , Css.property "color" colors.accent
        , Css.property "font-weight" "500"
        ]
    , Css.Global.class "eco-roadmap-nav-current"
        [ Css.property "padding" "7px 12px"
        , Css.property "font-family" fontBody
        , Css.property "font-size" "13px"
        , Css.property "color" colors.text
        , Css.property "font-weight" "600"
        , Css.property "background-color" colors.currentBlueBg
        , Css.property "border-left" "3px solid #4A9EFF"
        ]
    , Css.Global.class "eco-roadmap-nav-future"
        [ Css.property "padding" "7px 12px"
        , Css.property "font-family" fontBody
        , Css.property "font-size" "13px"
        , Css.property "color" colors.muted
        ]
    , Css.Global.class "eco-roadmap-nav-default"
        [ Css.property "padding" "7px 12px"
        , Css.property "font-family" fontBody
        , Css.property "font-size" "13px"
        , Css.property "color" colors.heading
        ]

    -- Nav dots
    , Css.Global.class "eco-roadmap-dot-released"
        [ Css.property "width" "6px"
        , Css.property "height" "6px"
        , Css.property "border-radius" "50%"
        , Css.property "background-color" colors.accent
        , Css.property "flex-shrink" "0"
        ]
    , Css.Global.class "eco-roadmap-dot-current"
        [ Css.property "width" "6px"
        , Css.property "height" "6px"
        , Css.property "border-radius" "50%"
        , Css.property "background-color" colors.currentBlue
        , Css.property "flex-shrink" "0"
        ]
    , Css.Global.class "eco-roadmap-dot-future"
        [ Css.property "width" "5px"
        , Css.property "height" "5px"
        , Css.property "border-radius" "50%"
        , Css.property "background-color" colors.futureGray
        , Css.property "flex-shrink" "0"
        ]

    -- Timeline station dots
    , Css.Global.class "eco-roadmap-station-released"
        [ Css.property "width" "16px"
        , Css.property "height" "16px"
        , Css.property "border-radius" "50%"
        , Css.property "background-color" colors.accent
        , Css.property "box-shadow" "0 0 0 3px #E8F5E9"
        , Css.property "flex-shrink" "0"
        ]
    , Css.Global.class "eco-roadmap-station-current"
        [ Css.property "width" "16px"
        , Css.property "height" "16px"
        , Css.property "border-radius" "50%"
        , Css.property "background-color" colors.currentBlue
        , Css.property "box-shadow" "0 0 0 3px #DBEAFE"
        , Css.property "flex-shrink" "0"
        ]
    , Css.Global.class "eco-roadmap-station-future"
        [ Css.property "width" "14px"
        , Css.property "height" "14px"
        , Css.property "border-radius" "50%"
        , Css.property "background-color" colors.bgWhite
        , Css.property "border" "2px solid #CCCCCC"
        , Css.property "flex-shrink" "0"
        ]
    -- Version badges
    , Css.Global.class "eco-roadmap-badge-released"
        [ Css.property "font-family" fontCode
        , Css.property "font-size" "13px"
        , Css.property "font-weight" "600"
        , Css.property "color" colors.accent
        , Css.property "background-color" colors.releasedGreenBg
        , Css.property "padding" "4px 10px"
        , Css.property "border-radius" "3px"
        ]
    , Css.Global.class "eco-roadmap-badge-current"
        [ Css.property "font-family" fontCode
        , Css.property "font-size" "13px"
        , Css.property "font-weight" "600"
        , Css.property "color" colors.currentBlue
        , Css.property "background-color" colors.currentBlueBadge
        , Css.property "padding" "4px 10px"
        , Css.property "border-radius" "3px"
        ]
    , Css.Global.class "eco-roadmap-badge-future"
        [ Css.property "font-family" fontCode
        , Css.property "font-size" "13px"
        , Css.property "font-weight" "600"
        , Css.property "color" colors.muted
        , Css.property "background-color" colors.futureGrayBg
        , Css.property "padding" "4px 10px"
        , Css.property "border-radius" "3px"
        ]

    -- Milestone title
    , Css.Global.class "eco-roadmap-milestone-title"
        [ Css.property "font-family" fontHeading
        , Css.property "font-size" "20px"
        , Css.property "font-weight" "700"
        , Css.property "color" colors.text
        , Css.property "letter-spacing" "-0.5px"
        ]

    -- Status tags
    , Css.Global.class "eco-roadmap-status-released"
        [ Css.property "font-family" fontBody
        , Css.property "font-size" "12px"
        , Css.property "font-weight" "500"
        , Css.property "color" colors.accent
        ]
    , Css.Global.class "eco-roadmap-status-current"
        [ Css.property "font-family" fontBody
        , Css.property "font-size" "11px"
        , Css.property "font-weight" "600"
        , Css.property "color" colors.bgWhite
        , Css.property "background-color" colors.currentBlue
        , Css.property "padding" "3px 8px"
        , Css.property "border-radius" "3px"
        ]
    , Css.Global.class "eco-roadmap-status-planned"
        [ Css.property "font-family" fontBody
        , Css.property "font-size" "12px"
        , Css.property "font-weight" "500"
        , Css.property "color" colors.muted
        ]

    -- Card content
    , Css.Global.class "eco-roadmap-desc"
        [ Css.property "font-family" fontBody
        , Css.property "font-size" "15px"
        , Css.property "color" colors.heading
        , Css.property "line-height" "1.6"
        ]
    , Css.Global.class "eco-roadmap-feature"
        [ Css.property "font-family" fontBody
        , Css.property "font-size" "14px"
        , Css.property "color" colors.heading
        ]
    , Css.Global.class "eco-roadmap-card-future"
        [ Css.property "opacity" "0.6"
        ]

    -- Timeline line
    , Css.Global.class "eco-roadmap-timeline"
        [ Css.property "position" "absolute"
        , Css.property "width" "2px"
        , Css.property "top" "0"
        , Css.property "bottom" "0"
        , Css.property "left" "279px"
        , Css.property "background-color" colors.border
        ]

    -- Milestone layout
    , Css.Global.class "eco-roadmap-milestone"
        [ Css.property "position" "relative"
        , Css.property "padding-left" "32px"
        ]
    , Css.Global.class "eco-roadmap-station-wrap"
        [ Css.property "position" "absolute"
        , Css.property "left" "-9px"
        , Css.property "top" "4px"
        ]
    , Css.Global.class "eco-roadmap-station-wrap-current"
        [ Css.property "position" "absolute"
        , Css.property "left" "-9px"
        , Css.property "top" "4px"
        ]
    , Css.Global.class "eco-roadmap-station-wrap-future"
        [ Css.property "position" "absolute"
        , Css.property "left" "-8px"
        , Css.property "top" "5px"
        ]
    ]



-- HOMEPAGE (VARIATION C)


homepageStyles : List Css.Global.Snippet
homepageStyles =
    [ -- Split Hero (Crystal Lattice variant)
      Css.Global.class "eco-home-hero"
        [ Css.property "position" "relative"
        , Css.property "overflow" "hidden"
        , Css.property "height" "440px"
        , Css.property "background" "radial-gradient(ellipse at 100% 100%, rgba(102,187,106,0.25) 0%, transparent 50%), radial-gradient(ellipse at 70% 100%, rgba(165,214,167,0.2) 0%, transparent 45%), radial-gradient(ellipse at 100% 50%, rgba(200,230,201,0.18) 0%, transparent 40%), radial-gradient(ellipse at 40% 80%, rgba(232,245,233,0.2) 0%, transparent 40%), #FFFFFF"
        ]
    , Css.Global.class "eco-home-hero-lattice"
        [ Css.property "position" "absolute"
        , Css.property "inset" "0"
        , Css.property "pointer-events" "none"
        , Css.property "z-index" "0"
        ]
    , Css.Global.class "eco-home-hero-content"
        [ Css.property "position" "relative"
        , Css.property "z-index" "1"
        ]
    , Css.Global.class "eco-home-accent-bar"
        [ Css.property "width" "64px"
        , Css.property "height" "3px"
        , Css.property "background-color" colors.accent
        ]
    , Css.Global.class "eco-home-badge"
        [ Css.property "background-color" colors.releasedGreenBg
        , Css.property "border-radius" "20px"
        , Css.property "padding" "5px 14px"
        ]
    , Css.Global.class "eco-home-badge-dot"
        [ Css.property "width" "8px"
        , Css.property "height" "8px"
        , Css.property "border-radius" "50%"
        , Css.property "background-color" colors.accent
        , Css.property "flex-shrink" "0"
        ]
    , Css.Global.class "eco-home-badge-text"
        [ Css.property "font-family" fontBody
        , Css.property "font-size" "13px"
        , Css.property "font-weight" "500"
        , Css.property "color" colors.accent
        ]
    , Css.Global.class "eco-home-title"
        [ Css.property "font-family" fontHeading
        , Css.property "font-size" "44px"
        , Css.property "font-weight" "700"
        , Css.property "color" colors.text
        , Css.property "letter-spacing" "-2px"
        , Css.property "line-height" "1.2"
        ]
    , Css.Global.class "eco-home-subtitle"
        [ Css.property "font-family" fontBody
        , Css.property "font-size" "17px"
        , Css.property "color" colors.heading
        , Css.property "line-height" "1.7"
        , Css.property "max-width" "460px"
        ]

    -- Editor mockup
    , Css.Global.class "eco-home-editor"
        [ Css.property "background-color" colors.editorBg
        , Css.property "border-radius" "8px"
        , Css.property "box-shadow" "0 8px 32px rgba(0, 0, 0, 0.13)"
        , Css.property "overflow" "hidden"
        ]
    , Css.Global.class "eco-home-editor-bar"
        [ Css.property "height" "36px"
        , Css.property "padding" "0 14px"
        , Css.property "background-color" colors.bgCode
        ]
    , Css.Global.class "eco-home-editor-dot-red"
        [ Css.property "width" "10px"
        , Css.property "height" "10px"
        , Css.property "border-radius" "50%"
        , Css.property "background-color" colors.editorDotRed
        ]
    , Css.Global.class "eco-home-editor-dot-yellow"
        [ Css.property "width" "10px"
        , Css.property "height" "10px"
        , Css.property "border-radius" "50%"
        , Css.property "background-color" colors.editorDotYellow
        ]
    , Css.Global.class "eco-home-editor-dot-green"
        [ Css.property "width" "10px"
        , Css.property "height" "10px"
        , Css.property "border-radius" "50%"
        , Css.property "background-color" colors.editorDotGreen
        ]
    , Css.Global.class "eco-home-editor-filename"
        [ Css.property "font-family" fontCode
        , Css.property "font-size" "11px"
        , Css.property "color" colors.editorFilename
        ]
    , Css.Global.class "eco-home-editor-body"
        [ Css.property "padding" "16px 20px"
        ]
    , Css.Global.class "eco-home-code-line"
        [ Css.property "font-family" fontCode
        , Css.property "font-size" "13px"
        , Css.property "color" colors.syntaxDefault
        , Css.property "line-height" "1.7"
        , Css.property "white-space" "pre"
        ]
    , Css.Global.class "eco-home-code-keyword"
        [ Css.property "color" colors.syntaxKeyword
        ]
    , Css.Global.class "eco-home-code-symbol"
        [ Css.property "color" colors.syntaxSymbol
        ]
    , Css.Global.class "eco-home-code-string"
        [ Css.property "color" colors.syntaxString
        ]
    , Css.Global.class "eco-home-code-default"
        [ Css.property "color" colors.syntaxDefault
        ]

    -- How It Works steps
    , Css.Global.class "eco-home-step-number"
        [ Css.property "width" "48px"
        , Css.property "height" "48px"
        , Css.property "border-radius" "24px"
        , Css.property "background-color" colors.accent
        , Css.property "font-family" fontHeading
        , Css.property "font-size" "20px"
        , Css.property "font-weight" "700"
        , Css.property "color" colors.bgWhite
        , Css.property "display" "flex"
        , Css.property "align-items" "center"
        , Css.property "justify-content" "center"
        , Css.property "flex-shrink" "0"
        ]
    , Css.Global.class "eco-home-step-title"
        [ Css.property "font-family" fontHeading
        , Css.property "font-size" "18px"
        , Css.property "font-weight" "600"
        , Css.property "color" colors.text
        ]
    , Css.Global.class "eco-home-step-desc"
        [ Css.property "font-family" fontBody
        , Css.property "font-size" "15px"
        , Css.property "color" colors.heading
        , Css.property "line-height" "1.7"
        , Css.property "text-align" "center"
        ]

    -- Comparison section
    , Css.Global.class "eco-home-comp-section"
        [ Css.property "background-color" colors.bgWhite
        , Css.property "border-top" ("1px solid " ++ colors.border)
        , Css.property "border-bottom" ("1px solid " ++ colors.border)
        ]
    , Css.Global.class "eco-home-comp-title"
        [ Css.property "font-family" fontHeading
        , Css.property "font-size" "32px"
        , Css.property "font-weight" "600"
        , Css.property "color" colors.text
        , Css.property "letter-spacing" "-0.5px"
        ]
    , Css.Global.class "eco-home-table"
        [ Css.property "border-radius" "8px"
        , Css.property "border" ("1px solid " ++ colors.border)
        , Css.property "overflow" "hidden"
        ]
    , Css.Global.class "eco-home-table-header"
        [ Css.property "background-color" colors.tableHeaderBg
        , Css.property "border-bottom" ("1px solid " ++ colors.border)
        ]
    , Css.Global.class "eco-home-table-th"
        [ Css.property "padding" "14px 20px"
        , Css.property "font-family" fontBody
        , Css.property "font-size" "13px"
        , Css.property "font-weight" "600"
        , Css.property "color" colors.muted
        ]
    , Css.Global.class "eco-home-table-th-eco"
        [ Css.property "padding" "14px 20px"
        , Css.property "font-family" fontBody
        , Css.property "font-size" "13px"
        , Css.property "font-weight" "600"
        , Css.property "color" colors.accent
        ]
    , Css.Global.class "eco-home-table-row"
        [ Css.property "border-bottom" "1px solid #F0F0F0"
        ]
    , Css.Global.class "eco-home-table-cell"
        [ Css.property "padding" "14px 20px"
        , Css.property "font-family" fontBody
        , Css.property "font-size" "14px"
        , Css.property "color" colors.text
        ]
    , Css.Global.class "eco-home-table-cell-dim"
        [ Css.property "padding" "14px 20px"
        , Css.property "font-family" fontBody
        , Css.property "font-size" "14px"
        , Css.property "color" colors.heading
        ]
    , Css.Global.class "eco-home-table-cell-eco"
        [ Css.property "padding" "14px 20px"
        , Css.property "font-family" fontBody
        , Css.property "font-size" "14px"
        , Css.property "font-weight" "600"
        , Css.property "color" colors.accent
        ]

    -- Community cards
    , Css.Global.class "eco-home-comm-card"
        [ Css.property "border-radius" "8px"
        , Css.property "background-color" colors.bgWhite
        , Css.property "border" ("1px solid " ++ colors.border)
        , Css.property "padding" "32px"
        ]
    , Css.Global.class "eco-home-comm-title"
        [ Css.property "font-family" fontHeading
        , Css.property "font-size" "16px"
        , Css.property "font-weight" "600"
        , Css.property "color" colors.text
        ]
    , Css.Global.class "eco-home-comm-desc"
        [ Css.property "font-family" fontBody
        , Css.property "font-size" "14px"
        , Css.property "color" colors.heading
        , Css.property "line-height" "1.7"
        , Css.property "text-align" "center"
        ]
    , Css.Global.class "eco-home-btn-dark"
        [ Css.property "background-color" colors.text
        , Css.property "color" colors.bgWhite
        , Css.property "font-family" fontBody
        , Css.property "font-size" "13px"
        , Css.property "font-weight" "600"
        , Css.property "border-radius" "4px"
        , Css.property "padding" "10px 20px"
        ]
    , Css.Global.class "eco-home-btn-green"
        [ Css.property "background-color" colors.accent
        , Css.property "color" colors.bgWhite
        , Css.property "font-family" fontBody
        , Css.property "font-size" "13px"
        , Css.property "font-weight" "600"
        , Css.property "border-radius" "4px"
        , Css.property "padding" "10px 20px"
        ]

    -- CTA Band
    , Css.Global.class "eco-home-cta"
        [ Css.property "background-color" colors.accent
        , Css.property "padding" "48px 120px"
        ]
    , Css.Global.class "eco-home-cta-title"
        [ Css.property "font-family" fontHeading
        , Css.property "font-size" "24px"
        , Css.property "font-weight" "700"
        , Css.property "color" colors.bgWhite
        ]
    , Css.Global.class "eco-home-cta-sub"
        [ Css.property "font-family" fontBody
        , Css.property "font-size" "15px"
        , Css.property "color" "rgba(255, 255, 255, 0.8)"
        ]
    , Css.Global.class "eco-home-cta-btn-white"
        [ Css.property "background-color" colors.bgWhite
        , Css.property "color" colors.accent
        , Css.property "font-family" fontBody
        , Css.property "font-size" "14px"
        , Css.property "font-weight" "600"
        , Css.property "border-radius" "4px"
        , Css.property "padding" "12px 24px"
        ]
    , Css.Global.class "eco-home-cta-btn-ghost"
        [ Css.property "background-color" "rgba(255, 255, 255, 0.13)"
        , Css.property "border" "1px solid rgba(255, 255, 255, 0.27)"
        , Css.property "color" colors.bgWhite
        , Css.property "font-family" fontBody
        , Css.property "font-size" "14px"
        , Css.property "font-weight" "600"
        , Css.property "border-radius" "4px"
        , Css.property "padding" "12px 24px"
        ]

    -- Hero buttons
    , Css.Global.class "eco-home-btn-primary"
        [ Css.property "background-color" colors.accent
        , Css.property "color" colors.bgWhite
        , Css.property "font-family" fontBody
        , Css.property "font-size" "14px"
        , Css.property "font-weight" "600"
        , Css.property "border-radius" "6px"
        , Css.property "padding" "12px 24px"
        ]
    , Css.Global.class "eco-home-btn-outline"
        [ Css.property "color" colors.accent
        , Css.property "font-family" fontBody
        , Css.property "font-size" "14px"
        , Css.property "font-weight" "600"
        , Css.property "padding" "12px 24px"
        ]

    -- Section titles
    , Css.Global.class "eco-home-section-title"
        [ Css.property "font-family" fontHeading
        , Css.property "font-size" "36px"
        , Css.property "font-weight" "600"
        , Css.property "color" colors.text
        , Css.property "letter-spacing" "-0.5px"
        ]
    , Css.Global.class "eco-home-section-sub"
        [ Css.property "font-family" fontBody
        , Css.property "font-size" "17px"
        , Css.property "color" colors.muted
        , Css.property "line-height" "1.7"
        , Css.property "text-align" "center"
        , Css.property "max-width" "600px"
        ]
    ]
