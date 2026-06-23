module Route.Index exposing (ActionData, Data, Model, Msg, RouteParams, route)

import BackendTask exposing (BackendTask)
import Code exposing (codeLine)
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Html exposing (Html)
import Html.Attributes as Attrs
import Layout.Site
import MimeType
import Pages.Url
import PagesMsg exposing (PagesMsg)
import RouteBuilder exposing (App, StatelessRoute)
import Settings
import Shared
import UrlPath
import Style
import Svg
import Svg.Attributes as SvgAttrs
import View exposing (View)


type alias Model =
    {}


type alias Msg =
    ()


type alias RouteParams =
    {}


type alias Data =
    {}


type alias ActionData =
    {}


route : StatelessRoute RouteParams Data ActionData
route =
    RouteBuilder.single
        { head = head
        , data = data
        }
        |> RouteBuilder.buildNoState { view = view }


data : BackendTask FatalError Data
data =
    BackendTask.succeed {}


head :
    App Data ActionData RouteParams
    -> List Head.Tag
head _ =
    let
        imageUrl =
            [ "images", "site-image.png" ] |> UrlPath.join |> Pages.Url.fromPath
    in
    Seo.summaryLarge
        { canonicalUrlOverride = Just Settings.canonicalUrl
        , siteName = "eco"
        , image =
            { url = imageUrl
            , alt = "logo"
            , dimensions = Just { width = 500, height = 333 }
            , mimeType = Just (MimeType.Image MimeType.Png)
            }
        , description = Settings.subtitle
        , locale = Settings.locale
        , title = "eco"
        }
        |> Seo.website


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> View (PagesMsg Msg)
view _ _ =
    { title = Settings.title ++ " - " ++ Settings.subtitle
    , body =
        [ Html.div
            [ Attrs.class "min-h-screen flex flex-col eco-page"
            ]
            [ Style.styleNode
            , Layout.Site.viewHeader (Just Layout.Site.Home)
            , viewHero
            , viewHowItWorks
            , viewComparison
            , viewCommunity
            , viewCtaBand
            , Layout.Site.viewFooterDivider
            , Layout.Site.viewFooter
            ]
        ]
    }



-- HERO


viewHero : Html msg
viewHero =
    Html.section
        [ Attrs.class "eco-home-hero"
        ]
        [ viewCrystalLattice
        , Html.div [ Attrs.class "flex items-center gap-16 px-20 h-full eco-home-hero-content" ]
            [ Html.div [ Attrs.class "flex flex-col gap-6 max-w-[520px]" ]
                [ Html.h1
                    [ Attrs.class "eco-home-title"
                    ]
                    [ Html.text "eco: Elm Compiler Optimized, built in Elm." ]
                , Html.div [ Attrs.class "eco-home-accent-bar" ] []
                , Html.p
                    [ Attrs.class "eco-home-subtitle"
                    ]
                    [ Html.text "Self-hosted. Native output. No Haskell knowledge required." ]
                , Html.div [ Attrs.class "flex items-center gap-4" ]
                    [ Html.a
                        [ Attrs.href "/docs"
                        , Attrs.class "eco-home-btn-primary"
                        ]
                        [ Html.text "Get Started" ]
                    , Html.a
                        [ Attrs.href "/docs"
                        , Attrs.class "eco-home-btn-outline"
                        ]
                        [ Html.text "View Docs →" ]
                    ]
                ]
            , Html.div [ Attrs.class "flex-1" ]
                [ viewEditorMockup ]
            ]
        ]


viewCrystalLattice : Html msg
viewCrystalLattice =
    Html.div [ Attrs.class "eco-home-hero-lattice" ]
        [ Svg.svg
            [ SvgAttrs.width "100%"
            , SvgAttrs.height "100%"
            , SvgAttrs.viewBox "0 0 1440 440"
            , SvgAttrs.preserveAspectRatio "none"
            ]
            [ Svg.g
                [ SvgAttrs.transform "translate(-80, 200) rotate(-22, 0, 0) scale(1.2, 1.2)"
                ]
                [ Svg.path
                    [ SvgAttrs.d meshPathData
                    , SvgAttrs.fill (Style.colors.accent ++ "08")
                    , SvgAttrs.stroke (Style.colors.accent ++ "30")
                    , SvgAttrs.strokeWidth "1.1"
                    ]
                    []
                ]
            ]
        ]


meshPathData : String
meshPathData =
    "M0 0l28 18 14-13 26 17-13 20 27-10 23 16-13-20 26-13 24 20-14 20 27-13 23 16-13-20 27-13 23 20-13 17 26-12 24 18-14-20 27-13 23 20-13 17 27-12 23 18-13-20 26-13 24 20-14 17 27-12 23 18-13-20 27-13 23 20-13 17 26-12 24 18-14-20 27-13 23 20-13 17 27-12 23 18-13-20 26-13 24 20-14 17 27-12 23 18-13-20 27-13 23 20-13 17 26-12 24 18-14-20 27-13 23 20-13 17 27-12 23 18-13-20 26-13 24 20-14 17 27-12 23 18-13-20 27-13 23 20-13 17 26-12 24 18-14-20 27-13 23 20-13 17 27-12 23 18-13-20 26-13 24 20-14 17 27-12 23 18-13-20 27-13 23 20-13 17 26-12 24 18-14-20 27-13 23 20-13 17 27-12 23 18-13-20 26-13 24 20-14 17 27-12 23 18-13-20 27-13 23 20-13 17 26-12 24 18-14-20 27-13 23 20-13 17 27-12 23 18-13-20 28-13 0 30z m0 0l0 35 28-17z m28 18l27 24-13-37 26 17z m27 24l27-10-14-10z m27-10l23 16-13-20z m10-4l26-13z m26-13l24 20-14 20z m10 40l27-13z m27-13l23 16-13-20z m10-4l27-13z m27-13l23 20-13 17z m10 37l26-12z m26-12l24 18-14-20z m10-2l27-13z m27-13l23 20-13 17z m10 37l27-12z m27-12l23 18-13-20z m10-2l26-13z m26-13l24 20-14 17z m10 37l27-12z m27-12l23 18-13-20z m10-2l27-13z m27-13l23 20-13 17z m10 37l26-12z m26-12l24 18-14-20z m10-2l27-13z m27-13l23 20-13 17z m10 37l27-12z m27-12l23 18-13-20z m10-2l26-13z m26-13l24 20-14 17z m10 37l27-12z m27-12l23 18-13-20z m10-2l27-13z m27-13l23 20-13 17z m10 37l26-12z m26-12l24 18-14-20z m10-2l27-13z m-678-73l0 37 15-17 13-37z m15 20l40-13z m-15 17l0 38 18-18 17-20-20-17z m35 0l20-30 27-10-7 26z m40-14l30-10 23 7-13 23z m40 20l27-43 13 7-10 30z m30-6l33-14 24 4-14 26z m43 16l27-43 13 5-10 30z m30-8l34-12 23 4-13 26z m44 18l26-43 14 5-10 28z m30-10l33-10 23 4-13 26z m43 20l27-43 13 5-10 28z m30-10l33-10 24 4-14 26z m43 20l27-43 13 5-10 28z m30-10l34-10 23 4-13 26z m44 20l26-43 14 5-10 28z m30-10l33-10 23 4-13 26z m43 20l27-43 13 5-10 28z m30-10l33-10 24 4-14 26z m43 20l27-43 13 5-10 28z m30-10l34-10 23 4-13 26z m44 20l26-43 14 5-10 28z m30-10l33-10 23 4-13 26z m43 20l27-43 13 5-10 28z m30-10l33-10 24 4-14 26z m43 20l27-43 13 5-10 28z m30-10l34-10 23 4-13 26z m44 20l26-43 14 5-10 28z m30-10l33-10 23 4-13 26z m43 20l27-43 13 5-10 28z m30-10l33-10 24 4-14 26z m43 20l27-43 13 5-10 28z m30-10l34-10 23 4-13 26z m44 20l26-43 14 5-10 28z m30-10l33-10 23 4-13 26z m43 20l27-43 13 5-10 28z m30-10l33-10 24 4-14 26z m43 20l27-43 13 5-10 28z m30-10l34-10 23 4-13 26z m44 20l26-43 14 5-10 28z m30-10l33-10 15-3 0 30-22-7z m-1392-128l0 38 22-16-4-40z m22 22l13-60 40-14-13 40z m40-34l53-20 30-6-13 36z m70 10l56-20 30-8-13 38z m73 10l57-20 30-10-14 37z m73 7l57-17 30-10-13 37z m74 10l56-17 30-10-13 37z m73 10l57-17 30-10-14 37z m73 10l57-17 30-10-13 37z m74 10l56-17 30-10-13 37z m73 10l57-17 30-10-14 37z m73 10l57-17 30-10-13 37z m74 10l56-17 30-10-13 37z m73 10l57-17 30-10-14 37z m73 10l57-17 30-10-13 37z m74 10l56-17 30-10-13 37z m73 10l57-17 30-10-14 37z m73 10l57-17 30-10-13 37z m74 10l56-17 30-10-13 37z m73 10l57-17 30-10-14 37z m73 10l40-27 22 7 0 30z m-1378-127l0 40 25-16-3-40z m25 24l37-74 70 10-14 40z m93-24l87-30 73 7-16 40z m144 17l90-30 73 10-17 40z m146 20l90-30 74 10-17 40z m147 20l90-30 73 10-16 40z m147 20l90-30 73 10-17 40z m146 20l90-30 74 10-17 40z m147 20l90-30 73 10-16 40z m147 20l90-30 73 10-17 40z m146 20l90-30 62 10 0 35z m-1288-117l0 40 28-18-3-38z m28 22l90-62 144 17-17 45z m217 0l163-25 147 20-20 43z m290 38l167-23 146 20-20 43z m293 40l167-23 147 20-20 43z m294 40l166-23 152 15 0 38z m-1122-100l0 40 32-18-4-40z m32 22l213-40 290 38-20 44z m483 42l313-4 294 40-20 40z m587 76l338-10 0 40z m-1102-100l0 42 35-18-3-42z m35 24l480 0 587 76-20 40z m1047 116l358-10 0 42z m-1082-98l0 40 38-18-3-40z m38 22l1044 76 358 32z m-38 18l0 45 42-20-4-43z m42 25l1398 65z m-42 20l0 45 1440 0-1398-65z"


viewEditorMockup : Html msg
viewEditorMockup =
    Html.div [ Attrs.class "eco-home-editor" ]
        [ Html.div [ Attrs.class "flex items-center gap-2 eco-home-editor-bar" ]
            [ Html.span [ Attrs.class "eco-home-editor-dot-red" ] []
            , Html.span [ Attrs.class "eco-home-editor-dot-yellow" ] []
            , Html.span [ Attrs.class "eco-home-editor-dot-green" ] []
            , Html.span [ Attrs.class "eco-home-editor-filename" ] [ Html.text "  Main.elm" ]
            ]
        , Html.div [ Attrs.class "flex flex-col gap-0.5 eco-home-editor-body" ]
            [ codeLine "module Main exposing (main)"
            , codeLine "\u{00A0}"
            , codeLine "import Eco.Console"
            , codeLine "import Platform"
            , codeLine "\u{00A0}"
            , codeLine "main : Program () {} ()"
            , codeLine "main ="
            , codeLine "\u{00A0}\u{00A0}Platform.worker"
            , codeLine "\u{00A0}\u{00A0}\u{00A0}\u{00A0}{ init = \\_ -> ( Eco.Console.log \"Hello World!\" {}, Cmd.none )"
            , codeLine "\u{00A0}\u{00A0}\u{00A0}\u{00A0}, update = \\_ model -> ( model, Cmd.none )"
            , codeLine "\u{00A0}\u{00A0}\u{00A0}\u{00A0}, subscriptions = \\_ -> Sub.none"
            , codeLine "\u{00A0}\u{00A0}\u{00A0}\u{00A0}}"
            , codeLine " "
            ]
        ]



-- HOW IT WORKS


viewHowItWorks : Html msg
viewHowItWorks =
    Html.section
        [ Attrs.class "flex flex-col items-center gap-12 py-16 px-20 md:px-30"
        ]
        [ Html.h2 [ Attrs.class "eco-home-section-title" ]
            [ Html.text "How it works" ]
        , Html.div [ Attrs.class "flex gap-8 w-full" ]
            [ viewStep "1" "Write Elm" "Write standard Elm code using the types and patterns you already know and love."
            , viewStep "2" "Compile with eco" "eco analyses, optimises, and compiles your code through MLIR and LLVM to high performance native."
            , viewStep "3" "Ship anywhere" "Deploy native binaries, or web apps, all from a single codebase."
            ]
        ]


viewStep : String -> String -> String -> Html msg
viewStep number title description =
    Html.div
        [ Attrs.class "flex flex-col items-center gap-4 flex-1 px-4"
        ]
        [ Html.div [ Attrs.class "eco-home-step-number" ] [ Html.text number ]
        , Html.div [ Attrs.class "eco-home-step-title" ] [ Html.text title ]
        , Html.p [ Attrs.class "eco-home-step-desc" ] [ Html.text description ]
        ]



-- COMPARISON TABLE


viewComparison : Html msg
viewComparison =
    Html.section
        [ Attrs.class "flex flex-col items-center gap-10 py-16 px-20 md:px-40 eco-home-comp-section"
        ]
        [ Html.h2 [ Attrs.class "eco-home-comp-title" ]
            [ Html.text "eco vs. the official Elm compiler" ]
        , Html.div [ Attrs.class "w-full eco-home-table" ]
            [ viewTableHeader
            , viewTableRow True "Written in" "Haskell" "Elm, C++ ✓"
            , viewTableRow True "Output targets" "JavaScript only" "Native, JavaScript ✓"
            , viewTableRow True "Build dependency" "GHC required" "Self-hosted ✓"
            , viewTableRow False "Community contributions" "Requires Haskell knowledge" "Elm devs welcome ✓"
            ]
        ]


viewTableHeader : Html msg
viewTableHeader =
    Html.div [ Attrs.class "flex eco-home-table-header" ]
        [ Html.div [ Attrs.class "flex-1 eco-home-table-th" ] [ Html.text "Feature" ]
        , Html.div [ Attrs.class "flex-1 eco-home-table-th" ] [ Html.text "Elm Compiler" ]
        , Html.div [ Attrs.class "flex-1 eco-home-table-th-eco" ] [ Html.text "eco" ]
        ]


viewTableRow : Bool -> String -> String -> String -> Html msg
viewTableRow hasBorder feature elm eco =
    Html.div
        [ Attrs.class
            (if hasBorder then
                "flex eco-home-table-row"

             else
                "flex"
            )
        ]
        [ Html.div [ Attrs.class "flex-1 eco-home-table-cell" ] [ Html.text feature ]
        , Html.div [ Attrs.class "flex-1 eco-home-table-cell-dim" ] [ Html.text elm ]
        , Html.div [ Attrs.class "flex-1 eco-home-table-cell-eco" ] [ Html.text eco ]
        ]



-- COMMUNITY


viewCommunity : Html msg
viewCommunity =
    Html.section
        [ Attrs.class "flex flex-col items-center gap-10 py-16 px-20 md:px-30"
        ]
        [ Html.h2 [ Attrs.class "eco-home-section-title" ]
            [ Html.text "Join the community" ]
        , Html.p [ Attrs.class "eco-home-section-sub" ]
            [ Html.text "eco is open source and community-driven. Contributors, testers, and feedback are all welcome." ]
        , Html.div [ Attrs.class "flex gap-6 w-full" ]
            [ viewCommunityCard
                { icon = githubIcon
                , title = "Contribute on GitHub"
                , description = "Browse issues, submit PRs, or fork the project. The compiler is written in Elm, so no Haskell is required."
                , buttonText = "View Repository →"
                , buttonClass = "eco-home-btn-dark"
                , buttonHref = "https://github.com/eco-lang/eco-compiler"
                }
            ]
        ]


viewCommunityCard :
    { icon : Html msg
    , title : String
    , description : String
    , buttonText : String
    , buttonClass : String
    , buttonHref : String
    }
    -> Html msg
viewCommunityCard card =
    Html.div
        [ Attrs.class "flex flex-col items-center gap-3 flex-1 eco-home-comm-card"
        ]
        [ card.icon
        , Html.div [ Attrs.class "eco-home-comm-title" ] [ Html.text card.title ]
        , Html.p [ Attrs.class "eco-home-comm-desc" ] [ Html.text card.description ]
        , Html.a
            [ Attrs.href card.buttonHref
            , Attrs.target "_blank"
            , Attrs.class card.buttonClass
            ]
            [ Html.text card.buttonText ]
        ]



-- CTA BAND


viewCtaBand : Html msg
viewCtaBand =
    Html.section
        [ Attrs.class "flex items-center justify-between eco-home-cta"
        ]
        [ Html.div [ Attrs.class "flex flex-col gap-1.5" ]
            [ Html.div [ Attrs.class "eco-home-cta-title" ]
                [ Html.text "Ready to compile Elm to native?" ]
            , Html.div [ Attrs.class "eco-home-cta-sub" ]
                [ Html.text "Install in one command. Start building immediately." ]
            ]
        , Html.div [ Attrs.class "flex items-center gap-3" ]
            [ Html.a
                [ Attrs.href "/docs"
                , Attrs.class "flex items-center gap-2 eco-home-cta-btn-white"
                ]
                [ terminalIcon 16 Style.colors.accent
                , Html.text "Install eco"
                ]
            , Html.a
                [ Attrs.href "/docs"
                , Attrs.class "eco-home-cta-btn-ghost"
                ]
                [ Html.text "Read Docs →" ]
            ]
        ]



-- ICONS


terminalIcon : Int -> String -> Html msg
terminalIcon size color =
    Svg.svg
        [ SvgAttrs.width (String.fromInt size)
        , SvgAttrs.height (String.fromInt size)
        , SvgAttrs.viewBox "0 0 24 24"
        , SvgAttrs.fill "none"
        , SvgAttrs.stroke color
        , SvgAttrs.strokeWidth "2"
        , SvgAttrs.strokeLinecap "round"
        , SvgAttrs.strokeLinejoin "round"
        ]
        [ Svg.polyline [ SvgAttrs.points "4 17 10 11 4 5" ] []
        , Svg.line [ SvgAttrs.x1 "12", SvgAttrs.y1 "19", SvgAttrs.x2 "20", SvgAttrs.y2 "19" ] []
        ]


githubIcon : Html msg
githubIcon =
    Svg.svg
        [ SvgAttrs.width "32"
        , SvgAttrs.height "32"
        , SvgAttrs.viewBox "0 0 24 24"
        , SvgAttrs.fill "none"
        , SvgAttrs.stroke Style.colors.text
        , SvgAttrs.strokeWidth "1.5"
        , SvgAttrs.strokeLinecap "round"
        , SvgAttrs.strokeLinejoin "round"
        ]
        [ Svg.path [ SvgAttrs.d "M9 19c-5 1.5-5-2.5-7-3m14 6v-3.87a3.37 3.37 0 0 0-.94-2.61c3.14-.35 6.44-1.54 6.44-7A5.44 5.44 0 0 0 20 4.77 5.07 5.07 0 0 0 19.91 1S18.73.65 16 2.48a13.38 13.38 0 0 0-7 0C6.27.65 5.09 1 5.09 1A5.07 5.07 0 0 0 5 4.77a5.44 5.44 0 0 0-1.5 3.78c0 5.42 3.3 6.61 6.44 7A3.37 3.37 0 0 0 9 18.13V22" ] []
        ]


messageCircleIcon : Html msg
messageCircleIcon =
    Svg.svg
        [ SvgAttrs.width "32"
        , SvgAttrs.height "32"
        , SvgAttrs.viewBox "0 0 24 24"
        , SvgAttrs.fill "none"
        , SvgAttrs.stroke Style.colors.accent
        , SvgAttrs.strokeWidth "1.5"
        , SvgAttrs.strokeLinecap "round"
        , SvgAttrs.strokeLinejoin "round"
        ]
        [ Svg.path [ SvgAttrs.d "M7.9 20A9 9 0 1 0 4 16.1L2 22Z" ] []
        ]
