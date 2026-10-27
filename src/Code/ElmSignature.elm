module Code.ElmSignature exposing
    ( Line, Piece(..)
    , value, union, alias, binop
    )

{-| Elm declarations printed as package.elm-lang.org prints them, ready to render as lines of code.

Each type name is printed unqualified (`Path` for `Path.Path`), with the qualified name kept so the caller can link it.
A signature longer than `maxWidth` is broken after its name, with one argument per line, and a record too long for its
line is broken into one field per line, as elm-format lays them out.

@docs Line, Piece
@docs value, union, alias, binop

-}

import Elm.Type exposing (Type(..))


{-| One line of a printed declaration.
-}
type alias Line =
    List Piece


{-| A piece of a line. `Name` is the declared name, `Keyword` is syntax (`type`, `:`, `->`, `|`), `TypeRef` is a type
name with its qualified form (`Path.Path`), and `Text` is anything else: type variables, field names, brackets.
-}
type Piece
    = Name String
    | Keyword String
    | TypeRef { label : String, qualified : String }
    | Text String


maxWidth : Int
maxWidth =
    72


indent : String
indent =
    "    "



-- DECLARATIONS


{-| `name : type`, broken over lines when too long.
-}
value : String -> Type -> List Line
value name tipe =
    let
        oneLine =
            [ Name name, Keyword " : " ] ++ inline Top tipe
    in
    if width oneLine <= maxWidth then
        [ oneLine ]

    else
        [ Name name, Keyword " :" ]
            :: List.concat
                (List.indexedMap
                    (\index arg ->
                        if index == 0 then
                            block [ Text indent ] arg

                        else
                            block [ Text indent, Keyword "-> " ] arg
                    )
                    (arrowParts tipe)
                )


{-| An operator: `(op) : type`.
-}
binop : String -> Type -> List Line
binop name tipe =
    value ("(" ++ name ++ ")") tipe


{-| `type Name args`, then each tag on its own line.
-}
union : String -> { a | args : List String, tags : List ( String, List Type ) } -> List Line
union name { args, tags } =
    (Keyword "type " :: Name name :: List.map (\arg -> Text (" " ++ arg)) args)
        :: List.indexedMap
            (\index ( tag, tagArgs ) ->
                Text indent
                    :: Keyword
                        (if index == 0 then
                            "= "

                         else
                            "| "
                        )
                    :: Text tag
                    :: List.concatMap (\arg -> Text " " :: inline Arg arg) tagArgs
            )
            tags


{-| `type alias Name args =`, then the aliased type on the lines below.
-}
alias : String -> { a | args : List String, tipe : Type } -> List Line
alias name { args, tipe } =
    (Keyword "type alias " :: Name name :: List.map (\arg -> Text (" " ++ arg)) args ++ [ Keyword " =" ])
        :: block [ Text indent ] tipe



-- LAYOUT


{-| A type after a prefix: on one line if it fits, and otherwise, for a record, one field per line, aligned under
the prefix's end.
-}
block : Line -> Type -> List Line
block prefix tipe =
    let
        oneLine =
            prefix ++ inline Top tipe
    in
    if width oneLine <= maxWidth then
        [ oneLine ]

    else
        case tipe of
            Record ((_ :: _) as fields) extension ->
                let
                    pad =
                        Text (String.repeat (width prefix) " ")

                    fieldLine index ( field, fieldType ) =
                        let
                            opener =
                                case ( index, extension ) of
                                    ( 0, Nothing ) ->
                                        [ Text "{ " ]

                                    ( 0, Just ext ) ->
                                        [ Text ("{ " ++ ext), Keyword " | " ]

                                    _ ->
                                        [ pad, Text ", " ]

                            start =
                                if index == 0 then
                                    prefix ++ opener

                                else
                                    opener
                        in
                        start ++ [ Text field, Keyword " : " ] ++ inline Top fieldType
                in
                List.indexedMap fieldLine fields ++ [ [ pad, Text "}" ] ]

            _ ->
                [ oneLine ]


{-| The arguments and result of a function type: `a -> b -> c` is `[ a, b, c ]`.
-}
arrowParts : Type -> List Type
arrowParts tipe =
    case tipe of
        Lambda arg result ->
            arg :: arrowParts result

        _ ->
            [ tipe ]


width : Line -> Int
width line =
    List.sum (List.map pieceWidth line)


pieceWidth : Piece -> Int
pieceWidth piece =
    case piece of
        Name text ->
            String.length text

        Keyword text ->
            String.length text

        TypeRef { label } ->
            String.length label

        Text text ->
            String.length text



-- ONE LINE


{-| Where a type appears, which decides whether it needs brackets: at the top, as the left side of an arrow, or as
an argument of a type.
-}
type Context
    = Top
    | ArrowLeft
    | Arg


inline : Context -> Type -> Line
inline context tipe =
    case tipe of
        Var name ->
            [ Text name ]

        Lambda _ _ ->
            let
                pieces =
                    List.intersperse [ Keyword " -> " ]
                        (List.map
                            (\( index, part ) ->
                                if index == List.length (arrowParts tipe) - 1 then
                                    inline Top part

                                else
                                    inline ArrowLeft part
                            )
                            (List.indexedMap Tuple.pair (arrowParts tipe))
                        )
                        |> List.concat
            in
            if context == Top then
                pieces

            else
                parens pieces

        Tuple [] ->
            [ Text "()" ]

        Tuple types ->
            Text "( "
                :: (List.map (inline Top) types |> List.intersperse [ Text ", " ] |> List.concat)
                ++ [ Text " )" ]

        Type qualified [] ->
            [ typeRef qualified ]

        Type qualified args ->
            let
                pieces =
                    typeRef qualified :: List.concatMap (\arg -> Text " " :: inline Arg arg) args
            in
            if context == Arg then
                parens pieces

            else
                pieces

        Record [] Nothing ->
            [ Text "{}" ]

        Record fields extension ->
            let
                fieldPieces =
                    List.map (\( field, fieldType ) -> Text field :: Keyword " : " :: inline Top fieldType) fields
                        |> List.intersperse [ Text ", " ]
                        |> List.concat
            in
            case extension of
                Nothing ->
                    Text "{ " :: fieldPieces ++ [ Text " }" ]

                Just ext ->
                    Text ("{ " ++ ext) :: Keyword " | " :: fieldPieces ++ [ Text " }" ]


parens : Line -> Line
parens pieces =
    Text "(" :: pieces ++ [ Text ")" ]


typeRef : String -> Piece
typeRef qualified =
    TypeRef
        { label =
            String.split "." qualified
                |> List.reverse
                |> List.head
                |> Maybe.withDefault qualified
        , qualified = qualified
        }
