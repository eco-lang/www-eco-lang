module Route.Articles exposing (ActionData, Data, Model, Msg, RouteParams, route)

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
    {}


type alias Data =
    { articlePage : ArticlePage
    , tocSections : List TocSection
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
    BackendTask.map2 Data
        firstArticlePage
        Content.Articles.tocSections


firstArticlePage : BackendTask FatalError ArticlePage
firstArticlePage =
    Content.Articles.allArticlePages
        |> BackendTask.andThen
            (\pages ->
                case List.head pages of
                    Just page ->
                        BackendTask.succeed page

                    Nothing ->
                        BackendTask.fail <|
                            FatalError.fromString "No article pages found"
            )


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
        , description = Maybe.withDefault Settings.subtitle app.data.articlePage.metadata.description
        , locale = Settings.locale
        , title = Settings.title ++ " Articles"
        }
        |> Seo.website


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> View (PagesMsg Msg)
view app _ =
    { title = Settings.title ++ " Articles"
    , body = Layout.Articles.viewArticlesPage app.data.articlePage.metadata.slug app.data.articlePage app.data.tocSections
    }
