module Layout.About exposing (seoHeaders, view)

import Content.About exposing (Author)
import Head
import Head.Seo as Seo
import Html exposing (Html)
import Html.Attributes as Attrs
import Html.Extra
import Layout.Markdown
import MimeType
import Layout.Site
import Pages.Url
import Settings
import Style
import Svg
import Svg.Attributes as SvgAttrs
import UrlPath


seoHeaders : Author -> List Head.Tag
seoHeaders author =
    let
        imageUrl =
            author.avatar
                |> Maybe.map (\authorAvatar -> Pages.Url.fromPath <| UrlPath.fromString authorAvatar)
                |> Maybe.withDefault
                    ([ "images", "site-image.png" ] |> UrlPath.join |> Pages.Url.fromPath)
    in
    Seo.summary
        { canonicalUrlOverride = Just Settings.canonicalUrl
        , siteName = Settings.title
        , image =
            { url = imageUrl
            , alt = author.name
            , dimensions = Just { width = 300, height = 300 }
            , mimeType = Just (MimeType.Image MimeType.Png)
            }
        , description = author.name ++ " - " ++ (author.occupation |> Maybe.withDefault ("Author of " ++ Settings.title))
        , locale = Settings.locale
        , title = author.name
        }
        |> Seo.website


view : Author -> List (Html msg)
view author =
    [ Html.div
        [ Attrs.class "min-h-screen flex flex-col eco-page"
        ]
        [ Style.styleNode
        , Layout.Site.viewHeader (Just Layout.Site.About)
        , Html.div
            [ Attrs.class "eco-about-container"
            ]
            [ Html.h1
                [ Attrs.class "eco-about-title"
                ]
                [ Html.text "About" ]
            , Html.div
                [ Attrs.class "eco-about-divider"
                ]
                []
            , Html.div
                [ Attrs.class "eco-about-layout flex-col md:flex-row"
                ]
                [ viewProfileCard author
                , viewBioContent author
                ]
            ]
        , Layout.Site.viewFooterDivider
        , Layout.Site.viewFooter
        ]
    ]


viewProfileCard : Author -> Html msg
viewProfileCard author =
    Html.div
        [ Attrs.class "eco-profile-card self-center md:self-start"
        ]
        [ Html.div
            [ Attrs.class "eco-avatar"
            ]
            [ Html.img
                [ Attrs.src "/images/authors/default.png"
                , Attrs.alt author.name
                , Attrs.attribute "loading" "lazy"
                , Attrs.class "eco-avatar-img"
                ]
                []
            ]
        , Html.div
            [ Attrs.class "eco-profile-name"
            ]
            [ Html.text author.name ]
        , Html.Extra.viewMaybe
            (\occupation ->
                Html.div
                    [ Attrs.class "eco-profile-occupation"
                    ]
                    [ Html.text occupation ]
            )
            author.occupation
        , Html.Extra.viewMaybe
            (\company ->
                Html.div
                    [ Attrs.class "eco-profile-company"
                    ]
                    [ Html.text company ]
            )
            author.company
        , Html.div
            [ Attrs.class "eco-profile-accent"
            ]
            []
        , viewSocials author.socials
        ]


viewSocials : List ( String, String ) -> Html msg
viewSocials socials =
    let
        socialLink name link =
            if name == "email" then
                "mailto:" ++ link

            else
                link

        viewSocialIcon ( name, link ) =
            Html.a
                [ Attrs.href (socialLink name link)
                , Attrs.target "_blank"
                , Attrs.rel "noopener noreferrer"
                , Attrs.class "eco-social-link"
                ]
                [ Html.span [ Attrs.class "sr-only" ] [ Html.text name ]
                , socialIcon name
                ]
    in
    Html.div
        [ Attrs.class "eco-socials"
        ]
        (List.filterMap
            (\( name, link ) ->
                if List.member name [ "email", "twitter", "github", "linkedin", "youtube" ] then
                    Just (viewSocialIcon ( name, link ))

                else
                    Nothing
            )
            socials
        )


socialIcon : String -> Html msg
socialIcon name =
    let
        attrs =
            [ SvgAttrs.width "18"
            , SvgAttrs.height "18"
            , SvgAttrs.viewBox "0 0 24 24"
            , SvgAttrs.fill "none"
            , SvgAttrs.stroke "currentColor"
            , SvgAttrs.strokeWidth "1.5"
            , SvgAttrs.strokeLinecap "round"
            , SvgAttrs.strokeLinejoin "round"
            ]
    in
    case name of
        "email" ->
            Svg.svg attrs
                [ Svg.rect [ SvgAttrs.x "2", SvgAttrs.y "4", SvgAttrs.width "20", SvgAttrs.height "16", SvgAttrs.rx "2" ] []
                , Svg.path [ SvgAttrs.d "m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7" ] []
                ]

        "twitter" ->
            Svg.svg attrs
                [ Svg.path [ SvgAttrs.d "M22 4s-.7 2.1-2 3.4c1.6 10-9.4 17.3-18 11.6 2.2.1 4.4-.6 6-2C3 15.5.5 9.6 3 5c2.2 2.6 5.6 4.1 9 4-.9-4.2 4-6.6 7-3.8 1.1 0 3-1.2 3-1.2z" ] []
                ]

        "github" ->
            Svg.svg attrs
                [ Svg.path [ SvgAttrs.d "M9 19c-5 1.5-5-2.5-7-3m14 6v-3.87a3.37 3.37 0 0 0-.94-2.61c3.14-.35 6.44-1.54 6.44-7A5.44 5.44 0 0 0 20 4.77 5.07 5.07 0 0 0 19.91 1S18.73.65 16 2.48a13.38 13.38 0 0 0-7 0C6.27.65 5.09 1 5.09 1A5.07 5.07 0 0 0 5 4.77a5.44 5.44 0 0 0-1.5 3.78c0 5.42 3.3 6.61 6.44 7A3.37 3.37 0 0 0 9 18.13V22" ] []
                ]

        "linkedin" ->
            Svg.svg attrs
                [ Svg.path [ SvgAttrs.d "M16 8a6 6 0 0 1 6 6v7h-4v-7a2 2 0 0 0-2-2 2 2 0 0 0-2 2v7h-4v-7a6 6 0 0 1 6-6z" ] []
                , Svg.rect [ SvgAttrs.x "2", SvgAttrs.y "9", SvgAttrs.width "4", SvgAttrs.height "12" ] []
                , Svg.circle [ SvgAttrs.cx "4", SvgAttrs.cy "4", SvgAttrs.r "2" ] []
                ]

        "youtube" ->
            Svg.svg attrs
                [ Svg.path [ SvgAttrs.d "M2.5 17a24.12 24.12 0 0 1 0-10 2 2 0 0 1 1.4-1.4 49.56 49.56 0 0 1 16.2 0A2 2 0 0 1 21.5 7a24.12 24.12 0 0 1 0 10 2 2 0 0 1-1.4 1.4 49.55 49.55 0 0 1-16.2 0A2 2 0 0 1 2.5 17" ] []
                , Svg.path [ SvgAttrs.d "m10 15 5-3-5-3z" ] []
                ]

        _ ->
            Svg.svg attrs
                [ Svg.path [ SvgAttrs.d "M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71" ] []
                , Svg.path [ SvgAttrs.d "M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71" ] []
                ]


viewBioContent : Author -> Html msg
viewBioContent author =
    Html.div
        [ Attrs.class "eco-bio-content"
        ]
        (Layout.Markdown.docsBlocksToHtml author.body)
