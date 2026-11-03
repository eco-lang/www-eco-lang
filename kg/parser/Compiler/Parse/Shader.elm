module Compiler.Parse.Shader exposing (shader)

{-| An Elm expression can embed a WebGL shader as a GLSL literal, written
`[glsl| ... |]`, and this module parses one.

The type checker gives a shader an Elm type built from its inputs, so the
parser has to look inside the GLSL rather than carry it as opaque text. The
literal is read in two steps. First the text between `[glsl|` and the first
`|]` after it is cut out as it stands, so a `|]` anywhere in the GLSL, even in a
GLSL comment, ends the literal. In the compiler, that text is then handed to the
GLSL parser of `Language.GLSL.Parser`, and the inputs are picked out of the
declarations it returns; kg's copy skips that step (see `parseGlsl`).

An input is recorded only when it is a top-level declaration of a single
name, qualified `attribute`, `uniform` or `varying`, with one of the types
`vec2`, `vec3`, `vec4`, `mat4`, `int`, `float`, `sampler2D` or `bool`. Every
other declaration is ignored, without error. What the three kinds of input
mean is stated in `Compiler.AST.Utils.Shader`.

A GLSL syntax error is reported as an Elm syntax error. The GLSL parser gives
only a character offset into the cut-out text, so this module turns that offset
back into a row and column in the Elm file.

@docs shader

-}

import Compiler.AST.Source as Src
import Compiler.AST.Utils.Shader as Shader
import Compiler.Parse.Primitives as P exposing (Col, Parser, Row)
import Compiler.Reporting.Annotation as A
import Compiler.Reporting.Error.Syntax as E
import Data.Map as Dict


-- ====== SHADER ======


{-| Parses a GLSL literal that begins at the current position, given that
position as `start`, and returns a `Src.Shader` expression located from `start`
to just after the closing `|]`.

The expression holds the text between the delimiters, escaped by
`Shader.fromString`, and the inputs found in it. Input that does not begin with
`[glsl|` fails without consuming anything, with `E.Start`. A literal with no
closing `|]` fails with `E.EndlessShader` at the opening `[`, and one whose
GLSL does not parse fails with `E.ShaderProblem`. When the same name is
declared twice with the same qualifier, the first declaration's type is kept.

-}
shader : A.Position -> Parser E.Expr Src.Expr
shader ((A.Position row col) as start) =
    parseBlock
        |> P.andThen
            (\block ->
                parseGlsl row col block
                    |> P.andThen
                        (\shdr ->
                            P.getPosition
                                |> P.map
                                    (\end ->
                                        A.at start end (Src.Shader (Shader.fromString block) shdr)
                                    )
                        )
            )


-- ====== BLOCK ======


{-| A parser for the delimiters of a GLSL literal, producing the raw text
between `[glsl|` and the first `|]`, which is consumed too.
-}
parseBlock : Parser E.Expr String
parseBlock =
    P.Parser <|
        \(P.State st) ->
            let
                pos6 : Int
                pos6 =
                    st.pos + 6
            in
            if
                (pos6 <= st.end)
                    && (P.unsafeIndex st.src st.pos == '[')
                    && (P.unsafeIndex st.src (st.pos + 1) == 'g')
                    && (P.unsafeIndex st.src (st.pos + 2) == 'l')
                    && (P.unsafeIndex st.src (st.pos + 3) == 's')
                    && (P.unsafeIndex st.src (st.pos + 4) == 'l')
                    && (P.unsafeIndex st.src (st.pos + 5) == '|')
            then
                let
                    ( ( status, newPos ), ( newRow, newCol ) ) =
                        eatShader st.src pos6 st.end st.row (st.col + 6)
                in
                case status of
                    Good ->
                        let
                            off : Int
                            off =
                                pos6

                            len : Int
                            len =
                                newPos - pos6

                            block : String
                            block =
                                String.left len (String.dropLeft off st.src)

                            newState : P.State
                            newState =
                                P.State { st | pos = newPos + 2, row = newRow, col = newCol + 2 }
                        in
                        P.Cok block newState

                    Unending ->
                        P.Cerr st.row st.col E.EndlessShader

            else
                P.Eerr st.row st.col E.Start


{-| Whether `eatShader` found the end of a GLSL literal: `Good` when it reached
a `|]`, and `Unending` when the input ran out first.
-}
type Status
    = Good
    | Unending


{-| Scans the source from `pos` for the first `|]`, tracking the row and
column as it goes, and returns whether one was found, the position where
the scan stopped (the `|` of the `|]` when one was found), and the row and
column of that point.
-}
eatShader : String -> Int -> Int -> Row -> Col -> ( ( Status, Int ), ( Row, Col ) )
eatShader src pos end row col =
    if pos >= end then
        ( ( Unending, pos ), ( row, col ) )

    else
        let
            word : Char
            word =
                P.unsafeIndex src pos
        in
        if word == '|' && P.isWord src (pos + 1) end ']' then
            ( ( Good, pos ), ( row, col ) )

        else if word == '\n' then
            eatShader src (pos + 1) end (row + 1) 1

        else
            let
                newPos : Int
                newPos =
                    pos + P.charWidthAt src pos end word
            in
            eatShader src newPos end row (col + 1)


-- ====== GLSL ======


{-| The shader's inputs. kg's copy does not parse the GLSL: kg needs nothing
from inside a shader, and the GLSL parser package crashes under eco 0.2.0
(eco-bugs.md). Every shader is taken to declare no inputs, and no GLSL
error is reported.
-}
parseGlsl : Row -> Col -> String -> Parser E.Expr Shader.Types
parseGlsl _ _ _ =
    P.pure emptyTypes


-- ====== INPUTS ======


{-| The inputs of a shader that declares none.
-}
emptyTypes : Shader.Types
emptyTypes =
    Shader.Types Dict.empty Dict.empty Dict.empty


