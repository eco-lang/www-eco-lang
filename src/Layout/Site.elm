module Layout.Site exposing (NavItem(..), viewFooter, viewFooterDivider, viewHeader)

import Html exposing (Html)
import Html.Attributes as Attrs
import Svg
import Svg.Attributes as SvgAttrs


type NavItem
    = Home
    | Docs
    | Articles
    | Roadmap
    | About


viewHeader : Maybe NavItem -> Html msg
viewHeader activeItem =
    Html.header
        [ Attrs.class "flex items-center justify-between px-4 md:px-18 py-4 eco-header"
        ]
        [ Html.div [ Attrs.class "flex items-center gap-3" ]
            [ Html.span
                [ Attrs.class "text-lg font-bold tracking-wide eco-header-logo"
                ]
                [ Html.text "eco" ]
            , Html.span
                [ Attrs.class "text-xs font-semibold px-2.5 py-1 rounded eco-header-badge"
                ]
                [ Html.text "alpha 0.1.0" ]
            ]
        , Html.div [ Attrs.class "flex items-center gap-7" ]
            [ viewNavLink "/"
                "Home"
                (activeItem == Just Home)
            , viewNavLink "/docs"
                "Docs"
                (activeItem == Just Docs)
            , viewNavLink "/articles"
                "Articles"
                (activeItem == Just Articles)
            , viewNavLink "/roadmap"
                "Roadmap"
                (activeItem == Just Roadmap)
            , viewNavLink "/about"
                "About"
                (activeItem == Just About)
            , Html.a
                [ Attrs.href "https://github.com/eco-lang/eco-compiler"
                , Attrs.target "_blank"
                , Attrs.class "flex items-center gap-2 eco-text-heading"
                ]
                [ githubIcon
                , Html.span
                    [ Attrs.class "text-sm font-medium eco-font-body"
                    ]
                    [ Html.text "GitHub" ]
                ]
            ]
        ]


viewNavLink : String -> String -> Bool -> Html msg
viewNavLink href label isActive =
    Html.a
        [ Attrs.href href
        , if isActive then
            Attrs.class "text-sm eco-nav-link-active"

          else
            Attrs.class "text-sm font-medium eco-nav-link"
        ]
        [ Html.text label ]


githubIcon : Html msg
githubIcon =
    Svg.svg
        [ SvgAttrs.width "18"
        , SvgAttrs.height "18"
        , SvgAttrs.viewBox "0 0 24 24"
        , SvgAttrs.fill "none"
        , SvgAttrs.stroke "currentColor"
        , SvgAttrs.strokeWidth "2"
        , SvgAttrs.strokeLinecap "round"
        , SvgAttrs.strokeLinejoin "round"
        ]
        [ Svg.path [ SvgAttrs.d "M9 19c-5 1.5-5-2.5-7-3m14 6v-3.87a3.37 3.37 0 0 0-.94-2.61c3.14-.35 6.44-1.54 6.44-7A5.44 5.44 0 0 0 20 4.77 5.07 5.07 0 0 0 19.91 1S18.73.65 16 2.48a13.38 13.38 0 0 0-7 0C6.27.65 5.09 1 5.09 1A5.07 5.07 0 0 0 5 4.77a5.44 5.44 0 0 0-1.5 3.78c0 5.42 3.3 6.61 6.44 7A3.37 3.37 0 0 0 9 18.13V22" ] []
        ]


viewFooterDivider : Html msg
viewFooterDivider =
    Html.div
        [ Attrs.class "eco-divider"
        ]
        []


viewFooter : Html msg
viewFooter =
    Html.footer
        [ Attrs.class "flex flex-col md:flex-row items-center justify-between px-4 md:px-18 py-7 gap-4 eco-footer"
        ]
        [ Html.div [ Attrs.class "flex items-center gap-2" ]
            [ Html.span
                [ Attrs.class "text-sm font-bold eco-footer-logo"
                ]
                [ Html.text "eco" ]
            , Html.span
                [ Attrs.class "text-sm eco-text-muted"
                ]
                [ Html.text "\u{2014} alpha release. Use at your own risk." ]
            ]
        , Html.div [ Attrs.class "flex items-center gap-6" ]
            [ Html.a
                [ Attrs.href "/docs"
                , Attrs.class "text-sm hover:underline eco-text-muted"
                ]
                [ Html.text "Documentation" ]
            , Html.a
                [ Attrs.href "/articles"
                , Attrs.class "text-sm hover:underline eco-text-muted"
                ]
                [ Html.text "Articles" ]
            , Html.a
                [ Attrs.href "https://github.com/eco-lang/eco-compiler"
                , Attrs.target "_blank"
                , Attrs.class "text-sm hover:underline eco-text-muted"
                ]
                [ Html.text "GitHub" ]
            , Html.a
                [ Attrs.href "https://elm-lang.org"
                , Attrs.target "_blank"
                , Attrs.class "text-sm hover:underline eco-text-muted"
                ]
                [ Html.text "Elm Lang" ]
            ]
        ]
