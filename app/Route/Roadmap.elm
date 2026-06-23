module Route.Roadmap exposing (ActionData, Data, Model, Msg, RouteParams, route)

import BackendTask exposing (BackendTask)
import Content.Roadmap exposing (MilestoneGroup, RoadmapMeta)
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Html
import Html.Attributes as Attrs
import Layout.Roadmap
import MimeType
import Layout.Site
import Pages.Url
import PagesMsg exposing (PagesMsg)
import RouteBuilder exposing (App, StatelessRoute)
import Settings
import Shared
import Style
import UrlPath
import View exposing (View)


type alias Model =
    {}


type alias Msg =
    ()


type alias RouteParams =
    {}


type alias Data =
    { meta : RoadmapMeta
    , milestones : List MilestoneGroup
    }


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
    Content.Roadmap.roadmapData


head :
    App Data ActionData RouteParams
    -> List Head.Tag
head app =
    Seo.summary
        { canonicalUrlOverride = Just Settings.canonicalUrl
        , siteName = Settings.title
        , image =
            { url = [ "images", "site-image.png" ] |> UrlPath.join |> Pages.Url.fromPath
            , alt = "eco Roadmap"
            , dimensions = Just { width = 300, height = 300 }
            , mimeType = Just (MimeType.Image MimeType.Png)
            }
        , description = app.data.meta.description
        , locale = Settings.locale
        , title = app.data.meta.title
        }
        |> Seo.website


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> View (PagesMsg Msg)
view app _ =
    { title = app.data.meta.title
    , body =
        [ Html.div
            [ Attrs.class "min-h-screen flex flex-col eco-page"
            ]
            ([ Style.styleNode
             , Layout.Site.viewHeader (Just Layout.Site.Roadmap)
             ]
                ++ Layout.Roadmap.viewRoadmapPage
                    { title = app.data.meta.title
                    , description = app.data.meta.description
                    }
                    app.data.milestones
                ++ [ Layout.Site.viewFooterDivider
                   , Layout.Site.viewFooter
                   ]
            )
        ]
    }
