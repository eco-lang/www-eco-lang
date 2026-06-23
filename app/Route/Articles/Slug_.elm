module Route.Articles.Slug_ exposing (ActionData, Data, Model, Msg, RouteParams, route)

import BackendTask exposing (BackendTask)
import Content.Articles exposing (ArticlePage, TocSection)
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Layout.Articles
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
    { articlePage : ArticlePage
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
    Content.Articles.allArticlePages
        |> BackendTask.map
            (List.map (\page -> { slug = page.metadata.slug }))


data : RouteParams -> BackendTask FatalError Data
data routeParams =
    BackendTask.map2 Data
        (Content.Articles.articlePageFromSlug routeParams.slug)
        Content.Articles.tocSections


head :
    App Data ActionData RouteParams
    -> List Head.Tag
head app =
    let
        meta =
            app.data.articlePage.metadata

        image =
            case meta.image of
                Just imagePath ->
                    { url = imagePath |> String.dropLeft 1 |> UrlPath.fromString |> Pages.Url.fromPath
                    , alt = meta.title
                    , dimensions = Nothing
                    , mimeType = Just (MimeType.Image MimeType.Png)
                    }

                Nothing ->
                    { url = [ "media", "logo.svg" ] |> UrlPath.join |> Pages.Url.fromPath
                    , alt = Settings.title
                    , dimensions = Just { width = 700, height = 351 }
                    , mimeType = Just (MimeType.Image (MimeType.OtherImage "svg+xml"))
                    }
    in
    Seo.summaryLarge
        { canonicalUrlOverride = Just Settings.canonicalUrl
        , siteName = Settings.title
        , image = image
        , description = Maybe.withDefault Settings.subtitle meta.description
        , locale = Settings.locale
        , title = meta.title ++ " - " ++ Settings.title ++ " Articles"
        }
        |> Seo.website


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> View (PagesMsg Msg)
view app _ =
    { title = app.data.articlePage.metadata.title ++ " - " ++ Settings.title ++ " Articles"
    , body = Layout.Articles.viewArticlesPage app.routeParams.slug app.data.articlePage app.data.tocSections
    }
