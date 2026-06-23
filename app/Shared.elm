module Shared exposing (Data, Model, Msg(..), SharedMsg(..), template)

import BackendTask exposing (BackendTask)
import Effect exposing (Effect)
import FatalError exposing (FatalError)
import Html exposing (Html)
import Pages.Flags
import Pages.PageUrl exposing (PageUrl)
import Route exposing (Route)
import SharedTemplate exposing (SharedTemplate)
import UrlPath exposing (UrlPath)
import View exposing (View)


template : SharedTemplate Msg Model Data msg
template =
    { init = init
    , update = update
    , view = view
    , data = data
    , subscriptions = subscriptions
    , onPageChange = Nothing
    }


type Msg
    = MenuClicked


type alias Data =
    ()


type SharedMsg
    = NoOp


type alias Model =
    { showMenu : Bool
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
init _ _ =
    ( { showMenu = False }
    , Effect.none
    )


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        MenuClicked ->
            ( { model | showMenu = not model.showMenu }, Effect.none )


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
view _ page model toMsg pageView =
    case page.route of
        Just Route.Index ->
            -- Landing page has its own custom layout
            { body = pageView.body
            , title = pageView.title
            }

        Just Route.Docs ->
            -- Docs pages have their own custom layout
            { body = pageView.body
            , title = pageView.title
            }

        Just (Route.Docs__Slug_ _) ->
            -- Docs pages have their own custom layout
            { body = pageView.body
            , title = pageView.title
            }

        Just Route.Articles ->
            -- Articles pages have their own custom layout
            { body = pageView.body
            , title = pageView.title
            }

        Just (Route.Articles__Slug_ _) ->
            -- Articles pages have their own custom layout
            { body = pageView.body
            , title = pageView.title
            }

        Just Route.About ->
            -- About page has its own custom layout
            { body = pageView.body
            , title = pageView.title
            }

        Just Route.Roadmap ->
            -- Roadmap page has its own custom layout
            { body = pageView.body
            , title = pageView.title
            }

        _ ->
            { body = pageView.body
            , title = pageView.title
            }
