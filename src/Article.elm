module Article exposing
    ( Article
    , ArticleError(..)
    , ArticleResult
    , Full
    , Preview
    , equals
    , fetchByTitle
    , fetchRandom
    , getContent
    , getLength
    , getLinks
    , getTitle
    , isDisambiguation
    , preview
    , viewAsLink
    , viewError
    )

import Css exposing (..)
import Html.Styled exposing (Html, a, span, text)
import Html.Styled.Attributes exposing (css, href)
import Http
import Json.Decode as Decode exposing (Decoder, at, bool, field, int, list, map, oneOf, string, succeed)
import Json.Decode.Pipeline exposing (custom, hardcoded, required, requiredAt)
import Url exposing (Url)
import Url.Builder as UrlBuilder exposing (QueryParameter)



-- TYPES


type Article a
    = Article Title a


type Preview
    = Preview


type Full
    = Full Body


type alias Body =
    { content : Wikitext
    , links : List (Article Preview)
    }


type alias Title =
    String


type alias Wikitext =
    String



-- INFO


getTitle : Article a -> String
getTitle (Article title _) =
    title


getContent : Article Full -> String
getContent (Article _ (Full { content })) =
    content


getLinks : Article Full -> List (Article Preview)
getLinks (Article _ (Full { links })) =
    links


getLength : Article Full -> Int
getLength =
    getContent >> String.length


isDisambiguation : Article Full -> Bool
isDisambiguation article =
    let
        doesArticleContain text =
            String.contains text (getContent article)
    in
    List.any doesArticleContain
        [ "disambiguation}}"
        , "{{Disambiguation"
        , "{{disambig}}"
        , "{{dmbox"
        ]


preview : Article a -> Article Preview
preview (Article title _) =
    Article title Preview


equals : Article a -> Article b -> Bool
equals (Article firstTitle _) (Article secondTitle _) =
    firstTitle == secondTitle



-- VIEW


viewAsLink : Article a -> Html msg
viewAsLink article =
    a
        [ href (toUrl article) ]
        [ text (getTitle article) ]


toUrl : Article a -> String
toUrl article =
    "https://en.wikipedia.org/wiki/" ++ getTitle article


viewError : ArticleError -> Html msg
viewError error =
    span
        [ css [ fontSize (px 16) ] ]
        [ text (toErrorMessage error) ]


toErrorMessage : ArticleError -> String
toErrorMessage error =
    case error of
        ArticleNotFound ->
            "Couldn't find that article 😕"

        InvalidTitle ->
            "Not a valid article title 😕"

        HttpError _ ->
            "Network error 😕"



-- FETCH


fetchByTitle : Title -> Http.Request ArticleResult
fetchByTitle title =
    Http.get (fetchByTitleUrl title) fetchByTitleDecoder


fetchRandom : Int -> Http.Request (List (Article Preview))
fetchRandom count =
    Http.get (fetchRandomUrl count) fetchRandomDecoder


type alias ArticleResult =
    Result ArticleError (Article Full)


type ArticleError
    = ArticleNotFound
    | InvalidTitle
    | HttpError Http.Error



-- URLS


type alias Url =
    String


fetchRandomUrl : Int -> Url
fetchRandomUrl count =
    wikipediaQueryUrl
        [ UrlBuilder.string "list" "random"
        , UrlBuilder.int "rnlimit" count
        , UrlBuilder.int "rnnamespace" 0
        ]


fetchByTitleUrl : Title -> Url
fetchByTitleUrl title =
    wikipediaQueryUrl
        [ UrlBuilder.string "prop" "revisions|links"
        , UrlBuilder.string "titles" title
        , UrlBuilder.int "redirects" 1
        , UrlBuilder.int "formatversion" 2
        , UrlBuilder.string "rvprop" "content"
        , UrlBuilder.string "rvslots" "main"
        , UrlBuilder.int "plnamespace" 0
        , UrlBuilder.string "pllimit" "max"
        ]


wikipediaQueryUrl : List QueryParameter -> Url
wikipediaQueryUrl params =
    let
        baseParams =
            [ UrlBuilder.string "action" "query"
            , UrlBuilder.string "format" "json"
            , UrlBuilder.string "origin" "*"
            ]
    in
    UrlBuilder.crossOrigin "https://en.wikipedia.org" [ "w", "api.php" ] (baseParams ++ params)



-- DECODERS


fetchByTitleDecoder : Decoder ArticleResult
fetchByTitleDecoder =
    at [ "query", "pages", "0" ]
        (oneOf
            [ map Ok articleFullDecoder
            , map Err invalidArticleDecoder
            , map Err missingArticleDecoder
            ]
        )


fetchRandomDecoder : Decoder (List (Article Preview))
fetchRandomDecoder =
    at [ "query", "random" ] (list articlePreviewDecoder)


articlePreviewDecoder : Decoder (Article Preview)
articlePreviewDecoder =
    succeed Article
        |> required "title" string
        |> hardcoded Preview


articleFullDecoder : Decoder (Article Full)
articleFullDecoder =
    succeed Article
        |> required "title" string
        |> custom (map Full bodyDecoder)


bodyDecoder : Decoder Body
bodyDecoder =
    succeed Body
        |> requiredAt [ "revisions", "0", "slots", "main", "content" ] string
        |> required "links" (list articlePreviewDecoder)


invalidArticleDecoder : Decoder ArticleError
invalidArticleDecoder =
    field "invalid" bool
        |> Decode.andThen (always <| Decode.succeed InvalidTitle)


missingArticleDecoder : Decoder ArticleError
missingArticleDecoder =
    field "missing" bool
        |> Decode.andThen (always <| Decode.succeed ArticleNotFound)
