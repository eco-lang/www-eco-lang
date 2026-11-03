module Kg.Extract exposing (extract, kind, Kind(..))

{-| File → facts (§8 of the plan): picks the extractor by path. -}

import Kg.Extract.Build as Build
import Kg.Extract.Cpp as Cpp
import Kg.Extract.Elm as Elm
import Kg.Extract.Prose as Prose
import Kg.Facts exposing (FileFacts(..))


type Kind
    = ElmSource
    | CppSource
    | ElmJsonFile
    | CMakeFile
    | MarkdownFile
    | InvariantsFile
    | Other


kind : String -> Kind
kind path =
    if String.endsWith ".elm" path then
        ElmSource

    else if List.any (\e -> String.endsWith e path) [ ".cpp", ".hpp", ".h", ".td" ] then
        CppSource

    else if String.endsWith "elm.json" path then
        ElmJsonFile

    else if String.endsWith "CMakeLists.txt" path then
        CMakeFile

    else if path == "design_docs/invariants.csv" then
        InvariantsFile

    else if String.endsWith ".md" path then
        MarkdownFile

    else
        Other


extract : String -> String -> FileFacts
extract path text =
    case kind path of
        ElmSource ->
            ElmFile (Elm.extract path text)

        CppSource ->
            CppFile (Cpp.extract path text)

        ElmJsonFile ->
            Build.elmJson text

        CMakeFile ->
            CMake (Build.cmake path text)

        MarkdownFile ->
            Markdown (Prose.markdown path text)

        InvariantsFile ->
            Invariants (Prose.invariants text)

        Other ->
            Unparsed "not a kind of file kg reads"
