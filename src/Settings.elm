module Settings exposing
    ( author
    , canonicalUrl
    , locale
    , subtitle
    , title
    , version
    )

import LanguageTag.Language as Language
import LanguageTag.Region as Region


canonicalUrl : String
canonicalUrl =
    "https://eco-lang.org"


locale : Maybe ( Language.Language, Region.Region )
locale =
    Just ( Language.en, Region.us )


title : String
title =
    "eco"


subtitle : String
subtitle =
    "Elm Compiler Optimized"


author : String
author =
    "eco Team"


{-| The current release, shown in the site header and footer.
-}
version : String
version =
    "0.2.0"
