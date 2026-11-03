module Kg.Facts exposing
    ( FileFacts(..), ElmFacts, ElmImport, Exposing(..), Decl, DeclKind(..), Reference, FieldRead
    , CppFacts, Uses, CMakeFacts, TableGen(..), ElmJsonFacts
    , MarkdownFacts, Section, Mention, Invariant, ConfigFlag
    , extractorVersion, codec, emptyElm
    )

{-| What one version of one file says (§8 of the plan). Facts are extracted once
per blob and cached by `(blob id, extractorVersion)`.

`extractorVersion` must be raised whenever any extractor changes its output;
that invalidates the whole fact cache.

-}

import Dict exposing (Dict)
import Kg.Codec as C exposing (Codec)


extractorVersion : Int
extractorVersion =
    3


type FileFacts
    = ElmFile ElmFacts
    | CppFile CppFacts
    | ElmJson ElmJsonFacts
    | CMake CMakeFacts
    | Markdown MarkdownFacts
    | Invariants (List Invariant)
    | Unparsed String



-- ELM


type alias ElmFacts =
    { moduleName : String
    , imports : List ElmImport
    , moduleDoc : Maybe String
    , decls : List Decl
    , references : List Reference
    , fieldReads : List FieldRead
    , config : List ConfigFlag
    , parseError : Maybe String
    }


type alias ElmImport =
    { name : String, asName : Maybe String, exposes : Exposing }


type Exposing
    = ExposeAll
    | ExposeList (List String)


type alias Decl =
    { name : String, kind : DeclKind, signature : Maybe String, doc : Maybe String, line : Int, exposed : Bool }


type DeclKind
    = Value
    | Union
    | Alias
    | Port


{-| A use of a name in a declaration's body or annotation: `qualifier` is the
module or alias written before it ("" for none), `from` the declaration it is
in.
-}
type alias Reference =
    { from : String, qualifier : String, name : String, line : Int, isType : Bool }


type alias FieldRead =
    { from : String, field : String, line : Int, text : String }


type alias ConfigFlag =
    { path : List String, typeName : String, default : String, doc : String }


emptyElm : String -> ElmFacts
emptyElm name =
    { moduleName = name, imports = [], moduleDoc = Nothing, decls = [], references = [], fieldReads = [], config = [], parseError = Nothing }



-- C++


{-| How a file uses one name: the qualifiers it is written with ("" for none),
and whether the file also declares it (`T name(` or `extern T name;`).
-}
type alias Uses =
    { quals : List String, declares : Bool }


type alias CppFacts =
    { includes : List String
    , defs : List ( String, String )
    , classes : List String
    , opened : List String
    , tokens : List String
    , uses : Dict String Uses
    , comments : List { line : Int, text : String }
    }


type alias ElmJsonFacts =
    { sourceDirectories : List String, dependencies : List ( String, String ) }


type TableGen
    = TableGenDefinitions String
    | TableGenInc String


type alias CMakeFacts =
    { libraries : List ( String, List String )
    , tablegen : List TableGen
    , variables : List ( String, List String )
    }



-- PROSE


type alias MarkdownFacts =
    { frontMatter : Dict String String
    , title : String
    , sections : List Section
    , mentions : List Mention
    }


type alias Section =
    { path : List String, startLine : Int, text : String }


type alias Mention =
    { target : String, line : Int }


type alias Invariant =
    { id : String, phase : String, category : String, status : String, description : String, source : String, line : Int }



-- CODECS


codec : Codec FileFacts
codec =
    C.withHeader "KGF" extractorVersion <|
        C.variants
            [ C.variant1 ElmFile
                (\f ->
                    case f of
                        ElmFile x ->
                            Just x

                        _ ->
                            Nothing
                )
                elmCodec
            , C.variant1 CppFile
                (\f ->
                    case f of
                        CppFile x ->
                            Just x

                        _ ->
                            Nothing
                )
                cppCodec
            , C.variant1 ElmJson
                (\f ->
                    case f of
                        ElmJson x ->
                            Just x

                        _ ->
                            Nothing
                )
                elmJsonCodec
            , C.variant1 CMake
                (\f ->
                    case f of
                        CMake x ->
                            Just x

                        _ ->
                            Nothing
                )
                cmakeCodec
            , C.variant1 Markdown
                (\f ->
                    case f of
                        Markdown x ->
                            Just x

                        _ ->
                            Nothing
                )
                markdownCodec
            , C.variant1 Invariants
                (\f ->
                    case f of
                        Invariants x ->
                            Just x

                        _ ->
                            Nothing
                )
                (C.list invariantCodec)
            , C.variant1 Unparsed
                (\f ->
                    case f of
                        Unparsed x ->
                            Just x

                        _ ->
                            Nothing
                )
                C.string
            ]


elmCodec : Codec ElmFacts
elmCodec =
    C.record ElmFacts
        |> C.field .moduleName C.string
        |> C.field .imports (C.list importCodec)
        |> C.field .moduleDoc (C.maybe C.string)
        |> C.field .decls (C.list declCodec)
        |> C.field .references (C.list referenceCodec)
        |> C.field .fieldReads (C.list fieldReadCodec)
        |> C.field .config (C.list configCodec)
        |> C.field .parseError (C.maybe C.string)
        |> C.finish


importCodec : Codec ElmImport
importCodec =
    C.record ElmImport
        |> C.field .name C.string
        |> C.field .asName (C.maybe C.string)
        |> C.field .exposes exposingCodec
        |> C.finish


exposingCodec : Codec Exposing
exposingCodec =
    C.variants
        [ C.variant0 ExposeAll ((==) ExposeAll)
        , C.variant1 ExposeList
            (\e ->
                case e of
                    ExposeList xs ->
                        Just xs

                    _ ->
                        Nothing
            )
            (C.list C.string)
        ]


declCodec : Codec Decl
declCodec =
    C.record Decl
        |> C.field .name C.string
        |> C.field .kind declKindCodec
        |> C.field .signature (C.maybe C.string)
        |> C.field .doc (C.maybe C.string)
        |> C.field .line C.int
        |> C.field .exposed C.bool
        |> C.finish


declKindCodec : Codec DeclKind
declKindCodec =
    C.variants
        [ C.variant0 Value ((==) Value)
        , C.variant0 Union ((==) Union)
        , C.variant0 Alias ((==) Alias)
        , C.variant0 Port ((==) Port)
        ]


referenceCodec : Codec Reference
referenceCodec =
    C.record Reference
        |> C.field .from C.string
        |> C.field .qualifier C.string
        |> C.field .name C.string
        |> C.field .line C.int
        |> C.field .isType C.bool
        |> C.finish


fieldReadCodec : Codec FieldRead
fieldReadCodec =
    C.record FieldRead
        |> C.field .from C.string
        |> C.field .field C.string
        |> C.field .line C.int
        |> C.field .text C.string
        |> C.finish


configCodec : Codec ConfigFlag
configCodec =
    C.record ConfigFlag
        |> C.field .path (C.list C.string)
        |> C.field .typeName C.string
        |> C.field .default C.string
        |> C.field .doc C.string
        |> C.finish


cppCodec : Codec CppFacts
cppCodec =
    C.record CppFacts
        |> C.field .includes (C.list C.string)
        |> C.field .defs (C.list (C.pair C.string C.string))
        |> C.field .classes (C.list C.string)
        |> C.field .opened (C.list C.string)
        |> C.field .tokens (C.list C.string)
        |> C.field .uses (C.dict C.string usesCodec)
        |> C.field .comments (C.list (C.record (\l t -> { line = l, text = t }) |> C.field .line C.int |> C.field .text C.string |> C.finish))
        |> C.finish


usesCodec : Codec Uses
usesCodec =
    C.record Uses
        |> C.field .quals (C.list C.string)
        |> C.field .declares C.bool
        |> C.finish


elmJsonCodec : Codec ElmJsonFacts
elmJsonCodec =
    C.record ElmJsonFacts
        |> C.field .sourceDirectories (C.list C.string)
        |> C.field .dependencies (C.list (C.pair C.string C.string))
        |> C.finish


cmakeCodec : Codec CMakeFacts
cmakeCodec =
    C.record CMakeFacts
        |> C.field .libraries (C.list (C.pair C.string (C.list C.string)))
        |> C.field .tablegen (C.list tablegenCodec)
        |> C.field .variables (C.list (C.pair C.string (C.list C.string)))
        |> C.finish


tablegenCodec : Codec TableGen
tablegenCodec =
    C.variants
        [ C.variant1 TableGenDefinitions
            (\t ->
                case t of
                    TableGenDefinitions x ->
                        Just x

                    _ ->
                        Nothing
            )
            C.string
        , C.variant1 TableGenInc
            (\t ->
                case t of
                    TableGenInc x ->
                        Just x

                    _ ->
                        Nothing
            )
            C.string
        ]


markdownCodec : Codec MarkdownFacts
markdownCodec =
    C.record MarkdownFacts
        |> C.field .frontMatter (C.dict C.string C.string)
        |> C.field .title C.string
        |> C.field .sections (C.list sectionCodec)
        |> C.field .mentions (C.list mentionCodec)
        |> C.finish


sectionCodec : Codec Section
sectionCodec =
    C.record Section
        |> C.field .path (C.list C.string)
        |> C.field .startLine C.int
        |> C.field .text C.string
        |> C.finish


mentionCodec : Codec Mention
mentionCodec =
    C.record Mention
        |> C.field .target C.string
        |> C.field .line C.int
        |> C.finish


invariantCodec : Codec Invariant
invariantCodec =
    C.record Invariant
        |> C.field .id C.string
        |> C.field .phase C.string
        |> C.field .category C.string
        |> C.field .status C.string
        |> C.field .description C.string
        |> C.field .source C.string
        |> C.field .line C.int
        |> C.finish
