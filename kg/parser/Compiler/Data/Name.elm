module Compiler.Data.Name exposing
    ( Name
    , toChars
    , fromPtr, fromWords
    
    , isKernel
    
    , int, float, bool, char, string, maybe, result, list, array, dict, bytes, tuple, json, task, cmd, sub
    , platform, virtualDom, shader, debug, basics
    , negate, true, false, value, node, program, mainModule
    )

{-| Every identifier the compiler handles is a `Name`, and this module holds the
rules that are carried in how a name is spelled.

A `Name` is the text of an identifier: a value, type, constructor, record
field, type variable or module, spelled as in source or as the compiler makes
it up. A module name keeps its dots, as in `Elm.Kernel.List`.

Three spelling rules matter outside this module.

A _kernel module_ is one whose name starts with `Elm.Kernel.` or `Eco.Kernel.`
and whose implementation is not written in Elm. The part before `.Kernel.`,
`Elm` or `Eco`, is its _kernel prefix_. `isKernel` recognises these names and
`getKernel` splits one into its prefix and the rest.

A type variable's constraint is written in its name. A variable whose name
starts with `number`, `comparable`, `appendable` or `compappend` is
_super-constrained_: it can stand only for a type of that class. The test is a
prefix match, so `number2` and `comparableKey` are constrained too.

A name the compiler makes up must not clash with one from source. The parser
never starts an identifier or an operator with `_`, so `fromVarIndex` and
`fromManyNames` start their names with it. `fromTypeVariable` and
`fromTypeVariableScheme` make ordinary-looking names, and nothing here checks
them against names already in use.

Besides a few conversion and splitting helpers, the rest of the module is
constants for names the compiler has to recognise or produce. Each is only
text, so one constant can name several things: `maybe` is both the module
`Maybe` and its type.


# Core Type

@docs Name


# Conversion

@docs toChars


# Construction

@docs fromPtr, fromWords


# Name Analysis


# Kernel Module Utilities

@docs isKernel


# Type Constraint Prefixes


# Names of Common Types and Modules

@docs int, float, bool, char, string, maybe, result, list, array, dict, bytes, tuple, json, task, cmd, sub


# Names of Other Modules, Kernel Modules and Types

@docs platform, virtualDom, shader, debug, basics


# Special Names

@docs negate, true, false, value, node, program, mainModule

-}


-- ====== NAME ======


{-| The text of an identifier, spelled as in source or as the compiler makes it
up.

This is a name for `String`, not a new type. Any `String` is accepted where a
`Name` is expected, so the compiler cannot tell a value name from a module
name, or a qualified name from a bare one.

-}
type alias Name =
    String


-- ====== TO ======


{-| Returns the characters of a name, first to last.
-}
toChars : Name -> List Char
toChars =
    String.toList


-- ====== FROM ======


{-| Returns the part of `src` from index `start` up to, but not including, index
`end`, counted as `String.slice` counts them.
-}
fromPtr : String -> Int -> Int -> Name
fromPtr src start end =
    String.slice start end src


-- ====== HAS DOT ======


-- ====== GET KERNEL ======


-- ====== STARTS WITH ======


{-| Tells whether the name is that of a kernel module: one that starts with
`Elm.Kernel.` or `Eco.Kernel.`.
-}
isKernel : Name -> Bool
isKernel name =
    String.startsWith prefixKernel name || String.startsWith prefixEcoKernel name


{-| The start of the name of every kernel module whose kernel prefix is `Elm`.
-}
prefixKernel : Name
prefixKernel =
    "Elm.Kernel."


{-| The start of the name of every kernel module whose kernel prefix is `Eco`.
-}
prefixEcoKernel : Name
prefixEcoKernel =
    "Eco.Kernel."


-- ====== FROM VAR INDEX ======


-- ====== FROM TYPE VARIABLE ======


-- ====== FROM TYPE VARIABLE SCHEME ======


-- ====== FROM MANY NAMES ======


{-| The start of every name `fromManyNames` makes. The parser never starts a name
with `_`, so no name from source begins this way.
-}
blank : Name
blank =
    "_M$"


-- ====== FROM WORDS ======


{-| Returns the name spelled by the characters, in order.
-}
fromWords : List Char -> Name
fromWords words =
    String.fromList words


-- ====== SEP BY ======


-- ====== COMMON NAMES ======


{-| The name of the type `Int`.
-}
int : Name
int =
    "Int"


{-| The name of the type `Float`.
-}
float : Name
float =
    "Float"


{-| The name of the type `Bool`.
-}
bool : Name
bool =
    "Bool"


{-| The name `Char`, of both the module and its type.
-}
char : Name
char =
    "Char"


{-| The name `String`, of both the module and its type.
-}
string : Name
string =
    "String"


{-| The name `Maybe`, of both the module and its type.
-}
maybe : Name
maybe =
    "Maybe"


{-| The name `Result`, of both the module and its type.
-}
result : Name
result =
    "Result"


{-| The name `List`: of the module and its type, and of the kernel module
`Elm.Kernel.List` without its `Elm.Kernel.` part.
-}
list : Name
list =
    "List"


{-| The name `Array`, of both the module and its type.
-}
array : Name
array =
    "Array"


{-| The name of the module `Dict`.
-}
dict : Name
dict =
    "Dict"


{-| The name of the type `Bytes`.
-}
bytes : Name
bytes =
    "Bytes"


{-| The name of the module `Tuple`.
-}
tuple : Name
tuple =
    "Tuple"


{-| The name of the kernel module `Elm.Kernel.Json`, without its `Elm.Kernel.`
part.
-}
json : Name
json =
    "Json"


{-| The name of the type `Task`.
-}
task : Name
task =
    "Task"


{-| The name `Cmd`, of the type and of the alias `Platform.Cmd` is imported under
by default.
-}
cmd : Name
cmd =
    "Cmd"


{-| The name `Sub`, of the type and of the alias `Platform.Sub` is imported under
by default.
-}
sub : Name
sub =
    "Sub"


{-| The name `Platform`: of the module, and of the kernel module
`Elm.Kernel.Platform` without its `Elm.Kernel.` part.
-}
platform : Name
platform =
    "Platform"


{-| The name `VirtualDom`: of the module, and of the kernel module
`Elm.Kernel.VirtualDom` without its `Elm.Kernel.` part.
-}
virtualDom : Name
virtualDom =
    "VirtualDom"


{-| The name of the type `Shader`, the type of a GLSL shader literal.
-}
shader : Name
shader =
    "Shader"


{-| The name `Debug`: of the module, and of the kernel module `Elm.Kernel.Debug`
without its `Elm.Kernel.` part.
-}
debug : Name
debug =
    "Debug"


{-| The name of the module `Basics`.
-}
basics : Name
basics =
    "Basics"


{-| The name of the function `negate`.
-}
negate : Name
negate =
    "negate"


{-| The name of the constructor `True`.
-}
true : Name
true =
    "True"


{-| The name of the constructor `False`.
-}
false : Name
false =
    "False"


{-| The name of the type `Value`, as in `Json.Encode.Value`.
-}
value : Name
value =
    "Value"


{-| The name of the type `Node`, as in `VirtualDom.Node`.
-}
node : Name
node =
    "Node"


{-| The name of the type `Program`.
-}
program : Name
program =
    "Program"


{-| The name `Main`, given to a module whose source has no `module` line.
-}
mainModule : Name
mainModule =
    "Main"


