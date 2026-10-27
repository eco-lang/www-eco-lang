module Route.Packages.Author_.Name_ exposing (ActionData, Data, Model, Msg, RouteParams, route)

import BackendTask exposing (BackendTask)
import Content.Packages exposing (PackageInfo)
import FatalError exposing (FatalError)
import Head
import Layout.Packages
import Markdown.Block exposing (Block)
import PagesMsg exposing (PagesMsg)
import RouteBuilder exposing (App, StatelessRoute)
import Settings
import Shared
import View exposing (View)


type alias Model =
    {}


type alias Msg =
    ()


type alias RouteParams =
    { author : String, name : String }


type alias Data =
    { info : PackageInfo
    , readme : List Block
    , hosted : List String
    }


type alias ActionData =
    {}


route : StatelessRoute RouteParams Data ActionData
route =
    RouteBuilder.preRender
        { head = head
        , pages = pages
        , data = data
        }
        |> RouteBuilder.buildNoState { view = view }


pages : BackendTask FatalError (List RouteParams)
pages =
    Content.Packages.allPackages
        |> BackendTask.map (List.map (\package -> { author = package.info.author, name = package.info.name }))


data : RouteParams -> BackendTask FatalError Data
data routeParams =
    BackendTask.map2 (\package hosted -> { info = package.info, readme = package.readme, hosted = hosted })
        (Content.Packages.packageFromName routeParams)
        Content.Packages.hostedPackages


title : App Data ActionData RouteParams -> String
title app =
    app.data.info.author ++ "/" ++ app.data.info.name ++ " - " ++ Settings.title ++ " Packages"


head : App Data ActionData RouteParams -> List Head.Tag
head app =
    Layout.Packages.seo { title = title app, description = app.data.info.summary }


view : App Data ActionData RouteParams -> Shared.Model -> View (PagesMsg Msg)
view app _ =
    { title = title app
    , body = Layout.Packages.viewPackagePage app.data.hosted app.data.info app.data.readme
    }
