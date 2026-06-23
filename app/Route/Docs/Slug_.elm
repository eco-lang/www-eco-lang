module Route.Docs.Slug_ exposing (ActionData, Data, Model, Msg, RouteParams, route)

import BackendTask exposing (BackendTask)
import Content.Docs exposing (DocPage, TocSection)
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Layout.Docs
import MimeType
import Pages.Url
import PagesMsg exposing (PagesMsg)
import RouteBuilder exposing (App, StatelessRoute)
import Settings
import Shared
import UrlPath
import View exposing (View)


type alias Model =
    {}


type alias Msg =
    ()


type alias RouteParams =
    { slug : String }


type alias Data =
    { docPage : DocPage
    , tocSections : List TocSection
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
    Content.Docs.allDocPages
        |> BackendTask.map
            (List.map (\page -> { slug = page.metadata.slug }))


data : RouteParams -> BackendTask FatalError Data
data routeParams =
    BackendTask.map2 Data
        (Content.Docs.docPageFromSlug routeParams.slug)
        Content.Docs.tocSections


head :
    App Data ActionData RouteParams
    -> List Head.Tag
head app =
    Seo.summaryLarge
        { canonicalUrlOverride = Just Settings.canonicalUrl
        , siteName = Settings.title
        , image =
            { url = [ "media", "logo.svg" ] |> UrlPath.join |> Pages.Url.fromPath
            , alt = Settings.title
            , dimensions = Just { width = 700, height = 351 }
            , mimeType = Just (MimeType.Image (MimeType.OtherImage "svg+xml"))
            }
        , description = Maybe.withDefault Settings.subtitle app.data.docPage.metadata.description
        , locale = Settings.locale
        , title = app.data.docPage.metadata.title ++ " - " ++ Settings.title ++ " Docs"
        }
        |> Seo.website


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> View (PagesMsg Msg)
view app _ =
    { title = app.data.docPage.metadata.title ++ " - " ++ Settings.title ++ " Docs"
    , body = Layout.Docs.viewDocsPage app.routeParams.slug app.data.docPage app.data.tocSections
    }
