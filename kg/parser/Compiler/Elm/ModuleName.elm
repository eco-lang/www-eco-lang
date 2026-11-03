module Compiler.Elm.ModuleName exposing
    ( Raw
    
    
    
    , basics, char, string, maybe, result, list, array, dict, tuple, platform, cmd, sub, debug
    , virtualDom
    
    , bytes
    , webgl
    
    
    
    , Canonical(..)
    )

{-| A module is known by two names, and this module defines both.

A _raw_ module name is the name as Elm source writes it: upper-case
identifiers joined by dots, such as `Dict` or `Html.Attributes`, with
identifiers as `Compiler.Parse.Variable` defines them. A raw name does not say
which package the module comes from, and two packages may each have a module
with the same raw name. A _canonical_ module name pairs the raw name with the
package the module belongs to, such as `List` in `elm/core`, and so tells
those modules apart.

The rest of the file serves the two types: turning a raw name into a path,
reading and writing raw names as JSON and either kind as binary, ordering
canonical names, and constants naming particular modules of `elm/core`,
`elm/virtual-dom`, `elm/json`, `elm/bytes`, `elm-explorations/webgl` and
`elm-explorations/linear-algebra`.


# Types

@docs Raw


# Path Conversion


# JSON Encoding/Decoding


# Canonical Module Names


# Core Modules

@docs basics, char, string, maybe, result, list, array, dict, tuple, platform, cmd, sub, debug


# HTML Modules

@docs virtualDom


# JSON Modules


# Bytes Modules

@docs bytes


# WebGL Modules

@docs webgl


# Binary Encoding/Decoding


# String-Interned Binary Encoding/Decoding


@docs Canonical

-}

import Compiler.Data.Name as Name exposing (Name)
import Compiler.Elm.Package as Pkg
import Compiler.Parse.Primitives as P
import Compiler.Parse.Variable as Var


-- ====== RAW ======


{-| A module name as written in Elm source, such as `Html.Attributes`.

This is a name for `Name`, which is a `String`, not a new type. Any string is
accepted where a `Raw` is expected; of this module's exposed values, only
`decoder` checks that it is a valid module name.

-}
type alias Raw =
    Name


{-| The full name of a module: the package it belongs to and its raw name
within that package, such as `List` in `elm/core`.

The package is a `Compiler.Elm.Package.Name`, author then project. The
constructor is exposed and checks nothing, so any strings make a `Canonical`.

-}
type Canonical
    = Canonical ( String, String ) String


-- ====== JSON ======


-- ====== PARSER ======


{-| A parser for a raw module name at the current position, giving its text.

It reads upper-case identifiers joined by dots, and stops before the first
character that can neither continue an identifier nor be a dot. It fails, with
the row and column where reading stopped, in three cases: there is no
upper-case identifier at the start, which is reported as consuming nothing; a
dot is not followed by one; or the name takes 256 or more units of position.
The last two are reported as having consumed input.

-}
parser : P.Parser ( Int, Int ) Raw
parser =
    P.Parser
        (\(P.State st) ->
            let
                ( isGood, newPos, newCol ) =
                    chompStart st.src st.pos st.end st.col
            in
            if isGood && (newPos - st.pos) < 256 then
                let
                    newState : P.State
                    newState =
                        P.State { st | pos = newPos, col = newCol }
                in
                P.Cok (String.slice st.pos newPos st.src) newState

            else if st.col == newCol then
                P.Eerr st.row newCol Tuple.pair

            else
                P.Cerr st.row newCol Tuple.pair
        )


{-| Reads the upper-case identifier that must begin at `pos`, and the rest of
the name after it with `chompInner`.

Returns whether the name read is valid, with the position and column reached.
With no upper-case character at `pos` the result is `( False, pos, col )`.

-}
chompStart : String -> Int -> Int -> Int -> ( Bool, Int, Int )
chompStart src pos end col =
    let
        width : Int
        width =
            Var.getUpperWidth src pos end
    in
    if width == 0 then
        ( False, pos, col )

    else
        chompInner src (pos + width) end (col + 1)


{-| Reads the rest of a module name from `pos`, which follows at least one
character of an identifier.

Inner characters continue the identifier, and a dot hands over to
`chompStart` for the next one, whose result is returned. Otherwise the result
is `True` with the position and column of the first character that is neither,
or of `end`.

-}
chompInner : String -> Int -> Int -> Int -> ( Bool, Int, Int )
chompInner src pos end col =
    if pos >= end then
        ( True, pos, col )

    else
        let
            word : Char
            word =
                P.unsafeIndex src pos

            width : Int
            width =
                Var.getInnerWidthHelp src pos end word
        in
        if width == 0 then
            if word == '.' then
                chompStart src (pos + 1) end (col + 1)

            else
                ( True, pos, col )

        else
            chompInner src (pos + width) end (col + 1)


-- ====== INSTANCES ======


-- ====== CORE ======


{-| The canonical name of `Basics` in `elm/core`.
-}
basics : Canonical
basics =
    Canonical Pkg.core Name.basics


{-| The canonical name of `Char` in `elm/core`.
-}
char : Canonical
char =
    Canonical Pkg.core Name.char


{-| The canonical name of `String` in `elm/core`.
-}
string : Canonical
string =
    Canonical Pkg.core Name.string


{-| The canonical name of `Maybe` in `elm/core`.
-}
maybe : Canonical
maybe =
    Canonical Pkg.core Name.maybe


{-| The canonical name of `Result` in `elm/core`.
-}
result : Canonical
result =
    Canonical Pkg.core Name.result


{-| The canonical name of `List` in `elm/core`.
-}
list : Canonical
list =
    Canonical Pkg.core Name.list


{-| The canonical name of `Array` in `elm/core`.
-}
array : Canonical
array =
    Canonical Pkg.core Name.array


{-| The canonical name of `Dict` in `elm/core`.
-}
dict : Canonical
dict =
    Canonical Pkg.core Name.dict


{-| The canonical name of `Tuple` in `elm/core`.
-}
tuple : Canonical
tuple =
    Canonical Pkg.core Name.tuple


{-| The canonical name of `Platform` in `elm/core`.
-}
platform : Canonical
platform =
    Canonical Pkg.core Name.platform


{-| The canonical name of `Platform.Cmd` in `elm/core`.
-}
cmd : Canonical
cmd =
    Canonical Pkg.core "Platform.Cmd"


{-| The canonical name of `Platform.Sub` in `elm/core`.
-}
sub : Canonical
sub =
    Canonical Pkg.core "Platform.Sub"


{-| The canonical name of `Debug` in `elm/core`.
-}
debug : Canonical
debug =
    Canonical Pkg.core Name.debug


-- ====== HTML ======


{-| The canonical name of `VirtualDom` in `elm/virtual-dom`.
-}
virtualDom : Canonical
virtualDom =
    Canonical Pkg.virtualDom Name.virtualDom


-- ====== JSON ======


-- ====== BYTES ======


{-| The canonical name of `Bytes` in `elm/bytes`.
-}
bytes : Canonical
bytes =
    Canonical Pkg.bytes "Bytes"


-- ====== WEBGL ======


{-| The canonical name of `WebGL` in `elm-explorations/webgl`.
-}
webgl : Canonical
webgl =
    Canonical Pkg.webgl "WebGL"


-- ====== ENCODERS and DECODERS ======


