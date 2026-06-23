module Content.Articles exposing
    ( ArticleMetadata
    , ArticlePage
    , TocSection
    , allArticlePages
    , articlePageFromSlug
    , tocSections
    )

import Array
import BackendTask exposing (BackendTask)
import BackendTask.File as File
import BackendTask.Glob as Glob
import Dict exposing (Dict)
import FatalError exposing (FatalError)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as Decode
import List.Extra
import Markdown.Block exposing (Block)
import Markdown.Parser
import String.Normalize


type alias ArticleMetadata =
    { title : String
    , slug : String
    , description : Maybe String
    , section : String
    , sectionOrder : Int
    , order : Int
    , image : Maybe String
    }


type alias ArticlePage =
    { metadata : ArticleMetadata
    , body : List Block
    , previousPage : Maybe ArticleMetadata
    , nextPage : Maybe ArticleMetadata
    }


type alias TocSection =
    { name : String
    , pages : List ArticleMetadata
    }


metadataDecoder : String -> Decoder ArticleMetadata
metadataDecoder slug =
    Decode.succeed ArticleMetadata
        |> Decode.andMap (Decode.field "title" Decode.string)
        |> Decode.andMap
            (Decode.succeed (String.Normalize.slug slug))
        |> Decode.andMap (Decode.maybe (Decode.field "description" Decode.string))
        |> Decode.andMap (Decode.field "section" Decode.string)
        |> Decode.andMap (Decode.field "sectionOrder" Decode.int)
        |> Decode.andMap (Decode.field "order" Decode.int)
        |> Decode.andMap (Decode.maybe (Decode.field "image" Decode.string))


articleFiles : BackendTask FatalError (List { filePath : String, slug : String })
articleFiles =
    Glob.succeed
        (\filePath fileName ->
            { filePath = filePath
            , slug = fileName
            }
        )
        |> Glob.captureFilePath
        |> Glob.match (Glob.literal "content/articles/")
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal ".md")
        |> Glob.toBackendTask


sortKey : ArticleMetadata -> ( Int, Int )
sortKey metadata =
    ( metadata.sectionOrder, metadata.order )


allArticlePages : BackendTask FatalError (List ArticlePage)
allArticlePages =
    articleFiles
        |> BackendTask.map
            (List.map
                (\file ->
                    file.filePath
                        |> File.bodyWithFrontmatter
                            (\markdownString ->
                                let
                                    parsedBody =
                                        markdownString
                                            |> Markdown.Parser.parse
                                            |> Result.mapError (\_ -> "Failed to parse markdown")
                                in
                                Decode.map2
                                    (\metadata body ->
                                        ArticlePage metadata body Nothing Nothing
                                    )
                                    (metadataDecoder file.slug)
                                    (case parsedBody of
                                        Ok blocks ->
                                            Decode.succeed blocks

                                        Err err ->
                                            Decode.fail err
                                    )
                            )
                        |> BackendTask.allowFatal
                )
            )
        |> BackendTask.resolve
        |> BackendTask.map
            (List.sortBy (.metadata >> sortKey))
        |> addPreviousNextPages


addPreviousNextPages : BackendTask FatalError (List ArticlePage) -> BackendTask FatalError (List ArticlePage)
addPreviousNextPages orderedPages =
    orderedPages
        |> BackendTask.map Array.fromList
        |> BackendTask.map
            (\pages ->
                Array.indexedMap
                    (\index page ->
                        { page
                            | previousPage = Array.get (index - 1) pages |> Maybe.map .metadata
                            , nextPage = Array.get (index + 1) pages |> Maybe.map .metadata
                        }
                    )
                    pages
            )
        |> BackendTask.map Array.toList


allArticlePagesDict : BackendTask FatalError (Dict String ArticlePage)
allArticlePagesDict =
    allArticlePages
        |> BackendTask.map
            (\pages ->
                List.map (\page -> ( page.metadata.slug, page )) pages
                    |> Dict.fromList
            )


articlePageFromSlug : String -> BackendTask FatalError ArticlePage
articlePageFromSlug slug =
    allArticlePagesDict
        |> BackendTask.andThen
            (\dict ->
                Dict.get slug dict
                    |> Maybe.map BackendTask.succeed
                    |> Maybe.withDefault
                        (BackendTask.fail <|
                            FatalError.fromString <|
                                "Unable to find article page with slug "
                                    ++ slug
                        )
            )


tocSections : BackendTask FatalError (List TocSection)
tocSections =
    allArticlePages
        |> BackendTask.map
            (\pages ->
                pages
                    |> List.map .metadata
                    |> List.Extra.groupWhile
                        (\a b -> a.section == b.section)
                    |> List.map
                        (\( first, rest ) ->
                            { name = first.section
                            , pages = first :: rest
                            }
                        )
            )
