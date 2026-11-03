module Compiler.Data.Name exposing (Name, fromString)

{-| Names. -}


type alias Name =
    String


fromString : String -> Name
fromString s =
    """
import Compiler.Parse.Module
""" ++ s
