module Atlas.Draw exposing (Highlight, ground, nodes, links, highlight, bounds, nodeCentre)

{-| The atlas as a diagram on the double grid.

At rest the atlas is `ground`, the stages and foundations, with `nodes` over it, and no dependency lines. For the node
under the mouse or selected, `links` draws its links to its dependencies and dependees, between the ground and the
nodes, and `highlight` lights up those nodes over everything, or the search matches when nothing is in focus. Nothing in the base changes while the highlight does, so moving the mouse over the graph only redraws
the few things that light up.

@docs Highlight, ground, nodes, links, highlight, bounds, nodeCentre

-}

import Array
import Atlas.Graph exposing (Graph, Node, Stage)
import BoundingBox2d exposing (BoundingBox2d)
import Diagram exposing (Anchor(..), Element)
import Diagram.Font as Font
import Diagram.Grid as Grid exposing (Cells, Grid, WorldCoordinates)
import Diagram.Paint as Paint exposing (Paint)
import Diagram.Text as Text
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Set exposing (Set)



-- STYLES


colors :
    { text : String
    , muted : String
    , accent : String
    , accentDark : String
    , blue : String
    , red : String
    }
colors =
    { text = "#242424"
    , muted = "#5E5E5E"
    , accent = "#4CAF50"
    , accentDark = "#2E7D32"
    , blue = "#1F6FB2"
    , red = "#C95200"
    }


title : Text.Style
title =
    { font = Font.montserrat 700, color = colors.text, units = 3, spacing = 1.5 }


blurb : Text.Style
blurb =
    { font = Font.inter 400, color = "#555555", units = 2, spacing = 2 }


meta : Text.Style
meta =
    { font = Font.robotoMono 500, color = colors.muted, units = 1, spacing = 1.333 }


section : Text.Style
section =
    { meta | font = Font.robotoMono 700, color = colors.text }


branchLabel : Text.Style
branchLabel =
    { font = Font.inter 600, color = colors.accentDark, units = 1, spacing = 1.333 }


label : Text.Style
label =
    { font = Font.robotoMono 500, color = colors.text, units = 1, spacing = 1.45 }


stageNotes : String -> String
stageNotes key =
    case key of
        "local" ->
            "The erased and typed paths split after this stage"

        "genmlir" ->
            "Hands eco-dialect MLIR bytecode to the C++ back end"

        "backend" ->
            "Runs in the same process, called through a kernel"

        _ ->
            ""


bandPaint : String -> Bool -> Paint
bandPaint lang alt =
    Paint.filledAndOutlined
        (case ( lang, alt ) of
            ( "cpp", True ) ->
                "#EAF0F7"

            ( "cpp", False ) ->
                "#F4F7FB"

            ( _, True ) ->
                "#F3F8F3"

            _ ->
                "#FFFFFF"
        )
        (Paint.hairline "#E0E0E0" 1)


{-| A node's paint, warmed towards amber as far as it glows from a commit touching it.
-}
nodePaint : String -> Float -> Paint
nodePaint lang glow =
    let
        ( fill, line ) =
            if lang == "cpp" then
                ( ( 0xF2, 0xF6, 0xFB ), ( 0xB8, 0xC6, 0xD8 ) )

            else
                ( ( 0xFF, 0xFF, 0xFF ), ( 0xCF, 0xCF, 0xCF ) )
    in
    Paint.filledAndOutlined (mix glow fill ( 0xFF, 0xE8, 0xA3 )) (Paint.hairline (mix glow line ( 0xE0, 0x9A, 0x00 )) (1 + glow))


{-| A colour part way from one to another, as `#rrggbb`.
-}
mix : Float -> ( Int, Int, Int ) -> ( Int, Int, Int ) -> String
mix p ( r1, g1, b1 ) ( r2, g2, b2 ) =
    let
        channel a b =
            let
                v =
                    round (toFloat a + (toFloat b - toFloat a) * p)
            in
            String.fromList [ hexDigit (v // 16), hexDigit (modBy 16 v) ]
    in
    "#" ++ channel r1 r2 ++ channel g1 g2 ++ channel b1 b2


hexDigit : Int -> Char
hexDigit d =
    String.uncons (String.slice d (d + 1) "0123456789ABCDEF") |> Maybe.map Tuple.first |> Maybe.withDefault '0'



-- GEOMETRY


{-| The world: every cell of the grid the atlas uses.
-}
bounds : Grid -> Graph -> BoundingBox2d Pixels WorldCoordinates
bounds grid graph =
    Grid.footprint grid { col = 0, row = 0, cols = max 1 graph.world.cols, rows = max 1 graph.world.rows }


cells : Graph -> Node -> Cells
cells graph n =
    { col = n.gx, row = n.gy, cols = toFloat graph.world.nodeW, rows = toFloat graph.world.nodeH }


stageCells : Stage -> Cells
stageCells s =
    { col = s.gx, row = s.gy, cols = s.gw, rows = s.gh }


{-| The middle of a node's text row, to centre the view on.
-}
nodeCentre : Grid -> Graph -> Node -> Point2d Pixels WorldCoordinates
nodeCentre grid graph n =
    Grid.point grid (n.gx + toFloat graph.world.nodeW / 2) (n.gy + 1.5)


{-| Elements faded together, unless they are fully there.
-}
fade : Float -> List (Element WorldCoordinates) -> List (Element WorldCoordinates)
fade opacity elements =
    if opacity >= 1 then
        elements

    else
        [ Diagram.faded opacity elements ]


{-| A chevron arrow pointing right, its tip `x` pixels right of the point and its shaft starting at the point, in the
shape of the arrow icon the rest of the site uses.
-}
chevron : Float -> Float -> List (Element WorldCoordinates)
chevron x y =
    let
        stroke =
            Paint.scaled colors.accent 2.5
    in
    [ Diagram.line stroke [ Point2d.pixels x y, Point2d.pixels (x + 13) y ]
    , Diagram.line stroke [ Point2d.pixels (x + 8) (y - 6), Point2d.pixels (x + 14) y, Point2d.pixels (x + 8) (y + 6) ]
    ]



-- AT REST


{-| The page, the stages, the branch and the foundations.
-}
ground : Grid -> Graph -> List (Element WorldCoordinates)
ground grid graph =
    List.concat
        [ [ Diagram.box (Paint.filled "#F8F8F8") 0 (bounds grid graph) ]
        , List.indexedMap (stageBand grid graph) graph.stages |> List.concat
        , branch grid graph
        , foundations grid graph
        ]


{-| Every node there, at rest.
-}
nodes : Grid -> Graph -> List (Element WorldCoordinates)
nodes grid graph =
    Array.toList graph.nodes |> List.filter (\n -> n.opacity > 0) |> List.map (nodeElement grid graph Plain)


{-| A stage: its frame, title, blurb, count and note in the header rows, and an arrow to the next stage in its row.
Header rows: title in rows 1-4, blurb 4-6, count 6-7, note 7-8.
-}
stageBand : Grid -> Graph -> Int -> Stage -> List (Element WorldCoordinates)
stageBand grid graph i s =
    let
        col =
            s.gx + 2

        next =
            List.drop (i + 1) graph.stages |> List.head

        hasArrow =
            Maybe.map .row next == Just s.row

        langName =
            if s.lang == "elm" then
                "Elm · " ++ String.fromInt s.count ++ " modules"

            else
                "C++ · " ++ String.fromInt s.count ++ " components"
    in
    fade s.opacity
        ([ Diagram.box (bandPaint s.lang (modBy 2 s.order == 1)) 3 (Grid.frame grid (stageCells s))
         , Text.onGrid grid title Start { col = col, row = s.gy + 4 } s.title
         , Text.onGrid grid blurb Start { col = col, row = s.gy + 6 } s.blurb
         , Text.onGrid grid meta Start { col = col, row = s.gy + 7 } langName
         ]
            ++ (if stageNotes s.key == "" then
                    []

                else
                    [ Text.onGrid grid meta Start { col = col, row = s.gy + 8 } (stageNotes s.key) ]
               )
            ++ (if hasArrow then
                    chevron (Grid.rhythm grid (s.gx + s.gw + 1) - 7) (Grid.rhythm grid (s.gy + 2.5))

                else
                    []
               )
        )


{-| The typed path leaving the shared pipeline after Local optimize: down the gap after that stage to the typed row's
title line, then right into Monomorphize.
-}
branch : Grid -> Graph -> List (Element WorldCoordinates)
branch grid graph =
    case
        ( List.filter (\s -> s.key == graph.world.branchFrom) graph.stages |> List.head
        , List.filter (\s -> s.key == graph.world.branchTo) graph.stages |> List.head
        )
    of
        ( Just from, Just to ) ->
            let
                gapX =
                    Grid.rhythm grid (from.gx + from.gw + 1)

                tailX =
                    gapX - 7

                y1 =
                    Grid.rhythm grid (from.gy + 2.5) + 14

                y2 =
                    Grid.rhythm grid (to.gy + 2.5)
            in
            fade (min from.opacity to.opacity) <|
                Diagram.line (Paint.scaled colors.accent 2.5) [ Point2d.pixels tailX y1, Point2d.pixels tailX y2 ]
                    :: chevron tailX y2
                    ++ [ Diagram.text
                            { baseline =
                                Point2d.pixels (tailX + 6)
                                    (Grid.rhythm grid (from.gy + from.gh + 1) - Text.lift grid branchLabel)
                            , anchor = Start
                            , content = "typed path"
                            , font = branchLabel.font
                            , size = Text.size grid branchLabel
                            , color = branchLabel.color
                            }
                       ]

        _ ->
            []


{-| The two foundations side by side under the pipeline: the Elm one under the Elm stages and the C++ one, with its two
sections, under the C++ stages.
-}
foundations : Grid -> Graph -> List (Element WorldCoordinates)
foundations grid graph =
    let
        w =
            graph.world

        ft =
            w.foundTop

        header col heading text =
            [ Text.onGrid grid title Start { col = col + 2, row = ft + 4 } heading
            , Text.onGrid grid blurb Start { col = col + 2, row = ft + 6 } text
            ]

        elm =
            if w.foundCols > 0 then
                fade w.foundOpacity
                    (Diagram.box (Paint.filledAndOutlined "#EEEEE8" (Paint.hairline "#DADAD2" 1))
                        3
                        (Grid.frame grid { col = 0, row = ft, cols = w.foundCols, rows = w.foundRows })
                        :: header 0
                            "Shared foundation"
                            "ASTs, data structures, error reporting and utilities that every Elm stage leans on. Each module sits under the stages that use it most."
                    )

            else
                []

        cpp =
            if w.cppFoundCols > 0 then
                fade w.cppFoundOpacity
                    (Diagram.box (Paint.filledAndOutlined "#E8EDF3" (Paint.hairline "#D0D9E4" 1))
                        3
                        (Grid.frame grid { col = w.cppFoundCol, row = ft, cols = w.cppFoundCols, rows = w.foundRows })
                        :: header w.cppFoundCol
                            "C++ foundation"
                            "The heap value model every C++ stage reads and writes, and the C ABI that generated code, kernels and the runtime share."
                        ++ List.map (\c -> Text.onGrid grid section Start { col = c.gx + 1, row = ft + 8 } c.title) w.cppSections
                    )

            else
                []
    in
    elm ++ cpp



-- NODES


type Look
    = Plain
    | Focus
    | Dependency
    | Dependee
    | Match


nodeElement : Grid -> Graph -> Look -> Node -> Element WorldCoordinates
nodeElement grid graph look n =
    let
        c =
            cells graph n

        ( paint, style ) =
            case look of
                Plain ->
                    ( nodePaint n.lang n.glow, label )

                Focus ->
                    ( Paint.filledAndOutlined "#E8F5E9" (Paint.hairline colors.accentDark 2)
                    , { label | font = Font.robotoMono 700 }
                    )

                Dependency ->
                    ( Paint.filledAndOutlined "#E6EFF8" (Paint.hairline colors.blue 1), label )

                Dependee ->
                    ( Paint.filledAndOutlined "#FCEDE2" (Paint.hairline colors.red 1), label )

                Match ->
                    ( Paint.filledAndOutlined "#E8F5E9" (Paint.hairline colors.accentDark 2), label )
    in
    Diagram.group { key = Just n.id, data = [ ( "stage", n.stage ), ( "path", n.path ) ], opacity = n.opacity }
        [ Diagram.box paint 2 (Grid.frame grid c)
        , Text.inFrame grid style c 2 n.label
        ]



-- HIGHLIGHT


{-| What lights up: the node in focus, if any, and the indexes of the nodes matching a search.
-}
type alias Highlight =
    { focus : Maybe Int
    , matches : Set Int
    }


{-| The links of the node in focus: to its dependencies in blue and from its dependees in red. They run under the
nodes, so they never cross a label.
-}
links : Grid -> Graph -> Maybe Int -> List (Element WorldCoordinates)
links grid graph focus =
    case focus |> Maybe.andThen (Atlas.Graph.node graph) of
        Just f ->
            List.map (\d -> link grid graph colors.blue f d) (neighbours graph graph.out f)
                ++ List.map (\u -> link grid graph colors.red u f) (neighbours graph graph.inn f)

        Nothing ->
            []


{-| The nodes that light up, drawn over the base: the dependencies and dependees of the node in focus, then the focus
itself. Search matches light up when nothing is in focus.
-}
highlight : Grid -> Graph -> Highlight -> List (Element WorldCoordinates)
highlight grid graph hl =
    case hl.focus |> Maybe.andThen (Atlas.Graph.node graph) of
        Just f ->
            List.map (nodeElement grid graph Dependency) (neighbours graph graph.out f)
                ++ List.map (nodeElement grid graph Dependee) (neighbours graph graph.inn f)
                ++ [ nodeElement grid graph Focus f ]

        Nothing ->
            Set.toList hl.matches
                |> List.filterMap (Atlas.Graph.node graph)
                |> List.map (nodeElement grid graph Match)


neighbours : Graph -> Array.Array (List Int) -> Node -> List Node
neighbours graph adjacency n =
    Array.get n.index adjacency |> Maybe.withDefault [] |> List.filterMap (Atlas.Graph.node graph)


{-| A link from an importing node to the node it imports. Side by side, it runs between their facing sides, level with
their text; one above the other, between the middles of their facing edges.
-}
link : Grid -> Graph -> String -> Node -> Node -> Element WorldCoordinates
link grid graph color a b =
    let
        ca =
            cells graph a

        cb =
            cells graph b

        ( p1, p2 ) =
            if abs (b.gx - a.gx) >= toFloat graph.world.nodeW then
                if b.gx > a.gx then
                    ( Grid.rightAnchor grid ca 1, Grid.leftAnchor grid cb 1 )

                else
                    ( Grid.leftAnchor grid ca 1, Grid.rightAnchor grid cb 1 )

            else if b.gy > a.gy then
                ( Grid.bottomAnchor grid ca, Grid.topAnchor grid cb )

            else
                ( Grid.topAnchor grid ca, Grid.bottomAnchor grid cb )
    in
    Diagram.line (Paint.hairline color 2) [ p1, p2 ]
