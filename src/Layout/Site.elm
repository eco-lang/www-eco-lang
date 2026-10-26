module Layout.Site exposing (MenuLink, MenuSection, NavItem(..), viewFooter, viewFooterDivider, viewHeader)

import Html exposing (Html)
import Html.Attributes as Attrs
import Html.Keyed
import Settings
import Svg
import Svg.Attributes as SvgAttrs


type NavItem
    = Home
    | Docs
    | Articles
    | Roadmap
    | About


{-| A group of links in the phone menu, such as one section of the docs.
-}
type alias MenuSection =
    { title : String
    , links : List MenuLink
    }


{-| A link in the phone menu. `current` marks the page being shown.
-}
type alias MenuLink =
    { label : String
    , href : String
    , current : Bool
    }


siteLinks : List ( NavItem, String, String )
siteLinks =
    [ ( Home, "/", "Home" )
    , ( Docs, "/docs", "Docs" )
    , ( Articles, "/articles", "Articles" )
    , ( Roadmap, "/roadmap", "Roadmap" )
    , ( About, "/about", "About" )
    ]


githubUrl : String
githubUrl =
    "https://github.com/eco-lang/eco-compiler"


{-| The site header. On a desktop it shows the site links. On a phone they move into a menu, which also lists
`contents`, the pages of the current section.

`path` is the current page's path. The menu is keyed on it, so that navigating to another page renders a new menu,
closed.

-}
viewHeader : { active : Maybe NavItem, path : String, contents : List MenuSection } -> Html msg
viewHeader { active, path, contents } =
    Html.header
        [ Attrs.class "eco-header"
        ]
        [ Html.div [ Attrs.class "eco-header-brand" ]
            [ Html.span
                [ Attrs.class "eco-header-logo"
                ]
                [ Html.text "eco" ]
            , Html.span
                [ Attrs.class "eco-header-badge"
                ]
                [ Html.text Settings.version ]
            ]
        , Html.div [ Attrs.class "eco-header-nav" ]
            (List.map (\( item, href, label ) -> viewNavLink href label (active == Just item)) siteLinks
                ++ [ Html.a
                        [ Attrs.href githubUrl
                        , Attrs.target "_blank"
                        , Attrs.class "eco-header-github"
                        ]
                        [ githubIcon
                        , Html.span
                            [ Attrs.class "eco-header-github-label"
                            ]
                            [ Html.text "GitHub" ]
                        ]
                   ]
            )
        , Html.Keyed.node "div"
            [ Attrs.class "eco-menu-wrap" ]
            [ ( path, viewMenu active contents ) ]
        ]


{-| The phone menu: a `<details>` element, so it opens and closes without any Elm state or JavaScript, and works
before the app has started.
-}
viewMenu : Maybe NavItem -> List MenuSection -> Html msg
viewMenu active contents =
    Html.node "details"
        [ Attrs.class "eco-menu" ]
        [ Html.node "summary"
            [ Attrs.class "eco-menu-button"
            , Attrs.attribute "aria-label" "Menu"
            ]
            [ menuIcon, closeIcon ]
        , Html.div [ Attrs.class "eco-menu-panel" ]
            (Html.nav [ Attrs.class "eco-menu-site" ]
                (List.map
                    (\( item, href, label ) ->
                        Html.a
                            [ Attrs.href href
                            , Attrs.class
                                (if active == Just item then
                                    "eco-menu-site-link-active"

                                 else
                                    "eco-menu-site-link"
                                )
                            ]
                            [ Html.text label ]
                    )
                    siteLinks
                    ++ [ Html.a
                            [ Attrs.href githubUrl
                            , Attrs.target "_blank"
                            , Attrs.class "eco-menu-site-link"
                            ]
                            [ Html.text "GitHub" ]
                       ]
                )
                :: List.map viewMenuSection contents
            )
        ]


viewMenuSection : MenuSection -> Html msg
viewMenuSection section =
    Html.div [ Attrs.class "eco-menu-section" ]
        (Html.div [ Attrs.class "eco-menu-section-title" ] [ Html.text section.title ]
            :: List.map viewMenuLink section.links
        )


viewMenuLink : MenuLink -> Html msg
viewMenuLink link =
    Html.a
        (if link.current then
            [ Attrs.href link.href
            , Attrs.class "eco-menu-link-current"
            , Attrs.attribute "aria-current" "page"
            ]

         else
            [ Attrs.href link.href
            , Attrs.class "eco-menu-link"
            ]
        )
        [ Html.text link.label ]


menuIcon : Html msg
menuIcon =
    Svg.svg
        [ SvgAttrs.class "eco-menu-icon-open"
        , SvgAttrs.width "22"
        , SvgAttrs.height "22"
        , SvgAttrs.viewBox "0 0 24 24"
        , SvgAttrs.fill "none"
        , SvgAttrs.stroke "currentColor"
        , SvgAttrs.strokeWidth "2"
        , SvgAttrs.strokeLinecap "round"
        ]
        [ Svg.path [ SvgAttrs.d "M4 6h16M4 12h16M4 18h16" ] [] ]


closeIcon : Html msg
closeIcon =
    Svg.svg
        [ SvgAttrs.class "eco-menu-icon-close"
        , SvgAttrs.width "22"
        , SvgAttrs.height "22"
        , SvgAttrs.viewBox "0 0 24 24"
        , SvgAttrs.fill "none"
        , SvgAttrs.stroke "currentColor"
        , SvgAttrs.strokeWidth "2"
        , SvgAttrs.strokeLinecap "round"
        ]
        [ Svg.path [ SvgAttrs.d "M6 6l12 12M18 6L6 18" ] [] ]


viewNavLink : String -> String -> Bool -> Html msg
viewNavLink href label isActive =
    Html.a
        [ Attrs.href href
        , if isActive then
            Attrs.class "eco-nav-link-active"

          else
            Attrs.class "eco-nav-link"
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
        [ Attrs.class "eco-footer"
        ]
        [ Html.div [ Attrs.class "eco-footer-brand" ]
            [ Html.span
                [ Attrs.class "eco-footer-logo"
                ]
                [ Html.text "eco" ]
            , Html.span
                [ Attrs.class "eco-footer-note"
                ]
                [ Html.text ("\u{2014} release " ++ Settings.version ++ ". Use at your own risk.") ]
            ]
        , Html.div [ Attrs.class "eco-footer-links" ]
            [ Html.a
                [ Attrs.href "/docs"
                , Attrs.class "eco-footer-link"
                ]
                [ Html.text "Documentation" ]
            , Html.a
                [ Attrs.href "/articles"
                , Attrs.class "eco-footer-link"
                ]
                [ Html.text "Articles" ]
            , Html.a
                [ Attrs.href "https://github.com/eco-lang/eco-compiler"
                , Attrs.target "_blank"
                , Attrs.class "eco-footer-link"
                ]
                [ Html.text "GitHub" ]
            , Html.a
                [ Attrs.href "https://elm-lang.org"
                , Attrs.target "_blank"
                , Attrs.class "eco-footer-link"
                ]
                [ Html.text "Elm Lang" ]
            ]
        ]
