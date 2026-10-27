module Content.Packages exposing
    ( PackageInfo, ModuleGroup, Package, ModuleDocs, Section(..), Declaration, DeclarationKind(..)
    , allPackages, hostedPackages, packageFromName, moduleDocs
    , moduleSlug
    )

{-| The API documentation of the packages the site hosts.

Each package has a folder `content/packages/<author>/<name>/` holding three files copied from the package: the
`docs.json` that `elm make --docs` writes, the package's `elm.json` and its `README.md`. A package appears on the site
when its folder is there.

The doc comments are parsed as Markdown here, at build time, so that a comment that does not parse stops the build.

@docs PackageInfo, ModuleGroup, Package, ModuleDocs, Section, Declaration, DeclarationKind
@docs allPackages, hostedPackages, packageFromName, moduleDocs
@docs moduleSlug

-}

import BackendTask exposing (BackendTask)
import BackendTask.File as File
import BackendTask.Glob as Glob
import Elm.Docs
import Elm.Type exposing (Type)
import FatalError exposing (FatalError)
import Json.Decode as Decode exposing (Decoder)
import Markdown.Block exposing (Block)
import Markdown.Parser


{-| What a package's `elm.json` says about it.
-}
type alias PackageInfo =
    { author : String
    , name : String
    , summary : String
    , version : String
    , license : String
    , modules : List ModuleGroup
    , dependencies : List ( String, String )
    }


{-| Exposed modules, as `elm.json` lists them: either one list, which has no title, or lists under headings.
-}
type alias ModuleGroup =
    { title : Maybe String
    , modules : List String
    }


{-| A package: what its `elm.json` says, its README, and the docs of each exposed module.
-}
type alias Package =
    { info : PackageInfo
    , readme : List Block
    , modules : List Elm.Docs.Module
    }


{-| A module's documentation, laid out as its module comment asks: prose, with each `@docs` line replaced by the
declarations it names.
-}
type alias ModuleDocs =
    { name : String
    , sections : List Section
    }


{-| -}
type Section
    = Prose (List Block)
    | DeclarationSection Declaration


{-| A documented type, type alias, value or operator, with its doc comment.
-}
type alias Declaration =
    { name : String
    , kind : DeclarationKind
    , comment : List Block
    }


{-| -}
type DeclarationKind
    = UnionKind { args : List String, tags : List ( String, List Type ) }
    | AliasKind { args : List String, tipe : Type }
    | ValueKind Type
    | BinopKind Type
    | UnknownKind



-- LOADING


packageFolders : BackendTask FatalError (List { author : String, name : String })
packageFolders =
    Glob.succeed (\author name -> { author = author, name = name })
        |> Glob.match (Glob.literal "content/packages/")
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal "/")
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal "/elm.json")
        |> Glob.toBackendTask


{-| Every hosted package, sorted by name.
-}
allPackages : BackendTask FatalError (List Package)
allPackages =
    packageFolders
        |> BackendTask.map (List.sortBy (\folder -> ( folder.author, folder.name )) >> List.map loadPackage)
        |> BackendTask.resolve


{-| The names of the hosted packages, such as `eco/system`, for linking between them.
-}
hostedPackages : BackendTask FatalError (List String)
hostedPackages =
    packageFolders
        |> BackendTask.map (List.map (\folder -> folder.author ++ "/" ++ folder.name))


{-| The package named `author/name`.
-}
packageFromName : { author : String, name : String } -> BackendTask FatalError Package
packageFromName folder =
    packageFolders
        |> BackendTask.andThen
            (\folders ->
                if List.member folder folders then
                    loadPackage folder

                else
                    BackendTask.fail (FatalError.fromString ("No package " ++ folder.author ++ "/" ++ folder.name))
            )


loadPackage : { author : String, name : String } -> BackendTask FatalError Package
loadPackage folder =
    let
        dir =
            "content/packages/" ++ folder.author ++ "/" ++ folder.name ++ "/"
    in
    BackendTask.map3 Package
        (File.jsonFile (infoDecoder folder) (dir ++ "elm.json") |> BackendTask.allowFatal)
        (File.rawFile (dir ++ "README.md")
            |> BackendTask.allowFatal
            |> BackendTask.andThen (parseMarkdown (dir ++ "README.md"))
        )
        (File.jsonFile (Decode.list Elm.Docs.decoder) (dir ++ "docs.json") |> BackendTask.allowFatal)


infoDecoder : { author : String, name : String } -> Decoder PackageInfo
infoDecoder folder =
    Decode.map5 (PackageInfo folder.author folder.name)
        (Decode.field "summary" Decode.string)
        (Decode.field "version" Decode.string)
        (Decode.field "license" Decode.string)
        (Decode.field "exposed-modules" moduleGroupsDecoder)
        (Decode.field "dependencies" (Decode.keyValuePairs Decode.string))


moduleGroupsDecoder : Decoder (List ModuleGroup)
moduleGroupsDecoder =
    Decode.oneOf
        [ Decode.list Decode.string
            |> Decode.map (\modules -> [ { title = Nothing, modules = modules } ])
        , Decode.keyValuePairs (Decode.list Decode.string)
            |> Decode.map (List.map (\( title, modules ) -> { title = Just title, modules = modules }))
        ]


parseMarkdown : String -> String -> BackendTask FatalError (List Block)
parseMarkdown context markdown =
    case Markdown.Parser.parse markdown of
        Ok blocks ->
            BackendTask.succeed blocks

        Err _ ->
            BackendTask.fail (FatalError.fromString ("Markdown that does not parse in " ++ context))



-- MODULES


{-| The docs of the module named by a URL slug, such as `Http-Server`.
-}
moduleDocs : String -> Package -> BackendTask FatalError ModuleDocs
moduleDocs slug package =
    let
        moduleName =
            moduleNameFromSlug slug
    in
    case List.filter (\docs -> docs.name == moduleName) package.modules of
        docs :: _ ->
            Elm.Docs.toBlocks docs
                |> List.map (toSection docs.name)
                |> BackendTask.combine
                |> BackendTask.map (\sections -> { name = docs.name, sections = sections })

        [] ->
            BackendTask.fail
                (FatalError.fromString
                    ("No module " ++ moduleName ++ " in " ++ package.info.author ++ "/" ++ package.info.name)
                )


toSection : String -> Elm.Docs.Block -> BackendTask FatalError Section
toSection moduleName block =
    let
        declaration name kind comment =
            parseMarkdown (moduleName ++ "." ++ name) comment
                |> BackendTask.map (\blocks -> DeclarationSection { name = name, kind = kind, comment = blocks })
    in
    case block of
        Elm.Docs.MarkdownBlock markdown ->
            parseMarkdown moduleName markdown |> BackendTask.map Prose

        Elm.Docs.UnionBlock union ->
            declaration union.name (UnionKind { args = union.args, tags = union.tags }) union.comment

        Elm.Docs.AliasBlock alias ->
            declaration alias.name (AliasKind { args = alias.args, tipe = alias.tipe }) alias.comment

        Elm.Docs.ValueBlock value ->
            declaration value.name (ValueKind value.tipe) value.comment

        Elm.Docs.BinopBlock binop ->
            declaration binop.name (BinopKind binop.tipe) binop.comment

        Elm.Docs.UnknownBlock name ->
            BackendTask.succeed (DeclarationSection { name = name, kind = UnknownKind, comment = [] })


{-| A module's name as it appears in a URL: `Http.Server` is `Http-Server`, as on package.elm-lang.org.
-}
moduleSlug : String -> String
moduleSlug =
    String.replace "." "-"


moduleNameFromSlug : String -> String
moduleNameFromSlug =
    String.replace "-" "."
