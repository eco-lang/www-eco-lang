module Layout.PackageMarkdown exposing (blocksToHtml)

{-| Markdown for the packages pages: a package's README and its doc comments, styled by `Style.Packages`.

These are written for package.elm-lang.org, so they are read as that site reads them: a code block with no language
is Elm, a relative link such as `Stream#pipe` names a module of the same package, and a link to `/packages/...` names a
package on package.elm-lang.org, unless it is one this site hosts.

@docs blocksToHtml

-}

import Html exposing (Html)
import Html.Attributes as Attrs
import Markdown.Block as Block
import Markdown.Renderer exposing (defaultHtmlRenderer)
import String.Normalize
import SyntaxHighlight


{-| Render Markdown blocks. `base` is the package's path, such as `/packages/eco/system/`, and `hosted` lists the
packages this site hosts, such as `eco/system`.
-}
blocksToHtml : { base : String, hosted : List String } -> List Block.Block -> List (Html msg)
blocksToHtml config blocks =
    Markdown.Renderer.render (renderer config) blocks
        |> Result.withDefault [ Html.text "failed to render markdown" ]


renderer : { base : String, hosted : List String } -> Markdown.Renderer.Renderer (Html msg)
renderer config =
    { defaultHtmlRenderer
        | heading =
            \{ level, rawText, children } ->
                let
                    ( tag, headingClass ) =
                        case level of
                            Block.H1 ->
                                ( Html.h1, "pkg-md-h1" )

                            Block.H2 ->
                                ( Html.h2, "pkg-md-h2" )

                            Block.H3 ->
                                ( Html.h3, "pkg-md-h3" )

                            _ ->
                                ( Html.h4, "pkg-md-h4" )
                in
                tag [ Attrs.id (String.Normalize.slug rawText), Attrs.class headingClass ] children
        , paragraph = Html.p [ Attrs.class "pkg-md-p" ]
        , blockQuote = Html.blockquote [ Attrs.class "pkg-md-blockquote" ]
        , codeSpan = \content -> Html.code [ Attrs.class "pkg-md-code" ] [ Html.text content ]
        , codeBlock = codeBlock
        , unorderedList =
            \items ->
                Html.ul [ Attrs.class "pkg-md-ul" ]
                    (List.map (\(Block.ListItem _ children) -> Html.li [ Attrs.class "pkg-md-li" ] children) items)
        , orderedList =
            \startingIndex items ->
                Html.ol [ Attrs.start startingIndex, Attrs.class "pkg-md-ol" ]
                    (List.map (Html.li [ Attrs.class "pkg-md-li" ]) items)
        , table =
            \children ->
                Html.div [ Attrs.class "pkg-md-table-wrap" ] [ Html.table [ Attrs.class "pkg-md-table" ] children ]
        , tableHeaderCell = \_ -> Html.th [ Attrs.class "pkg-md-cell" ]
        , tableCell = \_ -> Html.td [ Attrs.class "pkg-md-cell" ]
        , image =
            \image -> Html.img [ Attrs.src image.src, Attrs.alt image.alt, Attrs.class "pkg-md-img" ] []
        , thematicBreak = Html.hr [ Attrs.class "pkg-md-hr" ] []
        , strong = Html.strong [ Attrs.class "pkg-md-strong" ]
        , link =
            \link content ->
                Html.a
                    (Attrs.href (packageLink config link.destination)
                        :: Attrs.class "pkg-md-link"
                        :: (link.title |> Maybe.map Attrs.title |> Maybe.map List.singleton |> Maybe.withDefault [])
                    )
                    content
    }


{-| A code block, highlighted as Elm unless it names another language, without line numbers. An indented code block
keeps the blank lines after it, which are trimmed.
-}
codeBlock : { body : String, language : Maybe String } -> Html msg
codeBlock block =
    let
        body =
            String.trimRight block.body

        highlighted =
            case block.language of
                Nothing ->
                    SyntaxHighlight.elm body

                Just "" ->
                    SyntaxHighlight.elm body

                Just "elm" ->
                    SyntaxHighlight.elm body

                Just _ ->
                    SyntaxHighlight.noLang body
    in
    Html.div [ Attrs.class "pkg-md-pre" ]
        [ highlighted
            |> Result.map (SyntaxHighlight.toBlockHtml Nothing)
            |> Result.withDefault (Html.pre [] [ Html.code [] [ Html.text body ] ])
        ]


{-| Where a link in package docs points on this site.
-}
packageLink : { base : String, hosted : List String } -> String -> String
packageLink config destination =
    if
        String.startsWith "#" destination
            || String.contains "://" destination
            || String.startsWith "mailto:" destination
    then
        destination

    else if String.startsWith "/packages/" destination then
        case String.split "/" destination of
            "" :: "packages" :: author :: name :: _ ->
                if List.member (author ++ "/" ++ name) config.hosted then
                    destination

                else
                    "https://package.elm-lang.org" ++ destination

            _ ->
                destination

    else if String.startsWith "/" destination then
        destination

    else
        config.base ++ destination
