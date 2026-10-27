module Layout.Packages exposing (moduleDescription, seo, viewIndexPage, viewModulePage, viewPackagePage)

{-| The pages of the packages section: the list of packages, each package's overview (its README and what its
`elm.json` says), and the docs of each exposed module, laid out like package.elm-lang.org in the site's style.
-}

import Code.ElmSignature as Signature
import Content.Packages exposing (Declaration, DeclarationKind(..), ModuleDocs, PackageInfo, Section(..))
import Dict exposing (Dict)
import Head
import Head.Seo as Seo
import Html exposing (Html)
import Html.Attributes as Attrs
import Layout.Markdown as Markdown
import Layout.Site
import Markdown.Block as Block exposing (Block)
import MimeType
import Pages.Url
import Route
import Settings
import Style
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
        , contents = List.map (\info -> menuSection Nothing info) packages
        , sidebar = indexSidebar packages
        , main =
            [ Html.div [ Attrs.class "eco-page-header" ]
                [ Html.h1 [ Attrs.class "eco-page-title" ] [ Html.text "Packages" ]
                , Html.p [ Attrs.class "eco-page-desc" ]
                    [ Html.text "API documentation for the packages that come with eco." ]
                ]
            , divider
            , Html.div [ Attrs.class "eco-pkg-list" ] (List.map viewPackageCard packages)
            ]
        }


{-| `/packages/author/name`: the package's README and its details.
-}
viewPackagePage : List String -> PackageInfo -> List Block -> List (Html msg)
viewPackagePage hosted info readme =
    page
        { path = packageHref info
        , contents = [ menuSection (Just Overview) info ]
        , sidebar = packageSidebar (Just Overview) info
        , main =
            [ breadcrumb [ ( "Packages", Just (Route.toString Route.Packages) ) ] (packageName info)
            , Html.div [ Attrs.class "eco-page-header" ]
                [ Html.h1 [ Attrs.class "eco-page-title" ] [ Html.text (packageName info) ]
                , Html.p [ Attrs.class "eco-page-desc" ] [ Html.text info.summary ]
                ]
            , viewFacts info
            , divider
            , Html.article [ Attrs.class "eco-article-body" ]
                (Markdown.packageBlocksToHtml (linkConfig hosted info) (dropTitle info readme)
                    ++ viewDependencies info
                )
            ]
        }


{-| `/packages/author/name/Module-Name`: a module's docs.
-}
viewModulePage : List String -> PackageInfo -> ModuleDocs -> List (Html msg)
viewModulePage hosted info docs =
    let
        ( previous, next ) =
            neighbours docs.name (exposedModules info)
    in
    page
        { path = moduleHref info docs.name
        , contents = [ menuSection (Just (Module docs.name)) info ]
        , sidebar = packageSidebar (Just (Module docs.name)) info
        , main =
            [ breadcrumb
                [ ( "Packages", Just (Route.toString Route.Packages) )
                , ( packageName info, Just (packageHref info) )
                ]
                docs.name
            , Html.div [ Attrs.class "eco-page-header" ]
                [ Html.h1 [ Attrs.class "eco-page-title" ] [ Html.text docs.name ] ]
            , divider
            , Html.article [ Attrs.class "eco-article-body" ]
                (List.map (viewSection (linkConfig hosted info) info docs.name) docs.sections)
            , divider
            , viewPageNav info previous next
            ]
        }


{-| The modules before and after a module in the package's list.
-}
neighbours : String -> List String -> ( Maybe String, Maybe String )
neighbours name modules =
    case modules of
        first :: second :: rest ->
            if first == name then
                ( Nothing, Just second )

            else if second == name then
                ( Just first, List.head rest )

            else
                neighbours name (second :: rest)

        _ ->
            ( Nothing, Nothing )


page :
    { path : String
    , contents : List Layout.Site.MenuSection
    , sidebar : Html msg
    , main : List (Html msg)
    }
    -> List (Html msg)
page { path, contents, sidebar, main } =
    [ Html.div [ Attrs.class "eco-page" ]
        [ Layout.Site.viewHeader { active = Just Layout.Site.Packages, path = path, contents = contents }
        , Html.div [ Attrs.class "eco-page-body" ]
            [ sidebar
            , Html.main_ [ Attrs.class "eco-content-area" ] main
            ]
        , Layout.Site.viewFooterDivider
        , Layout.Site.viewFooter
        ]
    ]



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



-- NAVIGATION


type Current
    = Overview
    | Module String


menuSection : Maybe Current -> PackageInfo -> Layout.Site.MenuSection
menuSection current info =
    { title = packageName info
    , links =
        { label = "Overview", href = packageHref info, current = current == Just Overview }
            :: List.map
                (\moduleName ->
                    { label = moduleName
                    , href = moduleHref info moduleName
                    , current = current == Just (Module moduleName)
                    }
                )
                (exposedModules info)
    }


indexSidebar : List PackageInfo -> Html msg
indexSidebar packages =
    Html.aside [ Attrs.class "eco-sidebar" ]
        [ Html.span [ Attrs.class "eco-sidebar-title" ] [ Html.text "Packages" ]
        , Html.div [ Attrs.class "eco-sidebar-spacer" ] []
        , Html.div [ Attrs.class "eco-toc-items" ]
            (List.map (\info -> tocLink False (packageHref info) (packageName info)) packages)
        ]


packageSidebar : Maybe Current -> PackageInfo -> Html msg
packageSidebar current info =
    Html.aside [ Attrs.class "eco-sidebar" ]
        (Html.span [ Attrs.class "eco-sidebar-title" ] [ Html.text (packageName info) ]
            :: Html.div [ Attrs.class "eco-sidebar-spacer" ] []
            :: Html.div [ Attrs.class "eco-toc-items" ]
                [ tocLink (current == Just Overview) (packageHref info) "Overview" ]
            :: Html.div [ Attrs.class "eco-toc-gap" ] []
            :: List.concatMap
                (\group ->
                    [ Html.div [ Attrs.class "eco-toc-section" ]
                        [ Html.span [ Attrs.class "eco-toc-section-name" ]
                            [ Html.text (Maybe.withDefault "Modules" group.title) ]
                        ]
                    , Html.div [ Attrs.class "eco-toc-items" ]
                        (List.map
                            (\moduleName ->
                                tocLink (current == Just (Module moduleName)) (moduleHref info moduleName) moduleName
                            )
                            group.modules
                        )
                    , Html.div [ Attrs.class "eco-toc-gap" ] []
                    ]
                )
                info.modules
        )


tocLink : Bool -> String -> String -> Html msg
tocLink isActive href label =
    Html.a
        [ Attrs.href href
        , Attrs.class
            (if isActive then
                "eco-toc-item-active"

             else
                "eco-toc-item"
            )
        ]
        [ Html.text label ]


breadcrumb : List ( String, Maybe String ) -> String -> Html msg
breadcrumb trail active =
    Html.nav [ Attrs.class "eco-breadcrumb" ]
        (List.concatMap
            (\( label, href ) ->
                [ case href of
                    Just url ->
                        Html.a [ Attrs.href url, Attrs.class "eco-breadcrumb-link" ] [ Html.text label ]

                    Nothing ->
                        Html.span [ Attrs.class "eco-breadcrumb-text" ] [ Html.text label ]
                , Html.span [ Attrs.class "eco-breadcrumb-sep" ] [ Html.text "/" ]
                ]
            )
            trail
            ++ [ Html.span [ Attrs.class "eco-breadcrumb-active" ] [ Html.text active ] ]
        )


divider : Html msg
divider =
    Html.div [ Attrs.class "eco-content-divider" ] []


viewPageNav : PackageInfo -> Maybe String -> Maybe String -> Html msg
viewPageNav info previous next =
    let
        link className label moduleName icons =
            Html.a [ Attrs.href (moduleHref info moduleName), Attrs.class className ]
                [ Html.span [ Attrs.class "eco-page-nav-label" ] [ Html.text label ]
                , Html.div [ Attrs.class "eco-page-nav-link-row" ] (icons (Html.span [ Attrs.class "eco-page-nav-title" ] [ Html.text moduleName ]))
                ]
    in
    Html.div [ Attrs.class "eco-page-nav" ]
        [ case previous of
            Just moduleName ->
                link "eco-page-nav-prev" "Previous" moduleName (\title -> [ arrowIcon "m12 19-7-7 7-7" "M19 12H5", title ])

            Nothing ->
                Html.div [] []
        , case next of
            Just moduleName ->
                link "eco-page-nav-next" "Next" moduleName (\title -> [ title, arrowIcon "m12 5 7 7-7 7" "M5 12h14" ])

            Nothing ->
                Html.div [] []
        ]


arrowIcon : String -> String -> Html msg
arrowIcon head shaft =
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
        [ Svg.path [ SvgAttrs.d head ] []
        , Svg.path [ SvgAttrs.d shaft ] []
        ]



-- PACKAGE LIST AND OVERVIEW


viewPackageCard : PackageInfo -> Html msg
viewPackageCard info =
    Html.a [ Attrs.href (packageHref info), Attrs.class "eco-pkg-card" ]
        [ Html.div [ Attrs.class "eco-pkg-card-head" ]
            [ Html.span [ Attrs.class "eco-pkg-card-name" ] [ Html.text (packageName info) ]
            , Html.span [ Attrs.class "eco-pkg-card-version" ] [ Html.text info.version ]
            ]
        , Html.p [ Attrs.class "eco-pkg-card-summary" ] [ Html.text info.summary ]
        ]


viewFacts : PackageInfo -> Html msg
viewFacts info =
    let
        fact label content =
            Html.div [ Attrs.class "eco-pkg-fact" ]
                [ Html.span [ Attrs.class "eco-pkg-fact-label" ] [ Html.text label ]
                , Html.span [ Attrs.class "eco-pkg-fact-value" ] content
                ]
    in
    Html.div [ Attrs.class "eco-pkg-facts" ]
        [ fact "Version" [ Html.text info.version ]
        , fact "License" [ Html.text info.license ]
        , fact "Install"
            [ Html.code [ Attrs.class "eco-doc-code-inline" ] [ Html.text ("eco install " ++ packageName info) ] ]
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
        [ Html.h2 [ Attrs.id "dependencies", Attrs.class "eco-doc-h2" ] [ Html.text "Dependencies" ]
        , Html.ul [ Attrs.class "eco-doc-ul" ]
            (List.map
                (\( name, constraint ) ->
                    Html.li [ Attrs.class "eco-doc-li" ]
                        [ Html.span [ Attrs.class "eco-doc-bullet" ] []
                        , Html.span [ Attrs.class "eco-doc-bullet-text" ]
                            [ Html.a
                                [ Attrs.href ("https://package.elm-lang.org/packages/" ++ name ++ "/latest/")
                                , Attrs.class "eco-doc-link"
                                ]
                                [ Html.text name ]
                            , Html.span [ Attrs.class "eco-pkg-constraint" ] [ Html.text constraint ]
                            ]
                        ]
                )
                info.dependencies
            )
        ]



-- MODULE DOCS


viewSection : { base : String, hosted : List String } -> PackageInfo -> String -> Section -> Html msg
viewSection config info moduleName section =
    case section of
        Prose blocks ->
            Html.div [] (Markdown.packageBlocksToHtml config blocks)

        DeclarationSection declaration ->
            viewDeclaration config info moduleName declaration


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
    Html.div [ Attrs.id declaration.name, Attrs.class "eco-pkg-decl" ]
        [ Html.pre [ Attrs.class "eco-pkg-sig" ]
            [ Html.code []
                (List.intersperse [ Html.text "\n" ]
                    (List.map (List.map (viewPiece info moduleName declaration.name)) lines)
                    |> List.concat
                )
            ]
        , Html.div [ Attrs.class "eco-pkg-decl-doc" ] (Markdown.packageBlocksToHtml config declaration.comment)
        ]


viewPiece : PackageInfo -> String -> String -> Signature.Piece -> Html msg
viewPiece info moduleName declarationName piece =
    case piece of
        Signature.Name name ->
            Html.a [ Attrs.href ("#" ++ declarationName), Attrs.class "eco-pkg-sig-name" ] [ Html.text name ]

        Signature.Keyword text ->
            Html.span [ Attrs.class "eco-pkg-sig-keyword" ] [ Html.text text ]

        Signature.TypeRef { label, qualified } ->
            case typeHref info moduleName qualified of
                Just href ->
                    Html.a [ Attrs.href href, Attrs.class "eco-pkg-sig-type" ] [ Html.text label ]

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
