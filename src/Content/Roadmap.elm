module Content.Roadmap exposing
    ( MilestoneGroup
    , MilestoneStatus(..)
    , RoadmapMeta
    , roadmapData
    )

import BackendTask exposing (BackendTask)
import BackendTask.File as File
import Dict exposing (Dict)
import FatalError exposing (FatalError)
import Json.Decode as Decode exposing (Decoder)
import Markdown.Block exposing (Block(..))
import Markdown.Parser


type MilestoneStatus
    = Released
    | Current
    | Planned


type alias RoadmapMeta =
    { title : String
    , description : String
    , statuses : Dict String String
    }


type alias MilestoneGroup =
    { version : String
    , codename : String
    , status : MilestoneStatus
    , blocks : List Block
    }


roadmapData : BackendTask FatalError { meta : RoadmapMeta, milestones : List MilestoneGroup }
roadmapData =
    "content/roadmap.md"
        |> File.bodyWithFrontmatter
            (\markdownString ->
                let
                    parsedBody =
                        markdownString
                            |> Markdown.Parser.parse
                            |> Result.mapError (\_ -> "Failed to parse roadmap markdown")
                in
                Decode.map2
                    (\meta blocks ->
                        { meta = meta
                        , milestones = groupByMilestones meta.statuses blocks
                        }
                    )
                    metadataDecoder
                    (case parsedBody of
                        Ok blocks ->
                            Decode.succeed blocks

                        Err err ->
                            Decode.fail err
                    )
            )
        |> BackendTask.allowFatal


metadataDecoder : Decoder RoadmapMeta
metadataDecoder =
    Decode.map3 RoadmapMeta
        (Decode.field "title" Decode.string)
        (Decode.field "description" Decode.string)
        (Decode.field "statuses" (Decode.dict Decode.string))



-- BLOCK GROUPING


groupByMilestones : Dict String String -> List Block -> List MilestoneGroup
groupByMilestones statuses blocks =
    groupByH2 blocks
        |> List.filterMap (toMilestoneGroup statuses)


groupByH2 : List Block -> List { heading : List Markdown.Block.Inline, body : List Block }
groupByH2 blocks =
    List.foldl
        (\block acc ->
            case block of
                Heading Markdown.Block.H2 inlines ->
                    -- Start a new group
                    { heading = inlines, body = [] } :: acc

                _ ->
                    case acc of
                        current :: rest ->
                            { current | body = current.body ++ [ block ] } :: rest

                        [] ->
                            -- Block before first H2: discard
                            acc
        )
        []
        blocks
        |> List.reverse


toMilestoneGroup : Dict String String -> { heading : List Markdown.Block.Inline, body : List Block } -> Maybe MilestoneGroup
toMilestoneGroup statuses group =
    let
        rawText =
            Markdown.Block.extractInlineText group.heading

        ( version, codename ) =
            parseHeading rawText
    in
    if String.isEmpty version then
        Nothing

    else
        let
            status =
                Dict.get version statuses
                    |> Maybe.map parseStatus
                    |> Maybe.withDefault Planned
        in
        Just
            { version = version
            , codename = codename
            , status = status
            , blocks = group.body
            }


parseHeading : String -> ( String, String )
parseHeading text =
    case String.split ": " text of
        ver :: rest ->
            ( String.trim ver, String.trim (String.join ": " rest) )

        _ ->
            ( String.trim text, "" )


parseStatus : String -> MilestoneStatus
parseStatus str =
    case String.toLower (String.trim str) of
        "released" ->
            Released

        "current" ->
            Current

        _ ->
            Planned
