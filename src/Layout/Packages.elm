module Layout.Packages exposing (moduleDescription, seo, viewIndexPage, viewModulePage, viewPackagePage)

{-| The pages of the packages section: the list of packages, each package's overview (its README and what its
`elm.json` says), and the docs of each exposed module.

They are laid out as a site of their own, modelled on package.elm-lang.org, because they will move to one: a band of
colour across the top, the content on the left and the package's menu on the right. Their styles are in
`Style.Packages`.

-}

import Code.ElmSignature as Signature
import Content.Packages exposing (Declaration, DeclarationKind(..), ModuleDocs, PackageInfo, Section(..))
import Dict exposing (Dict)
import Head
import Head.Seo as Seo
import Html exposing (Html)
import Html.Attributes as Attrs
import Html.Keyed
import Layout.PackageMarkdown as Markdown
import Markdown.Block as Block exposing (Block)
import MimeType
import Pages.Url
import Route
import Settings
import Svg
import Svg.Attributes as SvgAttrs
import UrlPath



-- PAGES


{-| `/packages`: every hosted package, with its summary.
-}
viewIndexPage : List PackageInfo -> List (Html msg)
viewIndexPage packages =
    page
        { path = Route.toString Route.Packages
        , crumbs = []
        , nav = indexNav
        , main =
            [ Html.h1 [ Attrs.class "pkg-title" ] [ Html.text "Packages" ]
            , Html.p [ Attrs.class "pkg-subtitle" ] [ Html.text "API documentation for the packages that come with eco." ]
            , Html.div [] (List.map viewSummary packages)
            ]
        }


{-| `/packages/author/name`: the package's README and its dependencies.
-}
viewPackagePage : List String -> PackageInfo -> List Block -> List (Html msg)
viewPackagePage hosted info readme =
    page
        { path = packageHref info
        , crumbs = packageCrumbs info
        , nav = packageNav Overview info
        , main =
            Html.h1 [ Attrs.class "pkg-title" ] [ Html.text (packageName info) ]
                :: Markdown.blocksToHtml (linkConfig hosted info) (dropTitle info readme)
                ++ viewDependencies info
        }


{-| `/packages/author/name/Module-Name`: a module's docs.
-}
viewModulePage : List String -> PackageInfo -> ModuleDocs -> List (Html msg)
viewModulePage hosted info docs =
    page
        { path = moduleHref info docs.name
        , crumbs = packageCrumbs info
        , nav = packageNav (Module docs.name) info
        , main =
            Html.h1 [ Attrs.class "pkg-title" ] [ Html.text docs.name ]
                :: List.concatMap (viewSection (linkConfig hosted info) info docs.name) docs.sections
        }


{-| A page: the band, the content with the menu on its right, and the footer. On a phone the menu moves into the
band, as a menu that opens. `path` keys that menu, so that navigating to another page renders it closed.
-}
page :
    { path : String
    , crumbs : List Crumb
    , nav : List (Html msg)
    , main : List (Html msg)
    }
    -> List (Html msg)
page { path, crumbs, nav, main } =
    [ Html.div [ Attrs.class "pkg-page" ]
        [ Html.header [ Attrs.class "pkg-band" ]
            [ Html.div [ Attrs.class "pkg-band-inner" ]
                [ Html.div [ Attrs.class "pkg-band-start" ]
                    [ Html.a [ Attrs.href (Route.toString Route.Packages), Attrs.class "pkg-logo" ]
                        [ Html.span [ Attrs.class "pkg-logo-mark" ] [ Html.text "eco" ]
                        , Html.span [ Attrs.class "pkg-logo-word" ] [ Html.text "packages" ]
                        ]
                    , Html.div [ Attrs.class "pkg-crumbs" ] (List.concatMap viewCrumb crumbs)
                    ]
                , Html.div [ Attrs.class "pkg-band-end" ]
                    [ Html.a [ Attrs.href "/", Attrs.class "pkg-band-home" ] [ Html.text "eco-lang.org", arrowIcon ]
                    , Html.Keyed.node "div"
                        []
                        [ ( path
                          , Html.node "details"
                                [ Attrs.class "pkg-menu" ]
                                [ Html.node "summary"
                                    [ Attrs.class "pkg-menu-button", Attrs.attribute "aria-label" "Menu" ]
                                    [ menuIcon, closeIcon ]
                                , Html.nav [ Attrs.class "pkg-menu-panel" ] [ Html.div [ Attrs.class "pkg-nav" ] nav ]
                                ]
                          )
                        ]
                    ]
                ]
            ]
        , Html.div [ Attrs.class "pkg-body" ]
            [ Html.main_ [ Attrs.class "pkg-main" ] main
            , Html.aside [ Attrs.class "pkg-side" ] [ Html.nav [ Attrs.class "pkg-nav" ] nav ]
            ]
        , Html.footer [ Attrs.class "pkg-footer" ]
            [ Html.span [] [ Html.text ("eco packages \u{2014} release " ++ Settings.version) ]
            , Html.a [ Attrs.href "/", Attrs.class "pkg-footer-link" ] [ Html.text "eco-lang.org" ]
            , Html.a [ Attrs.href "/docs", Attrs.class "pkg-footer-link" ] [ Html.text "Documentation" ]
            , Html.a [ Attrs.href githubUrl, Attrs.class "pkg-footer-link" ] [ Html.text "GitHub" ]
            ]
        ]
    ]


type alias Crumb =
    { label : String, href : Maybe String }


packageCrumbs : PackageInfo -> List Crumb
packageCrumbs info =
    [ { label = packageName info, href = Just (packageHref info) }
    , { label = info.version, href = Nothing }
    ]


viewCrumb : Crumb -> List (Html msg)
viewCrumb crumb =
    [ Html.span [ Attrs.class "pkg-crumb-sep" ] [ Html.text "/" ]
    , case crumb.href of
        Just href ->
            Html.a [ Attrs.href href, Attrs.class "pkg-crumb" ] [ Html.text crumb.label ]

        Nothing ->
            Html.span [ Attrs.class "pkg-crumb-current" ] [ Html.text crumb.label ]
    ]


githubUrl : String
githubUrl =
    "https://github.com/eco-lang/eco-compiler"


-- HEAD


{-| The head tags of a packages page.
-}
seo : { title : String, description : String } -> List Head.Tag
seo { title, description } =
    Seo.summaryLarge
        { canonicalUrlOverride = Nothing
        , siteName = Settings.title
        , image =
            { url = [ "images", "site-image.png" ] |> UrlPath.join |> Pages.Url.fromPath
            , alt = Settings.title
            , dimensions = Just { width = 810, height = 523 }
            , mimeType = Just (MimeType.Image MimeType.Png)
            }
        , description = description
        , locale = Settings.locale
        , title = title
        }
        |> Seo.website


{-| A module's description for search results: the first paragraph of its module comment, cut to about 160
characters.
-}
moduleDescription : PackageInfo -> ModuleDocs -> String
moduleDescription info docs =
    let
        firstParagraph =
            List.concatMap
                (\section ->
                    case section of
                        Prose blocks ->
                            List.filterMap
                                (\block ->
                                    case block of
                                        Block.Paragraph inlines ->
                                            Just (Block.extractInlineText inlines)

                                        _ ->
                                            Nothing
                                )
                                blocks

                        DeclarationSection _ ->
                            []
                )
                docs.sections
                |> List.head
                |> Maybe.map (String.words >> String.join " ")
    in
    case firstParagraph of
        Just text ->
            if String.length text <= 160 then
                text

            else
                (String.left 157 text |> String.words |> List.reverse |> List.drop 1 |> List.reverse |> String.join " ")
                    ++ "…"

        Nothing ->
            "The " ++ docs.name ++ " module of " ++ packageName info ++ "."



-- PATHS


packageName : PackageInfo -> String
packageName info =
    info.author ++ "/" ++ info.name


packageHref : PackageInfo -> String
packageHref info =
    Route.toString (Route.Packages__Author___Name_ { author = info.author, name = info.name })


moduleHref : PackageInfo -> String -> String
moduleHref info moduleName =
    Route.toString
        (Route.Packages__Author___Name___ModuleName_
            { author = info.author, name = info.name, moduleName = Content.Packages.moduleSlug moduleName }
        )


linkConfig : List String -> PackageInfo -> { base : String, hosted : List String }
linkConfig hosted info =
    { base = packageHref info ++ "/", hosted = hosted }


exposedModules : PackageInfo -> List String
exposedModules info =
    List.concatMap .modules info.modules



-- MENU


type Current
    = Overview
    | Module String


indexNav : List (Html msg)
indexNav =
    [ heading "Resources"
    , Html.div [ Attrs.class "pkg-nav-list" ]
        [ navLink False "/docs" "eco documentation"
        , navLink False "/" "eco-lang.org"
        , navLink False "https://package.elm-lang.org" "Elm packages"
        , navLink False githubUrl "GitHub"
        ]
    ]


{-| The menu of a package's pages: its overview, what its `elm.json` says, and its modules, with the current one
marked.
-}
packageNav : Current -> PackageInfo -> List (Html msg)
packageNav current info =
    Html.h2 [ Attrs.class "pkg-nav-heading" ]
        [ navLink (current == Overview) (packageHref info) "Overview" ]
        :: heading "About"
        :: Html.div [ Attrs.class "pkg-about" ]
            [ aboutRow "Version" info.version
            , aboutRow "License" info.license
            , Html.span [ Attrs.class "pkg-about-label" ] [ Html.text "Install" ]
            , Html.code [ Attrs.class "pkg-about-code" ] [ Html.text ("eco install " ++ packageName info) ]
            ]
        :: List.concatMap
            (\group ->
                [ heading (Maybe.withDefault "Modules" group.title)
                , Html.div [ Attrs.class "pkg-nav-list" ] (List.map (navModule current info) group.modules)
                ]
            )
            info.modules


navModule : Current -> PackageInfo -> String -> Html msg
navModule current info moduleName =
    if current == Module moduleName then
        Html.a
            [ Attrs.href (moduleHref info moduleName)
            , Attrs.class "pkg-nav-module-current"
            , Attrs.attribute "aria-current" "page"
            ]
            [ Html.text moduleName ]

    else
        Html.a [ Attrs.href (moduleHref info moduleName), Attrs.class "pkg-nav-module" ] [ Html.text moduleName ]


heading : String -> Html msg
heading text =
    Html.h2 [ Attrs.class "pkg-nav-heading" ] [ Html.text text ]


aboutRow : String -> String -> Html msg
aboutRow label value =
    Html.div [ Attrs.class "pkg-about-row" ]
        [ Html.span [ Attrs.class "pkg-about-label" ] [ Html.text label ]
        , Html.span [] [ Html.text value ]
        ]


navLink : Bool -> String -> String -> Html msg
navLink isCurrent href label =
    if isCurrent then
        Html.a [ Attrs.href href, Attrs.class "pkg-nav-link-current", Attrs.attribute "aria-current" "page" ]
            [ Html.text label ]

    else
        Html.a [ Attrs.href href, Attrs.class "pkg-nav-link" ] [ Html.text label ]


menuIcon : Html msg
menuIcon =
    icon "pkg-menu-icon-open" 22 "M4 6h16M4 12h16M4 18h16"


closeIcon : Html msg
closeIcon =
    icon "pkg-menu-icon-close" 22 "M6 6l12 12M18 6L6 18"


{-| Marks the link back to the main site as a link to another site.
-}
arrowIcon : Html msg
arrowIcon =
    icon "" 14 "M7 17 17 7M8 7h9v9"


icon : String -> Int -> String -> Html msg
icon className size path =
    Svg.svg
        [ SvgAttrs.class className
        , SvgAttrs.width (String.fromInt size)
        , SvgAttrs.height (String.fromInt size)
        , SvgAttrs.viewBox "0 0 24 24"
        , SvgAttrs.fill "none"
        , SvgAttrs.stroke "currentColor"
        , SvgAttrs.strokeWidth "2"
        , SvgAttrs.strokeLinecap "round"
        , SvgAttrs.strokeLinejoin "round"
        ]
        [ Svg.path [ SvgAttrs.d path ] [] ]



-- PACKAGE LIST AND OVERVIEW


viewSummary : PackageInfo -> Html msg
viewSummary info =
    Html.div [ Attrs.class "pkg-summary" ]
        [ Html.div [ Attrs.class "pkg-summary-head" ]
            [ Html.a [ Attrs.href (packageHref info), Attrs.class "pkg-summary-name" ] [ Html.text (packageName info) ]
            , Html.span [ Attrs.class "pkg-summary-version" ] [ Html.text info.version ]
            ]
        , Html.p [ Attrs.class "pkg-summary-desc" ] [ Html.text info.summary ]
        ]


{-| The README starts with the package's name as its title, which the page header already shows.
-}
dropTitle : PackageInfo -> List Block -> List Block
dropTitle info blocks =
    case blocks of
        (Block.Heading Block.H1 inlines) :: rest ->
            if String.trim (Block.extractInlineText inlines) == packageName info then
                rest

            else
                blocks

        _ ->
            blocks


viewDependencies : PackageInfo -> List (Html msg)
viewDependencies info =
    if List.isEmpty info.dependencies then
        []

    else
        [ Html.h2 [ Attrs.id "dependencies", Attrs.class "pkg-md-h2" ] [ Html.text "Dependencies" ]
        , Html.ul [ Attrs.class "pkg-md-ul" ]
            (List.map
                (\( name, constraint ) ->
                    Html.li [ Attrs.class "pkg-md-li" ]
                        [ Html.a
                            [ Attrs.href ("https://package.elm-lang.org/packages/" ++ name ++ "/latest/")
                            , Attrs.class "pkg-md-link"
                            ]
                            [ Html.text name ]
                        , Html.span [ Attrs.class "pkg-dependency-version" ] [ Html.text constraint ]
                        ]
                )
                info.dependencies
            )
        ]



-- MODULE DOCS


viewSection : { base : String, hosted : List String } -> PackageInfo -> String -> Section -> List (Html msg)
viewSection config info moduleName section =
    case section of
        Prose blocks ->
            Markdown.blocksToHtml config blocks

        DeclarationSection declaration ->
            [ viewDeclaration config info moduleName declaration ]


{-| A declaration: its header on the left edge of the page, the name linking to the declaration itself, and its doc
comment inset below.
-}
viewDeclaration : { base : String, hosted : List String } -> PackageInfo -> String -> Declaration -> Html msg
viewDeclaration config info moduleName declaration =
    let
        lines =
            case declaration.kind of
                UnionKind union ->
                    Signature.union declaration.name union

                AliasKind alias ->
                    Signature.alias declaration.name alias

                ValueKind tipe ->
                    Signature.value declaration.name tipe

                BinopKind tipe ->
                    Signature.binop declaration.name tipe

                UnknownKind ->
                    [ [ Signature.Name declaration.name ] ]
    in
    Html.div [ Attrs.id declaration.name, Attrs.class "pkg-decl" ]
        [ Html.pre [ Attrs.class "pkg-decl-header" ]
            [ Html.code []
                (List.intersperse [ Html.text "\n" ]
                    (List.map (List.map (viewPiece info moduleName declaration.name)) lines)
                    |> List.concat
                )
            ]
        , Html.div [ Attrs.class "pkg-decl-comment" ] (Markdown.blocksToHtml config declaration.comment)
        ]


viewPiece : PackageInfo -> String -> String -> Signature.Piece -> Html msg
viewPiece info moduleName declarationName piece =
    case piece of
        Signature.Name name ->
            Html.a [ Attrs.href ("#" ++ declarationName), Attrs.class "pkg-decl-name" ] [ Html.text name ]

        Signature.Keyword text ->
            Html.span [ Attrs.class "pkg-decl-keyword" ] [ Html.text text ]

        Signature.TypeRef { label, qualified } ->
            case typeHref info moduleName qualified of
                Just href ->
                    Html.a [ Attrs.href href, Attrs.class "pkg-decl-type" ] [ Html.text label ]

                Nothing ->
                    Html.text label

        Signature.Text text ->
            Html.text text


{-| Where a qualified type name, such as `Path.Path`, is documented: on this page, on another page of the package, or
on package.elm-lang.org for the `elm/*` packages. Types of the package's internal modules are not linked.
-}
typeHref : PackageInfo -> String -> String -> Maybe String
typeHref info moduleName qualified =
    let
        segments =
            String.split "." qualified

        typeName =
            List.reverse segments |> List.head |> Maybe.withDefault qualified

        home =
            String.join "." (List.take (List.length segments - 1) segments)
    in
    if home == moduleName then
        Just ("#" ++ typeName)

    else if List.member home (exposedModules info) then
        Just (moduleHref info home ++ "#" ++ typeName)

    else
        Dict.get home elmModules
            |> Maybe.map
                (\package ->
                    "https://package.elm-lang.org/packages/"
                        ++ package
                        ++ "/latest/"
                        ++ Content.Packages.moduleSlug home
                        ++ "#"
                        ++ typeName
                )


{-| The modules of the `elm/*` packages, and the package each belongs to.
-}
elmModules : Dict String String
elmModules =
    [ ( "elm/core"
      , [ "Array", "Basics", "Bitwise", "Char", "Debug", "Dict", "List", "Maybe", "Platform", "Platform.Cmd", "Platform.Sub", "Process", "Result", "Set", "String", "Task", "Tuple" ]
      )
    , ( "elm/json", [ "Json.Decode", "Json.Encode" ] )
    , ( "elm/bytes", [ "Bytes", "Bytes.Decode", "Bytes.Encode" ] )
    , ( "elm/http", [ "Http" ] )
    , ( "elm/time", [ "Time" ] )
    , ( "elm/url", [ "Url", "Url.Builder", "Url.Parser", "Url.Parser.Query" ] )
    , ( "elm/html", [ "Html", "Html.Attributes", "Html.Events", "Html.Keyed", "Html.Lazy" ] )
    , ( "elm/svg", [ "Svg", "Svg.Attributes", "Svg.Events" ] )
    , ( "elm/virtual-dom", [ "VirtualDom" ] )
    ]
        |> List.concatMap (\( package, modules ) -> List.map (\name -> ( name, package )) modules)
        |> Dict.fromList
