module View.Content exposing (articlesContent)

import RemoteData
import Html exposing (Html, div, text, h2, a)
import Html.Attributes exposing (style, href)
import Model exposing (Model, ArticleResult, RemoteArticle, Article, ApiError(..))
import LinkExtractor exposing (Link, getLinks)


articlesContent : Model -> Html message
articlesContent { sourceArticle, destinationArticle } =
    div [ style [ ( "display", "flex" ), ( "align-items", "top" ) ] ]
        [ displayRemoteArticle sourceArticle
        , displayRemoteArticle destinationArticle
        ]


displayRemoteArticle : RemoteArticle -> Html message
displayRemoteArticle article =
    div [ style [ ( "flex", "1" ), ( "max-width", "50%" ) ] ]
        [ case article of
            RemoteData.NotAsked ->
                text ""

            RemoteData.Loading ->
                text "Loading..."

            RemoteData.Success articleResult ->
                displayArticleResult articleResult

            RemoteData.Failure error ->
                text (toString error)
        ]


displayArticleResult : ArticleResult -> Html message
displayArticleResult article =
    case article of
        Result.Err error ->
            displayError error

        Result.Ok article ->
            displaySuccess article


displaySuccess : Article -> Html message
displaySuccess { title, content } =
    div []
        ((h2 [] [ text title ])
            :: List.map displayLink (getLinks content)
        )


displayLink : Link -> Html message
displayLink { name, destination } =
    div []
        [ a
            [ href ("https://en.wikipedia.org" ++ destination)
            , (style [ ( "color", "hotpink" ) ])
            ]
            [ text name ]
        ]


displayError : ApiError -> Html message
displayError error =
    case error of
        ArticleNotFound ->
            text "Article not found"

        UnknownError errorCode ->
            text ("Unknown error: " ++ errorCode)
