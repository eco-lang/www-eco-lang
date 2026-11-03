module Kg.Extract.Config exposing (flags)

{-| The compiler's config flags, from `compiler/src/Compiler/Config.elm`
(§8.5 of the plan): every field of `EcoConfig`, through the record aliases it
nests, with its path, its type, its default from `default` (and the
`defaultX` values it refers to) as source text, and its doc: the paragraph of
its record's doc that names it.
-}

import Array exposing (Array)
import Compiler.AST.Snippet as Snippet
import Compiler.AST.Source as Src
import Compiler.Reporting.Annotation as A
import Dict exposing (Dict)
import Kg.Facts exposing (ConfigFlag)


flags : String -> Src.ModuleData -> List ConfigFlag
flags text data =
    let
        lines =
            Array.fromList (String.lines text)

        slice region =
            sliceRegion lines region |> String.words |> String.join " "

        docs : Dict String String
        docs =
            (case data.docs of
                Src.YesDocs _ ds ->
                    ds

                Src.NoDocs _ ds ->
                    ds
            )
                |> List.map (\( n, Src.Comment (Snippet.Snippet s) ) -> ( n, String.slice s.offset (s.offset + s.length) s.fptr ))
                |> Dict.fromList

        records : Dict String (List ( String, String ))
        records =
            data.aliases
                |> List.filterMap
                    (\(A.At _ (Src.Alias a)) ->
                        let
                            ( _, A.At _ name ) =
                                a.name
                        in
                        case Src.c1Value a.tipe of
                            A.At _ (Src.TRecord fields _ _) ->
                                Just
                                    ( name
                                    , fields |> List.map (\( _, ( ( _, A.At _ f ), ( _, A.At r _ ) ) ) -> ( f, slice r ))
                                    )

                            _ ->
                                Nothing
                    )
                |> Dict.fromList

        values : Dict String Src.Expr
        values =
            data.values
                |> List.map (\(A.At _ (Src.Value v)) -> ( Src.c1Value v.name |> A.toValue, Src.c1Value v.body ))
                |> Dict.fromList

        recordFields : Src.Expr -> Maybe (Dict String Src.Expr)
        recordFields expr =
            case expr of
                A.At _ (Src.Record ( _, fs )) ->
                    Just (fs |> List.map (\( _, ( ( _, A.At _ f ), ( _, e ) ) ) -> ( f, e )) |> Dict.fromList)

                A.At _ (Src.Var _ name) ->
                    Dict.get name values |> Maybe.andThen recordFields

                A.At _ (Src.Parens ( _, e )) ->
                    recordFields e

                _ ->
                    Nothing

        exprText (A.At r _) =
            slice r

        docFor recordName field =
            Dict.get recordName docs
                |> Maybe.andThen (paragraphNaming field)
                |> Maybe.withDefault ""

        expand depth recordName path defaults =
            Dict.get recordName records
                |> Maybe.withDefault []
                |> List.concatMap
                    (\( field, typeText ) ->
                        let
                            here =
                                path ++ [ field ]

                            defaultExpr =
                                defaults |> Maybe.andThen (Dict.get field)
                        in
                        if Dict.member typeText records && depth < 6 then
                            expand (depth + 1) typeText here (defaultExpr |> Maybe.andThen recordFields)

                        else
                            [ { path = here
                              , typeName = typeText
                              , default = defaultExpr |> Maybe.map exprText |> Maybe.withDefault ""
                              , doc = docFor recordName field
                              }
                            ]
                    )
    in
    expand 0 "EcoConfig" [] (Dict.get "default" values |> Maybe.andThen recordFields)


{-| The first paragraph of a doc comment that names the field in backticks. -}
paragraphNaming : String -> String -> Maybe String
paragraphNaming field doc =
    doc
        |> String.split "\n\n"
        |> List.filter (String.contains ("`" ++ field ++ "`"))
        |> List.head
        |> Maybe.map (String.words >> String.join " ")


sliceRegion : Array String -> A.Region -> String
sliceRegion lines (A.Region (A.Position r1 c1) (A.Position r2 c2)) =
    if r1 == r2 then
        Array.get (r1 - 1) lines |> Maybe.withDefault "" |> String.slice (c1 - 1) (c2 - 1)

    else
        let
            first =
                Array.get (r1 - 1) lines |> Maybe.withDefault "" |> String.dropLeft (c1 - 1)

            middle =
                List.range r1 (r2 - 2) |> List.filterMap (\r -> Array.get r lines)

            last =
                Array.get (r2 - 1) lines |> Maybe.withDefault "" |> String.left (c2 - 1)
        in
        String.join "\n" (first :: middle ++ [ last ])
