module Layout.Markdown exposing (docsBlocksToHtml, docsSyntaxHighlight)

import Html exposing (Html)
import Html.Attributes as Attrs
import Markdown.Block as Block
import Markdown.Renderer exposing (defaultHtmlRenderer)
import Parser exposing (DeadEnd)
import String.Normalize
import SyntaxHighlight


language : Maybe String -> String -> Result (List DeadEnd) SyntaxHighlight.HCode
language lang =
    case lang of
        Just "elm" ->
            SyntaxHighlight.elm

        Just "css" ->
            SyntaxHighlight.css

        Just "sql" ->
            SyntaxHighlight.sql

        Just "xml" ->
            SyntaxHighlight.xml

        Just "html" ->
            SyntaxHighlight.xml

        Just "nix" ->
            SyntaxHighlight.nix

        Just "json" ->
            SyntaxHighlight.json

        Just "python" ->
            SyntaxHighlight.python

        _ ->
            SyntaxHighlight.noLang


-- DOCS RENDERER


docsSyntaxHighlight : { a | language : Maybe String, body : String } -> Html msg
docsSyntaxHighlight codeBlock =
    let
        sanitiseCodeBlock =
            if String.endsWith "\n" codeBlock.body then
                String.dropRight 1 codeBlock.body

            else
                codeBlock.body
    in
    Html.div
        [ Attrs.class "eco-doc-code-block"
        ]
        [ language codeBlock.language sanitiseCodeBlock
            |> Result.map (SyntaxHighlight.toBlockHtml (Just 1))
            |> Result.withDefault
                (Html.pre
                    [ Attrs.class "eco-doc-code-fallback"
                    ]
                    [ Html.code [] [ Html.text sanitiseCodeBlock ] ]
                )
        ]


docsRenderer : Markdown.Renderer.Renderer (Html msg)
docsRenderer =
    { defaultHtmlRenderer
        | heading =
            \{ level, rawText, children } ->
                let
                    id =
                        String.Normalize.slug rawText

                    ( tag, headingClass ) =
                        case level of
                            Block.H1 ->
                                ( Html.h1, "eco-doc-h1" )

                            Block.H2 ->
                                ( Html.h2, "eco-doc-h2" )

                            Block.H3 ->
                                ( Html.h3, "eco-doc-h3" )

                            _ ->
                                ( Html.h4, "eco-doc-h4" )
                in
                tag
                    [ Attrs.id id
                    , Attrs.class headingClass
                    ]
                    children
        , paragraph =
            \children ->
                Html.p
                    [ Attrs.class "eco-doc-paragraph"
                    ]
                    children
        , blockQuote =
            \children ->
                Html.div
                    [ Attrs.class "eco-doc-blockquote"
                    ]
                    children
        , codeSpan =
            \content ->
                Html.code
                    [ Attrs.class "eco-doc-code-inline"
                    ]
                    [ Html.text content ]
        , codeBlock =
            \block ->
                docsSyntaxHighlight block
        , unorderedList =
            \items ->
                Html.ul
                    [ Attrs.class "eco-doc-ul"
                    ]
                    (List.map
                        (\item ->
                            case item of
                                Block.ListItem _ children ->
                                    Html.li
                                        [ Attrs.class "eco-doc-li"
                                        ]
                                        [ Html.span
                                            [ Attrs.class "eco-doc-bullet"
                                            ]
                                            []
                                        , Html.span
                                            [ Attrs.class "eco-doc-bullet-text"
                                            ]
                                            children
                                        ]
                        )
                        items
                    )
        , orderedList =
            \startingIndex items ->
                Html.ol
                    [ Attrs.start startingIndex
                    , Attrs.class "eco-doc-ol"
                    ]
                    (List.map
                        (\itemChildren ->
                            Html.li
                                [ Attrs.class "eco-doc-ol-li"
                                ]
                                itemChildren
                        )
                        items
                    )
        , table =
            \children ->
                Html.table
                    [ Attrs.class "eco-doc-table"
                    ]
                    children
        , tableHeader =
            \children ->
                Html.thead
                    [ Attrs.class "eco-doc-thead"
                    ]
                    children
        , tableBody =
            Html.tbody []
        , tableRow =
            \children ->
                Html.tr
                    [ Attrs.class "eco-doc-tr"
                    ]
                    children
        , tableHeaderCell =
            \_ children ->
                Html.th
                    [ Attrs.class "eco-doc-th"
                    ]
                    children
        , tableCell =
            \_ children ->
                Html.td
                    [ Attrs.class "eco-doc-td"
                    ]
                    children
        , thematicBreak =
            Html.hr
                [ Attrs.class "eco-doc-hr"
                ]
                []
        , strong =
            \children ->
                Html.strong
                    [ Attrs.class "eco-doc-strong"
                    ]
                    children
        , link =
            \link content ->
                Html.a
                    ([ Attrs.href link.destination
                     , Attrs.class "eco-doc-link"
                     ]
                        ++ (case link.title of
                                Just title ->
                                    [ Attrs.title title ]

                                Nothing ->
                                    []
                           )
                    )
                    content
    }


docsBlocksToHtml : List Block.Block -> List (Html msg)
docsBlocksToHtml blocks =
    Markdown.Renderer.render docsRenderer blocks
        |> Result.withDefault [ Html.text "failed to render markdown" ]
