module Route.Packages.Author_.Name_.ModuleName_ exposing (ActionData, Data, Model, Msg, RouteParams, route)

import BackendTask exposing (BackendTask)
import Content.Packages exposing (ModuleDocs, PackageInfo)
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
    { author : String, name : String, moduleName : String }


type alias Data =
    { info : PackageInfo
    , docs : ModuleDocs
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
        |> BackendTask.map
            (List.concatMap
                (\package ->
                    List.map
                        (\docs ->
                            { author = package.info.author
                            , name = package.info.name
                            , moduleName = Content.Packages.moduleSlug docs.name
                            }
                        )
                        package.modules
                )
            )


data : RouteParams -> BackendTask FatalError Data
data routeParams =
    Content.Packages.packageFromName { author = routeParams.author, name = routeParams.name }
        |> BackendTask.andThen
            (\package ->
                BackendTask.map2 (\docs hosted -> { info = package.info, docs = docs, hosted = hosted })
                    (Content.Packages.moduleDocs routeParams.moduleName package)
                    Content.Packages.hostedPackages
            )


title : App Data ActionData RouteParams -> String
title app =
    app.data.docs.name ++ " - " ++ app.data.info.author ++ "/" ++ app.data.info.name ++ " - " ++ Settings.title


head : App Data ActionData RouteParams -> List Head.Tag
head app =
    Layout.Packages.seo
        { title = title app
        , description = Layout.Packages.moduleDescription app.data.info app.data.docs
        }


view : App Data ActionData RouteParams -> Shared.Model -> View (PagesMsg Msg)
view app _ =
    { title = title app
    , body = Layout.Packages.viewModulePage app.data.hosted app.data.info app.data.docs
    }
