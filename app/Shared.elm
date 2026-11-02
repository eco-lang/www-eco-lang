module Shared exposing (Data, Model, Msg(..), SharedMsg(..), template)

import BackendTask exposing (BackendTask)
import Browser.Dom
import Effect exposing (Effect)
import FatalError exposing (FatalError)
import Html exposing (Html)
import Json.Decode as Decode
import Pages.Flags
import Pages.PageUrl exposing (PageUrl)
import Process
import Route exposing (Route)
import SharedTemplate exposing (SharedTemplate)
import Style
import Style.Packages
import Task
import UrlPath exposing (UrlPath)
import View exposing (View)


template : SharedTemplate Msg Model Data msg
template =
    { init = init
    , update = update
    , view = view
    , data = data
    , subscriptions = subscriptions
    , onPageChange = Just (\page -> PageChanged page.fragment)
    }


type Msg
    = PageChanged (Maybe String)
    | ScrolledToFragment


type alias Data =
    ()


type SharedMsg
    = NoOp


{-| `pixelRatio` is the number of device pixels to a CSS pixel, from the browser when the site loads. It is 1 when
pages are pre-rendered.
-}
type alias Model =
    { pixelRatio : Float
    }


init :
    Pages.Flags.Flags
    ->
        Maybe
            { path :
                { path : UrlPath
                , query : Maybe String
                , fragment : Maybe String
                }
            , metadata : route
            , pageUrl : Maybe PageUrl
            }
    -> ( Model, Effect Msg )
init flags _ =
    ( { pixelRatio =
            case flags of
                Pages.Flags.BrowserFlags value ->
                    Decode.decodeValue (Decode.field "pixelRatio" Decode.float) value
                        |> Result.withDefault 1

                Pages.Flags.PreRenderFlags ->
                    1
      }
    , Effect.none
    )


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        PageChanged (Just fragment) ->
            ( model, Effect.fromCmd (scrollToFragment fragment) )

        PageChanged Nothing ->
            ( model, Effect.none )

        ScrolledToFragment ->
            ( model, Effect.none )


{-| elm-pages scrolls to the top after navigating to another page, even when
the URL has a fragment, so a link such as `/docs/glossary#kernel` would land at
the top of the glossary. Once the new page has rendered, scroll to the element
the fragment names instead. If there is no such element, stay where we are.
-}
scrollToFragment : String -> Cmd Msg
scrollToFragment id =
    Process.sleep 50
        |> Task.andThen (\_ -> Browser.Dom.getElement id)
        |> Task.andThen (\found -> Browser.Dom.setViewport 0 found.element.y)
        |> Task.attempt (\_ -> ScrolledToFragment)


subscriptions : UrlPath -> Model -> Sub Msg
subscriptions _ _ =
    Sub.none


data : BackendTask FatalError Data
data =
    BackendTask.succeed ()


view :
    Data
    ->
        { path : UrlPath
        , route : Maybe Route
        }
    -> Model
    -> (Msg -> msg)
    -> View msg
    -> { body : List (Html msg), title : String }
view _ page _ _ pageView =
    -- Every route draws its own layout. The stylesheets go here, once, at the same place on every page, so that
    -- navigating between layouts does not recreate them. The packages pages have stylesheets of their own.
    { body =
        if isPackagesPage page.route then
            Style.Packages.styleNode :: Style.Packages.highlightTheme :: pageView.body

        else
            Style.styleNode :: Style.highlightTheme :: pageView.body
    , title = pageView.title
    }


isPackagesPage : Maybe Route -> Bool
isPackagesPage route =
    case route of
        Just Route.Packages ->
            True

        Just (Route.Packages__Author___Name_ _) ->
            True

        Just (Route.Packages__Author___Name___ModuleName_ _) ->
            True

        _ ->
            False
