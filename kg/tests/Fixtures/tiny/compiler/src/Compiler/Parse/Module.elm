module Compiler.Parse.Module exposing (parse)

{-| Parses a module. -}

import Compiler.Data.Name as Name exposing (Name)
import Eco.Kernel.File


{-| Parses. -}
parse : String -> Name
parse text =
    Name.fromString text
