module Route.Packages exposing (ActionData, Data, Model, Msg, RouteParams, route)

import BackendTask exposing (BackendTask)
import Content.Packages exposing (PackageInfo)
import FatalError exposing (FatalError)
import Head
import Layout.Packages
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
    {}


type alias Data =
    { packages : List PackageInfo }


type alias ActionData =
    {}


route : StatelessRoute RouteParams Data ActionData
route =
    RouteBuilder.single
        { head = head
        , data = data
        }
        |> RouteBuilder.buildNoState { view = view }


data : BackendTask FatalError Data
data =
    Content.Packages.allPackages
        |> BackendTask.map (\packages -> { packages = List.map .info packages })


title : String
title =
    "Packages - " ++ Settings.title


head : App Data ActionData RouteParams -> List Head.Tag
head _ =
    Layout.Packages.seo
        { title = title
        , description = "API documentation for the packages that come with eco."
        }


view : App Data ActionData RouteParams -> Shared.Model -> View (PagesMsg Msg)
view app _ =
    { title = title
    , body = Layout.Packages.viewIndexPage app.data.packages
    }
