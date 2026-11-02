module Route.Atlas exposing (ActionData, Data, Model, Msg, RouteParams, route)

{-| The compiler atlas: every Elm module and C++ component of the compiler, laid out along the pipeline on the double
grid, with pan and zoom.

The diagram is drawn by the `Diagram` engine. While the view moves, the drawing already on the screen is moved and
scaled with a transform, which is cheap. Once it settles, the diagram is projected again for the new view, onto device
pixels, so that it is sharp at every zoom. The base drawing and the highlight are drawn lazily, from the settled view,
so moving the mouse over the graph only redraws the highlight.

-}

import Array
import Atlas.Draw as Draw
import Atlas.Graph as Graph exposing (Graph, Node)
import BackendTask exposing (BackendTask)
import Browser.Dom
import Browser.Events
import Diagram
import Diagram.Camera as Camera exposing (Camera)
import Diagram.Grid as Grid exposing (Grid)
import Diagram.Paint as Paint
import Diagram.Svg
import Diagram.Svg11
import Dict
import Effect exposing (Effect)
import FatalError exposing (FatalError)
import File.Download
import Head
import Head.Seo as Seo
import Html exposing (Html)
import Html.Attributes as Attrs
import Html.Events as Events
import Json.Decode as Decode
import Layout.Site
import MimeType
import Pages.Url
import PagesMsg exposing (PagesMsg)
import Point2d
import Process
import RouteBuilder exposing (App, StatefulRoute)
import Set
import Settings
import Shared
import Svg exposing (Svg)
import Svg.Attributes as SvgAttrs
import Svg.Events
import Svg.Lazy
import Task
import UrlPath exposing (UrlPath)
import View exposing (View)


type alias RouteParams =
    {}


type alias Data =
    Graph


type alias ActionData =
    {}


route : StatefulRoute RouteParams Data ActionData Model Msg
route =
    RouteBuilder.single
        { head = head
        , data = Graph.data
        }
        |> RouteBuilder.buildWithLocalState
            { view = view
            , init = init
            , update = update
            , subscriptions = subscriptions
            }


head : App Data ActionData RouteParams -> List Head.Tag
head _ =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = Settings.title
        , image =
            { url = [ "images", "site-card.png" ] |> UrlPath.join |> Pages.Url.fromPath
            , alt = "eco compiler atlas"
            , dimensions = Just { width = 1200, height = 630 }
            , mimeType = Just (MimeType.Image MimeType.Png)
            }
        , description = "Every module of the eco compiler, laid out along its pipeline, with the dependencies between them."
        , locale = Settings.locale
        , title = "Compiler atlas"
        }
        |> Seo.website


{-| The grid the atlas is drawn on.
-}
grid : Grid
grid =
    Grid.default


rulerHeight : Float
rulerHeight =
    48



-- MODEL


{-| `view` is where the camera is now and `settled` the view the drawing was last made for. `screen` is the viewport's
place on the page and its size, once known.
-}
type alias Model =
    { view : Camera
    , settled : Camera
    , screen : Maybe Screen
    , fitted : Bool
    , drag : Maybe Drag
    , suppressClick : Bool
    , hover : Maybe Int
    , selected : Maybe Int
    , query : String
    , showGrid : Bool
    , wheelCount : Int
    }


type alias Screen =
    { x : Float
    , y : Float
    , width : Float
    , height : Float
    }


type alias Drag =
    { startX : Float
    , startY : Float
    , origin : Camera
    , moved : Bool
    }


type Msg
    = GotScreen (Result Browser.Dom.Error Browser.Dom.Element)
    | Resized
    | Wheel { deltaY : Float, ctrl : Bool, clientX : Float, clientY : Float }
    | Settle Int
    | DragStart Float Float
    | DragMove Float Float
    | DragEnd
    | Hover Int
    | Unhover Int
    | Pick Int
    | BackgroundClick
    | Query String
    | SearchKey String
    | ToggleGrid
    | ZoomIn
    | ZoomOut
    | FitAll
    | FocusOn Int
    | ClearSelection
    | Export


init : App Data ActionData RouteParams -> Shared.Model -> ( Model, Effect Msg )
init _ shared =
    let
        camera =
            { x = 24, y = 24, scale = 0.15, pixelRatio = shared.pixelRatio }
    in
    ( { view = camera
      , settled = camera
      , screen = Nothing
      , fitted = False
      , drag = Nothing
      , suppressClick = False
      , hover = Nothing
      , selected = Nothing
      , query = ""
      , showGrid = False
      , wheelCount = 0
      }
    , measure
    )


measure : Effect Msg
measure =
    Browser.Dom.getElement "atlas-viewport"
        |> Task.attempt GotScreen
        |> Effect.fromCmd



-- UPDATE


update : App Data ActionData RouteParams -> Shared.Model -> Msg -> Model -> ( Model, Effect Msg )
update app _ msg model =
    let
        graph =
            app.data
    in
    case msg of
        GotScreen (Ok { element }) ->
            let
                screen =
                    { x = element.x, y = element.y, width = element.width, height = element.height }

                measured =
                    { model | screen = Just screen }
            in
            if model.fitted then
                ( measured, Effect.none )

            else
                ( fit graph screen measured, Effect.none )

        GotScreen (Err _) ->
            ( model, Effect.none )

        Resized ->
            ( model, measure )

        Wheel w ->
            case model.screen of
                Just screen ->
                    let
                        factor =
                            e
                                ^ (-w.deltaY
                                    * (if w.ctrl then
                                        0.01

                                       else
                                        0.0015
                                      )
                                  )

                        count =
                            model.wheelCount + 1
                    in
                    ( { model
                        | view = zoom factor { x = w.clientX - screen.x, y = w.clientY - screen.y } model.view
                        , wheelCount = count
                      }
                    , Process.sleep 140 |> Task.perform (\_ -> Settle count) |> Effect.fromCmd
                    )

                Nothing ->
                    ( model, Effect.none )

        Settle count ->
            if count == model.wheelCount then
                ( settle model, Effect.none )

            else
                ( model, Effect.none )

        DragStart x y ->
            ( { model | drag = Just { startX = x, startY = y, origin = model.view, moved = False }, suppressClick = False }
            , Effect.none
            )

        DragMove x y ->
            case model.drag of
                Just drag ->
                    let
                        dx =
                            x - drag.startX

                        dy =
                            y - drag.startY

                        moved =
                            drag.moved || abs dx + abs dy > 4
                    in
                    if moved then
                        ( { model
                            | drag = Just { drag | moved = True }
                            , view = Camera.panBy dx dy drag.origin
                          }
                        , Effect.none
                        )

                    else
                        ( model, Effect.none )

                Nothing ->
                    ( model, Effect.none )

        DragEnd ->
            case model.drag of
                Just drag ->
                    if drag.moved then
                        ( settle { model | drag = Nothing, suppressClick = True }, Effect.none )

                    else
                        ( { model | drag = Nothing }, Effect.none )

                Nothing ->
                    ( model, Effect.none )

        Hover i ->
            if model.drag == Nothing && model.hover /= Just i then
                ( { model | hover = Just i }, Effect.none )

            else
                ( model, Effect.none )

        Unhover i ->
            if model.hover == Just i then
                ( { model | hover = Nothing }, Effect.none )

            else
                ( model, Effect.none )

        Pick i ->
            if model.suppressClick then
                ( { model | suppressClick = False }, Effect.none )

            else if model.selected == Just i then
                ( { model | selected = Nothing, hover = Nothing }, Effect.none )

            else
                ( { model | selected = Just i, hover = Nothing }, Effect.none )

        BackgroundClick ->
            if model.suppressClick then
                ( { model | suppressClick = False }, Effect.none )

            else
                ( { model | selected = Nothing }, Effect.none )

        Query q ->
            ( { model | query = q, selected = Nothing }, Effect.none )

        SearchKey "Escape" ->
            ( { model | query = "" }, Effect.none )

        SearchKey "Enter" ->
            case Graph.matches graph model.query of
                first :: _ ->
                    ( focusOn graph first model, Effect.none )

                [] ->
                    ( model, Effect.none )

        SearchKey _ ->
            ( model, Effect.none )

        ToggleGrid ->
            ( { model | showGrid = not model.showGrid }, Effect.none )

        ZoomIn ->
            ( settle (zoomCentre 1.4 model), Effect.none )

        ZoomOut ->
            ( settle (zoomCentre (1 / 1.4) model), Effect.none )

        FitAll ->
            case model.screen of
                Just screen ->
                    ( fit graph screen model, Effect.none )

                Nothing ->
                    ( model, Effect.none )

        FocusOn i ->
            case Graph.node graph i of
                Just n ->
                    ( focusOn graph n model, Effect.none )

                Nothing ->
                    ( model, Effect.none )

        ClearSelection ->
            ( { model | selected = Nothing }, Effect.none )

        Export ->
            ( model
            , File.Download.string "eco-compiler-atlas.svg" "image/svg+xml" (exportSvg graph (highlightOf graph model))
                |> Effect.fromCmd
            )


settle : Model -> Model
settle model =
    { model | settled = model.view }


zoom : Float -> { x : Float, y : Float } -> Camera -> Camera
zoom factor at camera =
    let
        clamped =
            clamp 0.03 4 (camera.scale * factor) / camera.scale
    in
    Camera.zoomAbout clamped at camera


zoomCentre : Float -> Model -> Model
zoomCentre factor model =
    case model.screen of
        Just screen ->
            { model | view = zoom factor { x = screen.width / 2, y = screen.height / 2 } model.view }

        Nothing ->
            model


fit : Graph -> Screen -> Model -> Model
fit graph screen model =
    let
        camera =
            Camera.fit
                { width = screen.width, height = screen.height, margin = 20, pixelRatio = model.view.pixelRatio }
                (Draw.bounds grid graph)
    in
    { model | view = camera, settled = camera, fitted = True }


{-| Centre the view on a node, close enough to read it, leaving room for the panel, and select it.
-}
focusOn : Graph -> Node -> Model -> Model
focusOn graph n model =
    case model.screen of
        Just screen ->
            let
                c =
                    Point2d.toPixels (Draw.nodeCentre grid graph n)

                k =
                    max model.view.scale 0.85

                panel =
                    if screen.width > 760 then
                        360

                    else
                        0

                camera =
                    { x = (screen.width - panel) / 2 - c.x * k
                    , y = screen.height / 2 - c.y * k
                    , scale = k
                    , pixelRatio = model.view.pixelRatio
                    }
            in
            { model | view = camera, settled = camera, selected = Just n.index, hover = Nothing }

        Nothing ->
            { model | selected = Just n.index, hover = Nothing }


highlightOf : Graph -> Model -> Draw.Highlight
highlightOf graph model =
    { focus = focusOf model
    , matches = Graph.matches graph model.query |> List.map .index |> Set.fromList
    }


focusOf : Model -> Maybe Int
focusOf model =
    case model.selected of
        Just _ ->
            model.selected

        Nothing ->
            model.hover


{-| The atlas as an SVG 1.1 file, at its own size, with whatever is highlighted now.
-}
exportSvg : Graph -> Draw.Highlight -> String
exportSvg graph hl =
    Diagram.diagram (Draw.bounds grid graph)
        (Draw.ground grid graph ++ Draw.links grid graph hl.focus ++ Draw.nodes grid graph ++ Draw.highlight grid graph hl)
        |> Camera.project Camera.identity
        |> Diagram.Svg11.document
            { title = "eco compiler atlas"
            , description = "Every module of the eco compiler, laid out along its pipeline."
            }



-- SUBSCRIPTIONS


subscriptions : RouteParams -> UrlPath -> Shared.Model -> Model -> Sub Msg
subscriptions _ _ _ model =
    Sub.batch
        [ Browser.Events.onResize (\_ _ -> Resized)
        , case model.drag of
            Just _ ->
                Sub.batch
                    [ Browser.Events.onMouseMove (Decode.map2 DragMove (Decode.field "clientX" Decode.float) (Decode.field "clientY" Decode.float))
                    , Browser.Events.onMouseUp (Decode.succeed DragEnd)
                    ]

            Nothing ->
                Sub.none
        ]



-- VIEW


view : App Data ActionData RouteParams -> Shared.Model -> Model -> View (PagesMsg Msg)
view app _ model =
    { title = "Compiler atlas"
    , body =
        [ Html.div [ Attrs.class "eco-atlas" ]
            [ Layout.Site.viewHeader { active = Nothing, path = "/atlas", contents = [] }
            , Html.map PagesMsg.fromMsg (viewAtlas app.data model)
            ]
        ]
    }


viewAtlas : Graph -> Model -> Html Msg
viewAtlas graph model =
    let
        matchCount =
            List.length (Graph.matches graph model.query)
    in
    Html.div [ Attrs.class "eco-atlas-main" ]
        [ viewBar graph model matchCount
        , Html.div [ Attrs.class "eco-atlas-stage" ]
            ([ viewRuler graph model.view
             , viewViewport graph model
             , viewLegend model.showGrid
             , viewZoom model.view
             ]
                ++ viewPanel graph model
            )
        ]


viewBar : Graph -> Model -> Int -> Html Msg
viewBar graph model matchCount =
    Html.div [ Attrs.class "eco-atlas-bar" ]
        [ Html.h1 [ Attrs.class "eco-atlas-title" ] [ Html.text "Compiler atlas" ]
        , Html.label [ Attrs.class "eco-atlas-search" ]
            [ icon "M11 4a7 7 0 1 0 0 14a7 7 0 1 0 0-14zM20 20l-4-4"
            , Html.span [ Attrs.class "eco-sr-only" ] [ Html.text "Find a module" ]
            , Html.input
                [ Attrs.type_ "search"
                , Attrs.class "eco-atlas-search-input"
                , Attrs.placeholder "Find a module, e.g. Specialize"
                , Attrs.value model.query
                , Events.onInput Query
                , Events.on "keydown" (Decode.map SearchKey (Decode.field "key" Decode.string))
                ]
                []
            ]
        , Html.button
            [ Attrs.type_ "button"
            , Attrs.class
                (if model.showGrid then
                    "eco-atlas-toggle-on"

                 else
                    "eco-atlas-toggle"
                )
            , Attrs.attribute "aria-pressed"
                (if model.showGrid then
                    "true"

                 else
                    "false"
                )
            , Events.onClick ToggleGrid
            ]
            [ icon "M4 4h16v16H4zM4 10h16M4 16h16M10 4v16M16 4v16", Html.text "Show grids" ]
        , Html.button
            [ Attrs.type_ "button"
            , Attrs.class "eco-atlas-toggle"
            , Attrs.title "Download the atlas as an SVG 1.1 file, for Inkscape or Illustrator"
            , Events.onClick Export
            ]
            [ icon "M12 4v11M7 10l5 5 5-5M5 20h14", Html.text "Export SVG" ]
        , Html.span [ Attrs.class "eco-atlas-note" ]
            [ Html.text
                (if String.trim model.query == "" then
                    ""

                 else if matchCount == 1 then
                    "1 match · Enter to jump"

                 else
                    String.fromInt matchCount ++ " matches · Enter to jump"
                )
            ]
        , Html.span [ Attrs.class "eco-atlas-summary" ]
            [ Html.text
                (String.fromInt (Array.length graph.nodes)
                    ++ " modules and files · "
                    ++ thousands graph.edgeCount
                    ++ " dependencies"
                )
            ]
        ]


{-| The stage names along the top, following the view as it moves. The shared stages take both tiers; after the
branch, the erased stages take the top tier and the typed stages the bottom one.
-}
viewRuler : Graph -> Camera -> Html Msg
viewRuler graph camera =
    let
        branchIndex =
            graph.stages
                |> List.indexedMap Tuple.pair
                |> List.filter (\( _, s ) -> s.key == graph.world.branchFrom)
                |> List.head
                |> Maybe.map Tuple.first
                |> Maybe.withDefault 0

        half =
            rulerHeight / 2
    in
    Html.div [ Attrs.class "eco-atlas-ruler" ]
        (List.indexedMap
            (\i s ->
                let
                    shared =
                        i <= branchIndex
                in
                Html.div
                    [ Attrs.class
                        (if s.lang == "cpp" then
                            "eco-atlas-tab-cpp"

                         else
                            "eco-atlas-tab"
                        )
                    , Attrs.style "left" (px (camera.x + Grid.rhythm grid (toFloat s.gx) * camera.scale))
                    , Attrs.style "width" (px (Grid.rhythm grid (toFloat s.gw) * camera.scale))
                    , Attrs.style "top"
                        (px
                            (if shared || s.row == 0 then
                                0

                             else
                                half
                            )
                        )
                    , Attrs.style "height"
                        (px
                            (if shared then
                                rulerHeight

                             else
                                half
                            )
                        )
                    ]
                    [ Html.span [] [ Html.text s.title ] ]
            )
            graph.stages
        )


viewViewport : Graph -> Model -> Html Msg
viewViewport graph model =
    let
        moving =
            Camera.relative { from = model.settled, to = model.view }

        transform =
            if model.view == model.settled then
                []

            else
                [ SvgAttrs.transform
                    ("translate("
                        ++ String.fromFloat moving.dx
                        ++ " "
                        ++ String.fromFloat moving.dy
                        ++ ") scale("
                        ++ String.fromFloat moving.scale
                        ++ ")"
                    )
                ]
    in
    Html.div
        [ Attrs.id "atlas-viewport"
        , Attrs.class
            (if model.drag /= Nothing then
                "eco-atlas-viewport-dragging"

             else
                "eco-atlas-viewport"
            )
        , Events.on "mousedown"
            (Decode.field "button" Decode.int
                |> Decode.andThen
                    (\b ->
                        if b == 0 then
                            Decode.map2 DragStart (Decode.field "clientX" Decode.float) (Decode.field "clientY" Decode.float)

                        else
                            Decode.fail "not the main button"
                    )
            )
        , Events.preventDefaultOn "wheel"
            (Decode.map4 (\dy mode ctrl ( cx, cy ) -> ( Wheel { deltaY = dy * modeScale mode, ctrl = ctrl, clientX = cx, clientY = cy }, True ))
                (Decode.field "deltaY" Decode.float)
                (Decode.field "deltaMode" Decode.int)
                (Decode.field "ctrlKey" Decode.bool)
                (Decode.map2 Tuple.pair (Decode.field "clientX" Decode.float) (Decode.field "clientY" Decode.float))
            )
        , Events.onClick BackgroundClick
        ]
        [ Svg.svg [ SvgAttrs.class "eco-atlas-svg" ]
            [ Svg.g transform
                [ Svg.Lazy.lazy2 groundLayer model.settled graph
                , Svg.Lazy.lazy3 linksLayer model.settled graph (focusOf model)
                , Svg.Lazy.lazy2 nodesLayer model.settled graph
                , if model.showGrid then
                    Svg.Lazy.lazy2 gridLayer model.settled model.screen

                  else
                    Svg.text ""
                , Svg.Lazy.lazy4 highlightLayer model.settled graph (focusOf model) model.query
                ]
            ]
        ]


modeScale : Int -> Float
modeScale mode =
    case mode of
        1 ->
            16

        2 ->
            400

        _ ->
            1


groundLayer : Camera -> Graph -> Svg Msg
groundLayer camera graph =
    Draw.ground grid graph
        |> Diagram.diagram (Draw.bounds grid graph)
        |> Camera.project camera
        |> .elements
        |> Diagram.Svg.elements Diagram.Svg.config
        |> Svg.g []


linksLayer : Camera -> Graph -> Maybe Int -> Svg Msg
linksLayer camera graph focus =
    Draw.links grid graph focus
        |> Diagram.diagram (Draw.bounds grid graph)
        |> Camera.project camera
        |> .elements
        |> Diagram.Svg.elements Diagram.Svg.config
        |> Svg.g [ SvgAttrs.pointerEvents "none" ]


nodesLayer : Camera -> Graph -> Svg Msg
nodesLayer camera graph =
    let
        events key =
            case Dict.get key graph.index of
                Just i ->
                    [ Svg.Events.on "mouseenter" (Decode.succeed (Hover i))
                    , Svg.Events.on "mouseleave" (Decode.succeed (Unhover i))
                    , Svg.Events.stopPropagationOn "click" (Decode.succeed ( Pick i, True ))
                    , SvgAttrs.class "eco-atlas-node"
                    ]

                Nothing ->
                    []
    in
    Diagram.diagram (Draw.bounds grid graph) (Draw.nodes grid graph)
        |> Camera.project camera
        |> .elements
        |> Diagram.Svg.elements { attributes = [], group = events }
        |> Svg.g []


highlightLayer : Camera -> Graph -> Maybe Int -> String -> Svg Msg
highlightLayer camera graph focus query =
    Draw.highlight grid graph { focus = focus, matches = Graph.matches graph query |> List.map .index |> Set.fromList }
        |> Diagram.diagram (Draw.bounds grid graph)
        |> Camera.project camera
        |> .elements
        |> Diagram.Svg.elements Diagram.Svg.config
        |> Svg.g [ SvgAttrs.pointerEvents "none" ]


{-| Both grids over what is in view: the text grid in red and the frame grid in blue.
-}
gridLayer : Camera -> Maybe Screen -> Svg Msg
gridLayer camera screen =
    case screen of
        Just s ->
            Grid.guides
                { grid = grid
                , region = Camera.visibleRegion camera { width = s.width, height = s.height }
                , scale = camera.scale
                , minGap = 4
                , text = Paint.hairline "#D64541" 1 |> (\st -> { st | opacity = 0.35 })
                , frames = Paint.hairline "#1F6FB2" 1 |> (\st -> { st | opacity = 0.35 })
                }
                |> Diagram.diagram (Camera.visibleRegion camera { width = s.width, height = s.height })
                |> Camera.project camera
                |> .elements
                |> Diagram.Svg.elements Diagram.Svg.config
                |> Svg.g [ SvgAttrs.pointerEvents "none" ]

        Nothing ->
            Svg.text ""


viewLegend : Bool -> Html Msg
viewLegend showGrid =
    let
        item swatch text =
            Html.span [ Attrs.class "eco-atlas-legend-item" ] [ Html.span [ Attrs.class swatch ] [], Html.text text ]
    in
    Html.div [ Attrs.class "eco-atlas-legend" ]
        ([ Html.div [ Attrs.class "eco-atlas-legend-row" ]
            [ item "eco-atlas-swatch" "Elm module", item "eco-atlas-swatch-cpp" "C++ component" ]
         , Html.div [ Attrs.class "eco-atlas-legend-row" ]
            [ item "eco-atlas-line-blue" "depends on", item "eco-atlas-line-red" "used by" ]
         ]
            ++ (if showGrid then
                    [ Html.div [ Attrs.class "eco-atlas-legend-row" ]
                        [ item "eco-atlas-line-grid-text" "text grid", item "eco-atlas-line-grid-frame" "frame grid" ]
                    ]

                else
                    []
               )
            ++ [ Html.div [ Attrs.class "eco-atlas-legend-hint" ]
                    [ Html.text "Drag to pan, scroll to zoom, hover over a module to trace its links, click to keep them." ]
               ]
        )


viewZoom : Camera -> Html Msg
viewZoom camera =
    Html.div [ Attrs.class "eco-atlas-zoom" ]
        [ Html.button [ Attrs.type_ "button", Attrs.class "eco-atlas-ctl", Attrs.attribute "aria-label" "Zoom in", Events.onClick ZoomIn ]
            [ icon "M12 5v14M5 12h14" ]
        , Html.div [ Attrs.class "eco-atlas-zoom-pct" ] [ Html.text (String.fromInt (round (camera.scale * 100)) ++ "%") ]
        , Html.button [ Attrs.type_ "button", Attrs.class "eco-atlas-ctl", Attrs.attribute "aria-label" "Zoom out", Events.onClick ZoomOut ]
            [ icon "M5 12h14" ]
        , Html.button [ Attrs.type_ "button", Attrs.class "eco-atlas-ctl-fit", Attrs.attribute "aria-label" "Fit whole pipeline", Events.onClick FitAll ]
            [ icon "M4 9V4h5M20 9V4h-5M4 15v5h5M20 15v5h-5" ]
        ]


viewPanel : Graph -> Model -> List (Html Msg)
viewPanel graph model =
    case model.selected |> Maybe.andThen (Graph.node graph) of
        Just n ->
            let
                links arr =
                    Array.get n.index arr |> Maybe.withDefault [] |> List.filterMap (Graph.node graph)

                uses =
                    links graph.out

                usedBy =
                    links graph.inn

                chip m =
                    Html.button
                        [ Attrs.type_ "button"
                        , Attrs.class "eco-atlas-chip"
                        , Events.onClick (FocusOn m.index)
                        ]
                        [ Html.span
                            [ Attrs.class
                                (if m.lang == "cpp" then
                                    "eco-atlas-dot-cpp"

                                 else
                                    "eco-atlas-dot"
                                )
                            ]
                            []
                        , Html.text m.label
                        ]
            in
            [ Html.aside [ Attrs.class "eco-atlas-panel" ]
                [ Html.div [ Attrs.class "eco-atlas-panel-head" ]
                    [ Html.div [ Attrs.class "eco-atlas-panel-titles" ]
                        [ Html.div [ Attrs.class "eco-atlas-panel-stage" ] [ Html.text n.stageName ]
                        , Html.h2 [ Attrs.class "eco-atlas-panel-title" ] [ Html.text n.label ]
                        , Html.div [ Attrs.class "eco-atlas-panel-path" ] [ Html.text n.path ]
                        ]
                    , Html.button
                        [ Attrs.type_ "button"
                        , Attrs.class "eco-atlas-close"
                        , Attrs.attribute "aria-label" "Close"
                        , Events.onClick ClearSelection
                        ]
                        [ icon "M6 6l12 12M18 6L6 18" ]
                    ]
                , Html.div [ Attrs.class "eco-atlas-panel-body" ]
                    (Html.div [ Attrs.class "eco-atlas-panel-uses" ]
                        [ Html.text ("Depends on · " ++ String.fromInt (List.length uses)) ]
                        :: List.map chip uses
                        ++ Html.div [ Attrs.class "eco-atlas-panel-used-by" ]
                            [ Html.text ("Used by · " ++ String.fromInt (List.length usedBy)) ]
                        :: List.map chip usedBy
                    )
                ]
            ]

        Nothing ->
            []


icon : String -> Html msg
icon d =
    Svg.svg
        [ SvgAttrs.width "16"
        , SvgAttrs.height "16"
        , SvgAttrs.viewBox "0 0 24 24"
        , SvgAttrs.fill "none"
        , SvgAttrs.stroke "currentColor"
        , SvgAttrs.strokeWidth "2"
        , SvgAttrs.strokeLinecap "round"
        , SvgAttrs.strokeLinejoin "round"
        , Attrs.attribute "aria-hidden" "true"
        ]
        [ Svg.path [ SvgAttrs.d d ] [] ]


px : Float -> String
px v =
    String.fromFloat (toFloat (round (v * 10)) / 10) ++ "px"


thousands : Int -> String
thousands n =
    if n >= 1000 then
        String.fromInt (n // 1000) ++ "," ++ String.padLeft 3 '0' (String.fromInt (modBy 1000 n))

    else
        String.fromInt n
