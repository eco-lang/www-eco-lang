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
            [ "images", "site-card.png" ] |> UrlPath.join |> Pages.Url.fromPath
    in
    Seo.summaryLarge
        { canonicalUrlOverride = Just Settings.canonicalUrl
        , siteName = "eco"
        , image =
            { url = imageUrl
            , alt = "logo"
            , dimensions = Just { width = 1200, height = 630 }
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
            [ Attrs.class "eco-page eco-home"
            ]
            [ Layout.Site.viewHeader { active = Nothing, path = "/", contents = [] }
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
        [ viewCircles
        , Html.div [ Attrs.class "eco-home-hero-content" ]
            [ Html.div [ Attrs.class "eco-home-hero-text" ]
                [ Html.h1
                    [ Attrs.class "eco-home-title"
                    ]
                    [ Html.span [ Attrs.class "eco-home-title-eco" ] [ Html.text "eco" ]
                    , Html.text ": Elm Compiler Optimized, built in Elm."
                    ]
                , Html.div [ Attrs.class "eco-home-accent-bar" ] []
                , Html.p
                    [ Attrs.class "eco-home-subtitle"
                    ]
                    [ Html.text "Written in Elm. Native output. Same Elm you know." ]
                , Html.div [ Attrs.class "eco-home-hero-actions" ]
                    [ Html.a
                        [ Attrs.href "/docs/getting-started"
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
            , Html.div [ Attrs.class "eco-home-hero-editor" ]
                [ viewEditorMockup ]
            ]
        ]


{-| The three circles, filled and faint, behind the editor.
-}
viewCircles : Html msg
viewCircles =
    Html.div [ Attrs.class "eco-home-hero-circles" ]
        [ Svg.svg
            [ SvgAttrs.class "eco-home-hero-circles-art"
            , SvgAttrs.width "1440"
            , SvgAttrs.height "440"
            , SvgAttrs.viewBox "0 0 1440 440"
            ]
            [ Svg.g
                [ SvgAttrs.fill Style.heroDark.accent
                , SvgAttrs.fillOpacity "0.1"
                ]
                (List.map
                    (\( cx, cy, r ) ->
                        Svg.circle
                            [ SvgAttrs.cx (String.fromFloat cx)
                            , SvgAttrs.cy (String.fromFloat cy)
                            , SvgAttrs.r (String.fromFloat r)
                            ]
                            []
                    )
                    [ ( 1010, 225, 235 )
                    , ( 770, 30, 125 )
                    , ( 1270, 430, 150 )
                    ]
                )
            ]
        ]


viewEditorMockup : Html msg
viewEditorMockup =
    Html.div [ Attrs.class "eco-home-editor" ]
        [ Html.div [ Attrs.class "eco-home-editor-bar" ]
            [ Html.span [ Attrs.class "eco-home-editor-dot-red" ] []
            , Html.span [ Attrs.class "eco-home-editor-dot-yellow" ] []
            , Html.span [ Attrs.class "eco-home-editor-dot-green" ] []
            , Html.span [ Attrs.class "eco-home-editor-filename" ] [ Html.text "  Hello.elm" ]
            ]
        , Html.div [ Attrs.class "eco-home-editor-body" ]
            [ codeLine "module Hello exposing (main)"
            , codeLine "\u{00A0}"
            , codeLine "import Stream"
            , codeLine "import System"
            , codeLine "\u{00A0}"
            , codeLine "\u{00A0}"
            , codeLine "main : Platform.Program System.Environment () ()"
            , codeLine "main ="
            , codeLine "\u{00A0}\u{00A0}\u{00A0}\u{00A0}System.simpleProgram"
            , codeLine "\u{00A0}\u{00A0}\u{00A0}\u{00A0}\u{00A0}\u{00A0}\u{00A0}\u{00A0}(\\env -> Stream.logLine \"Hello World!\" env.stdout)"
            , codeLine " "
            ]
        ]



-- OUTPUTS


viewHowItWorks : Html msg
viewHowItWorks =
    Html.section
        [ Attrs.class "eco-home-steps-section"
        ]
        [ Html.h2 [ Attrs.class "eco-home-section-title" ]
            [ Html.text "One command, three outputs" ]
        , Html.div [ Attrs.class "eco-home-steps" ]
            [ viewStep "1" "Executable" "--output=main" "A native program for the command line, a server or a batch job. It needs no Node or npm on the machine where it runs."
            , viewStep "2" "Embed" "--output=main.so" "A shared library or Node addon. A C, C++ or Node program starts your Elm program and talks to it through its ports."
            , viewStep "3" "Web" "--output=main.js" "For the browser, the same JavaScript and HTML that elm make produces, from the same code generator."
            ]
        ]


viewStep : String -> String -> String -> String -> Html msg
viewStep number title output description =
    Html.div
        [ Attrs.class "eco-home-step"
        ]
        [ Html.div [ Attrs.class ("eco-home-step-halo eco-home-step-halo-" ++ number) ] []
        , Html.div [ Attrs.class "eco-home-step-number" ] [ Html.text number ]
        , Html.div [ Attrs.class "eco-home-step-title" ] [ Html.text title ]
        , Html.code [ Attrs.class "eco-home-step-command" ] [ Html.text ("eco make src/Main.elm " ++ output) ]
        , Html.p [ Attrs.class "eco-home-step-desc" ] [ Html.text description ]
        ]



-- COMPARISON TABLE


viewComparison : Html msg
viewComparison =
    Html.section
        [ Attrs.class "eco-home-comp-section"
        ]
        [ Html.h2 [ Attrs.class "eco-home-comp-title" ]
            [ Html.text "Elm and eco compared" ]
        , Html.div [ Attrs.class "eco-home-table" ]
            [ viewTableHeader
            , viewTableRow True "Language" "Elm 0.19" "Elm 0.19, unchanged"
            , viewTableRow True "Error messages" "Elm's" "The same messages"
            , viewTableRow True "Packages" "The Elm package ecosystem" "The same packages; built-ins rewritten in C++"
            , viewTableRow True "Browser output" "JavaScript and HTML" "The same generator, the same output"
            , viewTableRow True "Native executables" "—" "Linux, macOS, Windows"
            , viewTableRow True "Files and processes" "Through ports, in Node" "eco/system (Linux and macOS)"
            , viewTableRow True "Sockets" "Through ports, in Node" "TCP, UDP, TLS, Unix sockets"
            , viewTableRow True "HTTP server" "Through ports, in Node" "Built in: HTTPS, HTTP/2, WebSockets"
            , viewTableRow True "Deployment" "Node and its dependencies" "One binary (static on Linux)"
            , viewTableRow True "Embedding" "—" "Shared libraries, Node addons"
            , viewTableRow True "Builds itself" "—" "Yes, byte for byte on every build"
            , viewTableRow True "Compiler threads" "Multi-threaded, in Haskell" "Single-threaded, in Elm"
            , viewTableRow False "Compile speed" "Famously fast" "Slower: one thread, and native builds go through LLVM"
            ]
        ]


viewTableHeader : Html msg
viewTableHeader =
    Html.div [ Attrs.class "eco-home-table-header" ]
        [ Html.div [ Attrs.class "eco-home-table-th" ] []
        , Html.div [ Attrs.class "eco-home-table-th-elm" ] [ Html.text "Elm 0.19" ]
        , Html.div [ Attrs.class "eco-home-table-th-eco" ] [ Html.text "eco" ]
        ]


viewTableRow : Bool -> String -> String -> String -> Html msg
viewTableRow hasBorder feature elm eco =
    Html.div
        [ Attrs.class
            (if hasBorder then
                "eco-home-table-row"

             else
                "eco-home-table-row-last"
            )
        ]
        [ Html.div [ Attrs.class "eco-home-table-cell" ] [ Html.text feature ]
        , Html.div [ Attrs.class "eco-home-table-cell-dim" ] [ Html.text elm ]
        , Html.div [ Attrs.class "eco-home-table-cell-eco" ] [ Html.text eco ]
        ]



-- COMMUNITY


viewCommunity : Html msg
viewCommunity =
    Html.section
        [ Attrs.class "eco-home-community-section"
        ]
        [ Html.h2 [ Attrs.class "eco-home-section-title" ]
            [ Html.text "Join the community" ]
        , Html.p [ Attrs.class "eco-home-section-sub" ]
            [ Html.text "eco is open source and community-driven. Contributors, testers, and feedback are all welcome." ]
        , Html.p [ Attrs.class "eco-home-section-sub" ]
            [ Html.text "You'll find the Elm community on "
            , communityLink "https://elm-lang.org/community/slack" "Elm Slack"
            , Html.text ", the "
            , communityLink "https://incrementalelm.com/chat" "Incremental Elm Discord"
            , Html.text " and the "
            , communityLink "https://discourse.elm-lang.org" "Elm Discourse forum"
            , Html.text "."
            ]
        , Html.div [ Attrs.class "eco-home-comm-cards" ]
            [ viewCommunityCard
                { icon = githubIcon
                , title = "Contribute on GitHub"
                , description = "Browse issues, submit PRs, or fork the project. The compiler is written in Elm, so no Haskell is required. The backend does use C++, though."
                , buttonText = "View Repository →"
                , buttonClass = "eco-home-btn-dark"
                , buttonHref = "https://github.com/eco-lang/eco-compiler"
                }
            ]
        ]


communityLink : String -> String -> Html msg
communityLink href label =
    Html.a
        [ Attrs.href href
        , Attrs.target "_blank"
        , Attrs.class "eco-home-section-sub-link"
        ]
        [ Html.text label ]


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
        [ Attrs.class "eco-home-comm-card"
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
        [ Attrs.class "eco-home-cta"
        ]
        [ Html.div [ Attrs.class "eco-home-cta-text" ]
            [ Html.div [ Attrs.class "eco-home-cta-title" ]
                [ Html.text "Ready to compile Elm to native?" ]
            , Html.div [ Attrs.class "eco-home-cta-sub" ]
                [ Html.text "Install in one command. Start building immediately." ]
            ]
        , Html.div [ Attrs.class "eco-home-cta-actions" ]
            [ Html.a
                [ Attrs.href "/docs/getting-started"
                , Attrs.class "eco-home-cta-btn-white"
                ]
                [ terminalIcon 16 Style.heroDark.buttonText
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
        , SvgAttrs.stroke Style.sageStone.text
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
