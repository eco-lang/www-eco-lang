module Layout.Docs exposing (viewDocsPage)

import Content.Docs exposing (DocMetadata, DocPage, TocSection)
import Html exposing (Html)
import Html.Attributes as Attrs
import Html.Extra
import Layout.Markdown as Markdown
import Layout.Site
import Markdown.Block exposing (Block)
import Route
import Style
import Svg
import Svg.Attributes as SvgAttrs


viewDocsPage : String -> DocPage -> List TocSection -> List (Html msg)
viewDocsPage currentSlug docPage sections =
    [ Html.div
        [ Attrs.class "eco-page"
        ]
        [ Layout.Site.viewHeader
            { active = Just Layout.Site.Docs
            , path = Route.toString (Route.Docs__Slug_ { slug = currentSlug })
            , contents = menuContents currentSlug sections
            }
        , Html.div [ Attrs.class "eco-page-body" ]
            [ viewSidebar currentSlug sections
            , viewContent docPage
            ]
        , Layout.Site.viewFooterDivider
        , Layout.Site.viewFooter
        ]
    ]



-- MENU


{-| The section's contents for the phone menu: the same entries as the sidebar.
-}
menuContents : String -> List TocSection -> List Layout.Site.MenuSection
menuContents currentSlug sections =
    List.map
        (\section ->
            { title = section.name
            , links =
                List.map
                    (\meta ->
                        { label = meta.title
                        , href = Route.toString (Route.Docs__Slug_ { slug = meta.slug })
                        , current = meta.slug == currentSlug
                        }
                    )
                    section.pages
            }
        )
        sections



-- SIDEBAR


viewSidebar : String -> List TocSection -> Html msg
viewSidebar currentSlug sections =
    Html.aside
        [ Attrs.class "eco-sidebar"
        ]
        (Html.span
            [ Attrs.class "eco-sidebar-title"
            ]
            [ Html.text "Documentation" ]
            :: Html.div [ Attrs.class "eco-sidebar-spacer" ] []
            :: List.concatMap (viewTocSection currentSlug) sections
        )


viewTocSection : String -> TocSection -> List (Html msg)
viewTocSection currentSlug section =
    [ Html.div
        [ Attrs.class "eco-toc-section"
        ]
        [ Html.span
            [ Attrs.class "eco-toc-section-name"
            ]
            [ Html.text section.name ]
        ]
    , Html.div
        [ Attrs.class "eco-toc-items"
        ]
        (List.map (viewTocItem currentSlug) section.pages)
    , Html.div [ Attrs.class "eco-toc-gap" ] []
    ]


viewTocItem : String -> DocMetadata -> Html msg
viewTocItem currentSlug meta =
    let
        isActive =
            meta.slug == currentSlug
    in
    Route.Docs__Slug_ { slug = meta.slug }
        |> Route.link
            [ Attrs.class
                (if isActive then
                    "eco-toc-item-active"

                 else
                    "eco-toc-item"
                )
            ]
            [ Html.text meta.title ]



-- CONTENT AREA


viewContent : DocPage -> Html msg
viewContent docPage =
    Html.main_
        [ Attrs.class "eco-content-area"
        ]
        [ viewBreadcrumb docPage.metadata
        , viewPageHeader docPage.metadata
        , viewDivider
        , Html.article
            [ Attrs.class "eco-article-body"
            ]
            (viewDocBody docPage.body)
        , viewDivider
        , viewPageNav docPage.previousPage docPage.nextPage
        ]



-- BREADCRUMB


viewBreadcrumb : DocMetadata -> Html msg
viewBreadcrumb meta =
    Html.nav
        [ Attrs.class "eco-breadcrumb"
        ]
        [ Html.span
            [ Attrs.class "eco-breadcrumb-text"
            ]
            [ Html.text "Docs" ]
        , Html.span
            [ Attrs.class "eco-breadcrumb-sep"
            ]
            [ Html.text "/" ]
        , Html.span
            [ Attrs.class "eco-breadcrumb-text"
            ]
            [ Html.text meta.section ]
        , Html.span
            [ Attrs.class "eco-breadcrumb-sep"
            ]
            [ Html.text "/" ]
        , Html.span
            [ Attrs.class "eco-breadcrumb-active"
            ]
            [ Html.text meta.title ]
        ]



-- PAGE HEADER


viewPageHeader : DocMetadata -> Html msg
viewPageHeader meta =
    Html.div
        [ Attrs.class "eco-page-header"
        ]
        [ Html.h1
            [ Attrs.class "eco-page-title"
            ]
            [ Html.text meta.title ]
        , Html.Extra.viewMaybe
            (\description ->
                Html.p
                    [ Attrs.class "eco-page-desc"
                    ]
                    [ Html.text description ]
            )
            meta.description
        ]



-- BODY


viewDocBody : List Block -> List (Html msg)
viewDocBody blocks =
    Markdown.docsBlocksToHtml blocks


viewDivider : Html msg
viewDivider =
    Html.div
        [ Attrs.class "eco-content-divider"
        ]
        []



-- PAGE NAVIGATION


viewPageNav : Maybe DocMetadata -> Maybe DocMetadata -> Html msg
viewPageNav previous next =
    Html.div
        [ Attrs.class "eco-page-nav"
        ]
        [ case previous of
            Just prev ->
                viewPrevLink prev

            Nothing ->
                Html.div [] []
        , case next of
            Just nxt ->
                viewNextLink nxt

            Nothing ->
                Html.div [] []
        ]


viewPrevLink : DocMetadata -> Html msg
viewPrevLink meta =
    Route.Docs__Slug_ { slug = meta.slug }
        |> Route.link
            [ Attrs.class "eco-page-nav-prev"
            ]
            [ Html.span
                [ Attrs.class "eco-page-nav-label"
                ]
                [ Html.text "Previous" ]
            , Html.div [ Attrs.class "eco-page-nav-link-row" ]
                [ arrowLeftIcon
                , Html.span
                    [ Attrs.class "eco-page-nav-title"
                    ]
                    [ Html.text meta.title ]
                ]
            ]


viewNextLink : DocMetadata -> Html msg
viewNextLink meta =
    Route.Docs__Slug_ { slug = meta.slug }
        |> Route.link
            [ Attrs.class "eco-page-nav-next"
            ]
            [ Html.span
                [ Attrs.class "eco-page-nav-label"
                ]
                [ Html.text "Next" ]
            , Html.div [ Attrs.class "eco-page-nav-link-row" ]
                [ Html.span
                    [ Attrs.class "eco-page-nav-title"
                    ]
                    [ Html.text meta.title ]
                , arrowRightIcon
                ]
            ]


arrowLeftIcon : Html msg
arrowLeftIcon =
    Svg.svg
        [ SvgAttrs.width "14"
        , SvgAttrs.height "14"
        , SvgAttrs.viewBox "0 0 24 24"
        , SvgAttrs.fill "none"
        , SvgAttrs.stroke Style.colors.accent
        , SvgAttrs.strokeWidth "2"
        , SvgAttrs.strokeLinecap "round"
        , SvgAttrs.strokeLinejoin "round"
        ]
        [ Svg.path [ SvgAttrs.d "m12 19-7-7 7-7" ] []
        , Svg.path [ SvgAttrs.d "M19 12H5" ] []
        ]


arrowRightIcon : Html msg
arrowRightIcon =
    Svg.svg
        [ SvgAttrs.width "14"
        , SvgAttrs.height "14"
        , SvgAttrs.viewBox "0 0 24 24"
        , SvgAttrs.fill "none"
        , SvgAttrs.stroke Style.colors.accent
        , SvgAttrs.strokeWidth "2"
        , SvgAttrs.strokeLinecap "round"
        , SvgAttrs.strokeLinejoin "round"
        ]
        [ Svg.path [ SvgAttrs.d "m12 5 7 7-7 7" ] []
        , Svg.path [ SvgAttrs.d "M5 12h14" ] []
        ]
