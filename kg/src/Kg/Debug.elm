module Kg.Debug exposing (factsJson)

{-| JSON views of facts, for `kg facts` and for comparing with the Python. -}

import Dict
import Json.Encode as E
import Kg.Facts exposing (FileFacts(..))


factsJson : String -> FileFacts -> E.Value
factsJson path facts =
    case facts of
        CppFile f ->
            E.object
                [ ( "path", E.string path )
                , ( "includes", E.list E.string f.includes )
                , ( "defs", E.list (\( a, b ) -> E.list E.string [ a, b ]) f.defs )
                , ( "classes", E.list E.string f.classes )
                , ( "opened", E.list E.string f.opened )
                , ( "tokens", E.list E.string f.tokens )
                , ( "uses", E.dict identity (\u -> E.list identity [ E.list E.string u.quals, E.bool u.declares ]) f.uses )
                ]

        ElmFile f ->
            E.object
                [ ( "path", E.string path )
                , ( "module", E.string f.moduleName )
                , ( "imports", E.list (\i -> E.string i.name) f.imports )
                , ( "decls", E.list (\d -> E.object [ ( "name", E.string d.name ), ( "line", E.int d.line ), ( "sig", Maybe.withDefault E.null (Maybe.map E.string d.signature) ), ( "doc", E.bool (d.doc /= Nothing) ), ( "exposed", E.bool d.exposed ) ]) f.decls )
                , ( "references", E.int (List.length f.references) )
                , ( "fieldReads", E.int (List.length f.fieldReads) )
                , ( "config", E.list (\c -> E.object [ ( "path", E.string (String.join "." c.path) ), ( "type", E.string c.typeName ), ( "default", E.string c.default ), ( "doc", E.string (String.left 80 c.doc) ) ]) f.config )
                , ( "parseError", Maybe.withDefault E.null (Maybe.map E.string f.parseError) )
                ]

        ElmJson f ->
            E.object [ ( "path", E.string path ), ( "sourceDirectories", E.list E.string f.sourceDirectories ), ( "dependencies", E.list (\( a, b ) -> E.list E.string [ a, b ]) f.dependencies ) ]

        CMake f ->
            E.object
                [ ( "path", E.string path )
                , ( "libraries", E.list (\( a, b ) -> E.list identity [ E.string a, E.list E.string b ]) f.libraries )
                , ( "variables", E.list (\( a, b ) -> E.list identity [ E.string a, E.list E.string b ]) f.variables )
                ]

        Markdown f ->
            E.object
                [ ( "path", E.string path )
                , ( "title", E.string f.title )
                , ( "frontMatter", E.dict identity E.string f.frontMatter )
                , ( "sections", E.list (\s -> E.object [ ( "path", E.list E.string s.path ), ( "line", E.int s.startLine ), ( "chars", E.int (String.length s.text) ) ]) f.sections )
                , ( "mentions", E.list (\m -> E.string (m.target ++ "@" ++ String.fromInt m.line)) f.mentions )
                ]

        Invariants is ->
            E.object [ ( "path", E.string path ), ( "count", E.int (List.length is) ), ( "first", E.list (\i -> E.list E.string [ i.id, i.status, i.description, i.source ]) (List.take 3 is) ) ]

        Unparsed why ->
            E.object [ ( "path", E.string path ), ( "unparsed", E.string why ) ]
