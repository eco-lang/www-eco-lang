module Layout.Articles exposing (viewArticlesPage)

import Content.Articles exposing (ArticleMetadata, ArticlePage, TocSection)
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
import SyntaxHighlight


viewArticlesPage : String -> ArticlePage -> List TocSection -> List (Html msg)
viewArticlesPage currentSlug articlePage sections =
    [ Html.div
        [ Attrs.class "min-h-screen flex flex-col eco-page"
        ]
        [ Style.styleNode
        , Layout.Site.viewHeader (Just Layout.Site.Articles)
        , Html.div [ Attrs.class "flex flex-1" ]
            [ viewSidebar currentSlug sections
            , viewContent articlePage
            ]
        , Layout.Site.viewFooterDivider
        , Layout.Site.viewFooter
        ]
    ]



-- SIDEBAR


viewSidebar : String -> List TocSection -> Html msg
viewSidebar currentSlug sections =
    Html.aside
        [ Attrs.class "hidden md:flex flex-col flex-shrink-0 eco-sidebar"
        ]
        (Html.span
            [ Attrs.class "text-xs font-bold tracking-widest eco-sidebar-title"
            ]
            [ Html.text "Articles" ]
            :: Html.div [ Attrs.class "eco-sidebar-spacer" ] []
            :: List.concatMap (viewTocSection currentSlug) sections
        )


viewTocSection : String -> TocSection -> List (Html msg)
viewTocSection currentSlug section =
    [ Html.div
        [ Attrs.class "eco-toc-section"
        ]
        [ Html.span
            [ Attrs.class "text-sm font-semibold eco-toc-section-name"
            ]
            [ Html.text section.name ]
        ]
    , Html.div
        [ Attrs.class "flex flex-col eco-toc-items"
        ]
        (List.map (viewTocItem currentSlug) section.pages)
    , Html.div [ Attrs.class "eco-toc-gap" ] []
    ]


viewTocItem : String -> ArticleMetadata -> Html msg
viewTocItem currentSlug meta =
    let
        isActive =
            meta.slug == currentSlug
    in
    Route.Articles__Slug_ { slug = meta.slug }
        |> Route.link
            [ Attrs.class
                (if isActive then
                    "block text-sm eco-toc-item-active"

                 else
                    "block text-sm eco-toc-item"
                )
            ]
            [ Html.text meta.title ]



-- CONTENT AREA


viewContent : ArticlePage -> Html msg
viewContent articlePage =
    Html.main_
        [ Attrs.class "flex-1 eco-content-area"
        ]
        [ viewBreadcrumb articlePage.metadata
        , viewPageHeader articlePage.metadata
        , viewBannerImage articlePage.metadata
        , viewDivider
        , Html.article
            [ Attrs.class "eco-article-body"
            ]
            (SyntaxHighlight.useTheme SyntaxHighlight.oneDark
                :: viewArticleBody articlePage.body
            )
        , viewDivider
        , viewPageNav articlePage.previousPage articlePage.nextPage
        ]



-- BREADCRUMB


viewBreadcrumb : ArticleMetadata -> Html msg
viewBreadcrumb meta =
    Html.nav
        [ Attrs.class "flex items-center gap-2 eco-breadcrumb"
        ]
        [ Html.span
            [ Attrs.class "text-sm eco-breadcrumb-text"
            ]
            [ Html.text "Articles" ]
        , Html.span
            [ Attrs.class "eco-breadcrumb-text"
            ]
            [ Html.text "/" ]
        , Html.span
            [ Attrs.class "text-sm eco-breadcrumb-text"
            ]
            [ Html.text meta.section ]
        , Html.span
            [ Attrs.class "eco-breadcrumb-text"
            ]
            [ Html.text "/" ]
        , Html.span
            [ Attrs.class "text-sm font-medium eco-breadcrumb-active"
            ]
            [ Html.text meta.title ]
        ]



-- PAGE HEADER


viewPageHeader : ArticleMetadata -> Html msg
viewPageHeader meta =
    Html.div
        [ Attrs.class "flex flex-col gap-3 eco-page-header"
        ]
        [ Html.h1
            [ Attrs.class "text-4xl font-semibold eco-page-title"
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


viewBannerImage : ArticleMetadata -> Html msg
viewBannerImage meta =
    Html.Extra.viewMaybe
        (\imagePath ->
            Html.img
                [ Attrs.src imagePath
                , Attrs.alt meta.title
                , Attrs.class "w-full rounded-lg mt-4"
                ]
                []
        )
        meta.image



-- BODY


viewArticleBody : List Block -> List (Html msg)
viewArticleBody blocks =
    Markdown.docsBlocksToHtml blocks


viewDivider : Html msg
viewDivider =
    Html.div
        [ Attrs.class "eco-content-divider"
        ]
        []



-- PAGE NAVIGATION


viewPageNav : Maybe ArticleMetadata -> Maybe ArticleMetadata -> Html msg
viewPageNav previous next =
    Html.div
        [ Attrs.class "flex items-center justify-between"
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


viewPrevLink : ArticleMetadata -> Html msg
viewPrevLink meta =
    Route.Articles__Slug_ { slug = meta.slug }
        |> Route.link
            [ Attrs.class "flex flex-col gap-1 no-underline"
            ]
            [ Html.span
                [ Attrs.class "text-xs eco-page-nav-label"
                ]
                [ Html.text "Previous" ]
            , Html.div [ Attrs.class "flex items-center gap-1.5" ]
                [ arrowLeftIcon
                , Html.span
                    [ Attrs.class "text-sm font-medium eco-page-nav-title"
                    ]
                    [ Html.text meta.title ]
                ]
            ]


viewNextLink : ArticleMetadata -> Html msg
viewNextLink meta =
    Route.Articles__Slug_ { slug = meta.slug }
        |> Route.link
            [ Attrs.class "flex flex-col items-end gap-1 no-underline"
            ]
            [ Html.span
                [ Attrs.class "text-xs eco-page-nav-label"
                ]
                [ Html.text "Next" ]
            , Html.div [ Attrs.class "flex items-center gap-1.5" ]
                [ Html.span
                    [ Attrs.class "text-sm font-medium eco-page-nav-title"
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
