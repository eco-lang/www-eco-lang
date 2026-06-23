module Settings exposing
    ( author
    , canonicalUrl
    , locale
    , subtitle
    , title
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
