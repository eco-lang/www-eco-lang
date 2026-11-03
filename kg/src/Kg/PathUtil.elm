module Kg.PathUtil exposing (normpath, join, dirname, basename, commonpathLength, stripExtension, extension, relativeTo)

{-| POSIX path arithmetic on strings, matching Python's `os.path` where the
extractor's port depends on it.
-}


{-| `os.path.normpath`: collapses `//`, `.` and `x/..`. A relative path keeps
leading `..` segments; the empty path is `.`.
-}
normpath : String -> String
normpath path =
    let
        absolute =
            String.startsWith "/" path

        step seg acc =
            if seg == "" || seg == "." then
                acc

            else if seg == ".." then
                case acc of
                    top :: rest ->
                        if top == ".." then
                            seg :: acc

                        else
                            rest

                    [] ->
                        if absolute then
                            []

                        else
                            [ seg ]

            else
                seg :: acc

        segs =
            List.foldl step [] (String.split "/" path) |> List.reverse

        joined =
            String.join "/" segs
    in
    if absolute then
        "/" ++ joined

    else if joined == "" then
        "."

    else
        joined


{-| `os.path.join` for two parts. -}
join : String -> String -> String
join a b =
    if String.startsWith "/" b || a == "" then
        b

    else if String.endsWith "/" a then
        a ++ b

    else
        a ++ "/" ++ b


{-| `os.path.dirname`: everything before the last `/`, or "". -}
dirname : String -> String
dirname path =
    case List.reverse (String.indexes "/" path) of
        i :: _ ->
            let
                d =
                    String.left i path
            in
            if d == "" then
                "/"

            else
                d

        [] ->
            ""


basename : String -> String
basename path =
    case List.reverse (String.split "/" path) of
        b :: _ ->
            b

        [] ->
            path


{-| The length of `os.path.commonpath([a, b])` for two relative paths. -}
commonpathLength : String -> String -> Int
commonpathLength a b =
    let
        go xs ys acc =
            case ( xs, ys ) of
                ( x :: xr, y :: yr ) ->
                    if x == y then
                        go xr yr (x :: acc)

                    else
                        acc

                _ ->
                    acc

        common =
            go (String.split "/" a |> List.filter ((/=) "")) (String.split "/" b |> List.filter ((/=) "")) []
    in
    String.length (String.join "/" (List.reverse common))


stripExtension : String -> String
stripExtension path =
    let
        base =
            basename path
    in
    case List.reverse (String.indexes "." base) of
        i :: _ ->
            if i > 0 then
                String.dropRight (String.length base - i) path

            else
                path

        [] ->
            path


extension : String -> String
extension path =
    let
        base =
            basename path
    in
    case List.reverse (String.indexes "." base) of
        i :: _ ->
            String.dropLeft i base

        [] ->
            ""


{-| `path` relative to `root` when it is inside it. -}
relativeTo : String -> String -> Maybe String
relativeTo root path =
    if path == root then
        Just ""

    else if String.startsWith (root ++ "/") path then
        Just (String.dropLeft (String.length root + 1) path)

    else
        Nothing
