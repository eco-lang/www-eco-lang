module Layout.Roadmap exposing (viewRoadmapPage)

import Content.Roadmap exposing (MilestoneGroup, MilestoneStatus(..))
import Html exposing (Html)
import Html.Attributes as Attrs
import Layout.Markdown exposing (docsSyntaxHighlight)
import Markdown.Block as Block
import Markdown.Renderer exposing (defaultHtmlRenderer)
import Style
import Svg
import Svg.Attributes as SvgAttrs


viewRoadmapPage :
    { title : String, description : String }
    -> List MilestoneGroup
    -> List (Html msg)
viewRoadmapPage meta milestones =
    [ Html.div [ Attrs.class "flex flex-1 relative" ]
        [ viewSidebar milestones
        , Html.div [ Attrs.class "eco-roadmap-timeline" ] []
        , viewContent meta milestones
        ]
    ]



-- SIDEBAR


viewSidebar : List MilestoneGroup -> Html msg
viewSidebar milestones =
    Html.aside
        [ Attrs.class "hidden md:flex flex-col flex-shrink-0 eco-sidebar"
        ]
        [ Html.span
            [ Attrs.class "text-xs font-bold tracking-widest eco-sidebar-title"
            ]
            [ Html.text "ROADMAP" ]
        , Html.div [ Attrs.class "eco-sidebar-spacer" ] []
        , Html.div [ Attrs.class "flex flex-col gap-1" ]
            (List.map viewNavItem milestones)
        ]


viewNavItem : MilestoneGroup -> Html msg
viewNavItem milestone =
    let
        ( dotClass, labelClass ) =
            case milestone.status of
                Released ->
                    ( "eco-roadmap-dot-released", "eco-roadmap-nav-released" )

                Current ->
                    ( "eco-roadmap-dot-current", "eco-roadmap-nav-current" )

                Planned ->
                    ( "eco-roadmap-dot-future", "eco-roadmap-nav-future" )

        label =
            if String.isEmpty milestone.codename then
                milestone.version

            else
                milestone.version ++ " \u{2014} " ++ milestone.codename
    in
    Html.div
        [ Attrs.class ("flex items-center gap-2 " ++ labelClass)
        ]
        [ Html.span [ Attrs.class dotClass ] []
        , Html.text label
        ]



-- CONTENT AREA


viewContent : { title : String, description : String } -> List MilestoneGroup -> Html msg
viewContent meta milestones =
    Html.div
        [ Attrs.class "flex-1 eco-roadmap-content"
        ]
        (viewTitleArea meta
            :: List.concatMap viewMilestone milestones
            ++ [ Html.div [ Attrs.class "h-16" ] [] ]
        )


viewTitleArea : { title : String, description : String } -> Html msg
viewTitleArea meta =
    Html.div
        [ Attrs.class "flex flex-col gap-2 pl-16 mb-12"
        ]
        [ Html.h1
            [ Attrs.class "eco-roadmap-title"
            ]
            [ Html.text meta.title ]
        , Html.p
            [ Attrs.class "eco-roadmap-subtitle"
            ]
            [ Html.text meta.description ]
        , Html.div
            [ Attrs.class "eco-hero-accent-bar mt-2"
            ]
            []
        ]


viewMilestone : MilestoneGroup -> List (Html msg)
viewMilestone milestone =
    [ Html.div [ Attrs.class "h-12" ] []
    , Html.div
        [ Attrs.class "eco-roadmap-milestone relative"
        ]
        [ viewStation milestone.status
        , Html.div
            [ Attrs.class
                (if milestone.status == Planned then
                    "flex flex-col gap-3 eco-roadmap-card-future"

                 else
                    "flex flex-col gap-3"
                )
            ]
            [ viewMilestoneHeader milestone
            , Html.div [] (renderBlocks milestone.blocks)
            ]
        ]
    ]


viewStation : MilestoneStatus -> Html msg
viewStation status =
    case status of
        Released ->
            Html.div
                [ Attrs.class "eco-roadmap-station-wrap"
                ]
                [ Html.div [ Attrs.class "eco-roadmap-station-released" ] []
                ]

        Current ->
            Html.div
                [ Attrs.class "eco-roadmap-station-wrap-current"
                ]
                [ Html.div [ Attrs.class "eco-roadmap-station-current" ] []
                ]

        Planned ->
            Html.div
                [ Attrs.class "eco-roadmap-station-wrap-future"
                ]
                [ Html.div [ Attrs.class "eco-roadmap-station-future" ] []
                ]


viewMilestoneHeader : MilestoneGroup -> Html msg
viewMilestoneHeader milestone =
    let
        badgeClass =
            case milestone.status of
                Released ->
                    "eco-roadmap-badge-released"

                Current ->
                    "eco-roadmap-badge-current"

                Planned ->
                    "eco-roadmap-badge-future"

        statusView =
            case milestone.status of
                Released ->
                    Html.span [ Attrs.class "eco-roadmap-status-released" ]
                        [ Html.text "Released" ]

                Current ->
                    Html.span [ Attrs.class "eco-roadmap-status-current" ]
                        [ Html.text "In Progress" ]

                Planned ->
                    Html.span [ Attrs.class "eco-roadmap-status-planned" ]
                        [ Html.text "Planned" ]
    in
    Html.div
        [ Attrs.class "flex items-center gap-3"
        ]
        [ Html.span [ Attrs.class badgeClass ]
            [ Html.text milestone.version ]
        , Html.span [ Attrs.class "eco-roadmap-milestone-title" ]
            [ Html.text milestone.codename ]
        , statusView
        ]



-- CUSTOM MARKDOWN RENDERER


roadmapRenderer : Markdown.Renderer.Renderer (Html msg)
roadmapRenderer =
    { defaultHtmlRenderer
        | paragraph =
            \children ->
                Html.p
                    [ Attrs.class "eco-roadmap-desc"
                    ]
                    children
        , unorderedList =
            \items ->
                Html.div
                    [ Attrs.class "flex flex-col gap-1.5 pt-2"
                    ]
                    (List.map
                        (\item ->
                            case item of
                                Block.ListItem Block.CompletedTask children ->
                                    Html.div
                                        [ Attrs.class "flex items-baseline gap-2 eco-roadmap-feature"
                                        ]
                                        (Html.text "\u{2022}  " :: children ++ [ checkIcon ])

                                Block.ListItem Block.IncompleteTask children ->
                                    Html.div
                                        [ Attrs.class "flex items-baseline gap-2 eco-roadmap-feature"
                                        ]
                                        (Html.text "\u{2022}  " :: children ++ [ Html.span [ Attrs.style "color" Style.colors.currentBlue, Attrs.style "font-weight" "700" ] [ Html.text " \u{2026}" ] ])

                                Block.ListItem _ children ->
                                    Html.div
                                        [ Attrs.class "eco-roadmap-feature"
                                        ]
                                        (Html.text "\u{2022}  " :: children)
                        )
                        items
                    )
        , codeBlock =
            \block ->
                docsSyntaxHighlight block
        , codeSpan =
            \content ->
                Html.code
                    [ Attrs.class "eco-doc-code-inline"
                    ]
                    [ Html.text content ]
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


checkIcon : Html msg
checkIcon =
    Svg.svg
        [ SvgAttrs.width "14"
        , SvgAttrs.height "14"
        , SvgAttrs.viewBox "0 0 24 24"
        , SvgAttrs.fill "none"
        , SvgAttrs.stroke Style.colors.accent
        , SvgAttrs.strokeWidth "3"
        , SvgAttrs.strokeLinecap "round"
        , SvgAttrs.strokeLinejoin "round"
        , SvgAttrs.style "flex-shrink: 0; position: relative; top: 1px"
        ]
        [ Svg.polyline [ SvgAttrs.points "20 6 9 17 4 12" ] [] ]


renderBlocks : List Block.Block -> List (Html msg)
renderBlocks blocks =
    Markdown.Renderer.render roadmapRenderer blocks
        |> Result.withDefault [ Html.text "failed to render roadmap content" ]
