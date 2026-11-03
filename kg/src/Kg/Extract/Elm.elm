module Kg.Extract.Elm exposing (extract, importNamesByRegex)

{-| Elm facts, from eco's own parser (§8.1 of the plan): the imports, the
module's doc, each declaration with its signature and doc, the qualified names
each declaration uses, and the record fields it reads.

A file the parser rejects falls back to the Python's regular expression, for
its imports only, and records the parse error.

-}

import Array exposing (Array)
import Compiler.AST.Snippet as Snippet
import Compiler.AST.Source as Src
import Compiler.Elm.Compiler.Imports as Imports
import Compiler.Parse.Module as M
import Compiler.Reporting.Annotation as A
import Dict exposing (Dict)
import Kg.Extract.Config as Config
import Kg.Facts as F exposing (Decl, DeclKind(..), ElmFacts, Exposing(..))
import Kg.PathUtil as P
import Kg.Re as Re exposing (Regex)
import Set exposing (Set)


importRe : Regex
importRe =
    Re.compileWith { caseInsensitive = False, multiline = True } "^import\\s+([A-Z][\\w.]*)"
        |> Maybe.withDefault (Re.unsafe "(?!)")


importNamesByRegex : String -> List String
importNamesByRegex text =
    Re.findAll importRe text |> List.filterMap (.groups >> List.head >> Maybe.andThen identity)


extract : String -> String -> ElmFacts
extract path text =
    case parse text of
        Ok (Src.Module data) ->
            fromModule path text data

        Err why ->
            let
                empty =
                    F.emptyElm (P.stripExtension (P.basename path))
            in
            { empty
                | imports = importNamesByRegex text |> List.map (\n -> { name = n, asName = Nothing, exposes = ExposeList [] })
                , parseError = Just why
            }


parse : String -> Result String Src.Module
parse text =
    case M.fromByteString M.Application text of
        Ok m ->
            Ok m

        Err _ ->
            case M.fromByteString (M.KernelApplication ( "eco", "kernel" )) text of
                Ok m ->
                    Ok m

                Err _ ->
                    Err "the parser rejected it"


commentText : Src.Comment -> String
commentText (Src.Comment (Snippet.Snippet s)) =
    String.slice s.offset (s.offset + s.length) s.fptr |> String.trim


rowOf : A.Region -> Int
rowOf (A.Region (A.Position row _) _) =
    row


fromModule : String -> String -> Src.ModuleData -> ElmFacts
fromModule path text data =
    let
        lines : Array String
        lines =
            Array.fromList (String.lines text)

        name =
            case data.name of
                Just (A.At _ n) ->
                    n

                Nothing ->
                    "Main"

        ( moduleDoc, declDocs ) =
            case data.docs of
                Src.YesDocs c ds ->
                    ( Just (commentText c), ds )

                Src.NoDocs _ ds ->
                    ( Nothing, ds )

        docOf : Dict String String
        docOf =
            List.foldl (\( n, c ) d -> Dict.insert n (commentText c) d) Dict.empty declDocs

        exposed : String -> Bool
        exposed =
            case data.exports of
                A.At _ (Src.Open _ _) ->
                    \_ -> True

                A.At _ (Src.Explicit (A.At _ items)) ->
                    let
                        names =
                            items |> List.map (Src.c2Value >> exposedName) |> Set.fromList
                    in
                    \n -> Set.member n names

        imports =
            data.imports
                |> List.drop (List.length Imports.defaults)
                |> List.map toImport

        slice region =
            sliceRegion lines region

        values =
            data.values
                |> List.reverse
                |> List.map
                    (\(A.At region (Src.Value v)) ->
                        let
                            (A.At _ n) =
                                Src.c1Value v.name
                        in
                        { name = n
                        , kind = Value
                        , signature =
                            v.tipe
                                |> Maybe.map (\( _, ( _, A.At r _ ) ) -> collapse (slice r))
                        , doc = Dict.get n docOf
                        , line = rowOf region
                        , exposed = exposed n
                        }
                    )

        unions =
            data.unions
                |> List.reverse
                |> List.map
                    (\(A.At region (Src.Union ( _, A.At _ n ) _ _)) ->
                        { name = n, kind = Union, signature = Just (collapse (slice region)), doc = Dict.get n docOf, line = rowOf region, exposed = exposed n }
                    )

        aliases =
            data.aliases
                |> List.reverse
                |> List.map
                    (\(A.At region (Src.Alias a)) ->
                        let
                            ( _, A.At _ n ) =
                                a.name
                        in
                        { name = n, kind = Alias, signature = Just (collapse (slice region)), doc = Dict.get n docOf, line = rowOf region, exposed = exposed n }
                    )

        ports =
            case data.effects of
                Src.Ports ps ->
                    ps
                        |> List.map
                            (\(Src.Port _ ( _, A.At r n ) (A.At tr _)) ->
                                { name = n, kind = Port, signature = Just (collapse (slice tr)), doc = Dict.get n docOf, line = rowOf r, exposed = exposed n }
                            )

                _ ->
                    []

        walked =
            data.values
                |> List.foldl
                    (\(A.At _ (Src.Value v)) acc ->
                        let
                            (A.At _ from) =
                                Src.c1Value v.name

                            fromBody =
                                walkExpr lines from (Src.c1Value v.body) acc

                            fromType =
                                case v.tipe of
                                    Just ( _, ( _, t ) ) ->
                                        walkType from t fromBody

                                    Nothing ->
                                        fromBody
                        in
                        fromType
                    )
                    { refs = [], fields = [] }

        typeRefs =
            (data.aliases
                |> List.concatMap (\(A.At _ (Src.Alias a)) -> walkType (Tuple.second a.name |> A.toValue) (Src.c1Value a.tipe) { refs = [], fields = [] } |> .refs)
            )
                ++ (data.unions
                        |> List.concatMap
                            (\(A.At _ (Src.Union ( _, A.At _ n ) _ ctors)) ->
                                ctors
                                    |> List.concatMap (\( _, ( _, args ) ) -> List.concatMap (\( _, t ) -> walkType n t { refs = [], fields = [] } |> .refs) args)
                            )
                   )
    in
    { moduleName = name
    , imports = imports
    , moduleDoc = moduleDoc
    , decls = values ++ unions ++ aliases ++ ports
    , references = List.reverse walked.refs ++ typeRefs
    , fieldReads = List.reverse walked.fields
    , config =
        if String.endsWith "Compiler/Eco/Config.elm" path then
            Config.flags text data

        else
            []
    , parseError = Nothing
    }


exposedName : Src.Exposed -> String
exposedName e =
    case e of
        Src.Lower (A.At _ n) ->
            n

        Src.Upper (A.At _ n) _ ->
            n

        Src.Operator _ n ->
            n


toImport : Src.Import -> F.ElmImport
toImport (Src.Import ( _, A.At _ n ) asName ( _, exp )) =
    { name = n
    , asName = Maybe.map Src.c2Value asName
    , exposes =
        case exp of
            Src.Open _ _ ->
                ExposeAll

            Src.Explicit (A.At _ items) ->
                ExposeList
                    (items
                        |> List.concatMap
                            (\( _, item ) ->
                                case item of
                                    Src.Upper (A.At _ u) ( _, Src.Public _ ) ->
                                        [ u, u ++ "(..)" ]

                                    _ ->
                                        [ exposedName item ]
                            )
                    )
    }


{-| The source text a region covers. Rows and columns count from 1. -}
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


collapse : String -> String
collapse s =
    String.words s |> String.join " "



-- WALKING EXPRESSIONS


type alias Walk =
    { refs : List F.Reference, fields : List F.FieldRead }


walkExpr : Array String -> String -> Src.Expr -> Walk -> Walk
walkExpr lines from (A.At region expr) acc =
    let
        go e a =
            walkExpr lines from e a

        line =
            rowOf region
    in
    case expr of
        Src.VarQual _ q n ->
            { acc | refs = { from = from, qualifier = q, name = n, line = line, isType = False } :: acc.refs }

        Src.Var _ n ->
            { acc | refs = { from = from, qualifier = "", name = n, line = line, isType = False } :: acc.refs }

        Src.List items _ ->
            List.foldl (\( _, e ) a -> go e a) acc items

        Src.Negate e ->
            go e acc

        Src.Binops pairs last ->
            List.foldl
                (\( e, ( _, A.At r op ) ) a -> go e { a | refs = { from = from, qualifier = "", name = op, line = rowOf r, isType = False } :: a.refs })
                acc
                pairs
                |> go last

        Src.Lambda _ ( _, body ) ->
            go body acc

        Src.Call f args ->
            List.foldl (\( _, e ) a -> go e a) (go f acc) args

        Src.If ( _, ( ( _, c ), ( _, t ) ) ) elseIfs ( _, otherwise ) ->
            List.foldl (\( _, ( ( _, c2 ), ( _, t2 ) ) ) a -> go t2 (go c2 a)) (go t (go c acc)) elseIfs
                |> go otherwise

        Src.Let defs _ body ->
            List.foldl
                (\( _, A.At _ def ) a ->
                    case def of
                        Src.Define _ _ ( _, e ) tipe ->
                            let
                                withBody =
                                    go e a
                            in
                            case tipe of
                                Just ( _, ( _, t ) ) ->
                                    walkType from t withBody

                                Nothing ->
                                    withBody

                        Src.Destruct _ ( _, e ) ->
                            go e a
                )
                acc
                defs
                |> go body

        Src.Case ( _, subject ) branches ->
            List.foldl (\( _, ( _, e ) ) a -> go e a) (go subject acc) branches

        Src.Accessor field ->
            { acc | fields = { from = from, field = field, line = line, text = lineText lines line } :: acc.fields }

        Src.Access e (A.At r field) ->
            go e { acc | fields = { from = from, field = field, line = rowOf r, text = lineText lines (rowOf r) } :: acc.fields }

        Src.Update ( _, e ) ( _, fields ) ->
            List.foldl (\( _, ( _, ( _, v ) ) ) a -> go v a) (go e acc) fields

        Src.Record ( _, fields ) ->
            List.foldl (\( _, ( _, ( _, v ) ) ) a -> go v a) acc fields

        Src.Tuple ( _, a1 ) ( _, b1 ) rest ->
            List.foldl (\( _, e ) a -> go e a) (go b1 (go a1 acc)) rest

        Src.Parens ( _, e ) ->
            go e acc

        _ ->
            acc


lineText : Array String -> Int -> String
lineText lines row =
    Array.get (row - 1) lines |> Maybe.withDefault "" |> String.trim |> String.left 200


walkType : String -> Src.Type -> Walk -> Walk
walkType from (A.At region tipe) acc =
    let
        go t a =
            walkType from t a

        line =
            rowOf region
    in
    case tipe of
        Src.TLambda ( _, a1 ) ( _, b1 ) ->
            go b1 (go a1 acc)

        Src.TType _ n args ->
            List.foldl (\( _, t ) a -> go t a) { acc | refs = { from = from, qualifier = "", name = n, line = line, isType = True } :: acc.refs } args

        Src.TTypeQual _ q n args ->
            List.foldl (\( _, t ) a -> go t a) { acc | refs = { from = from, qualifier = q, name = n, line = line, isType = True } :: acc.refs } args

        Src.TRecord fields _ _ ->
            List.foldl (\( _, ( _, ( _, t ) ) ) a -> go t a) acc fields

        Src.TTuple ( _, a1 ) ( _, b1 ) rest ->
            List.foldl (\( _, t ) a -> go t a) (go b1 (go a1 acc)) rest

        Src.TParens ( _, t ) ->
            go t acc

        _ ->
            acc
