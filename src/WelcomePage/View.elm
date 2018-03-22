module WelcomePage.View exposing (view)

import Html exposing (Html, div, input, button, text)
import Html.Attributes exposing (value, type_, style, placeholder)
import Bootstrap.Button as Button
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import RemoteData
import Common.Model exposing (RemoteArticle, ArticleError(..))
import WelcomePage.Messages exposing (Msg(..))
import WelcomePage.Model exposing (Model)


view : Model -> Html Msg
view model =
    Form.form []
        [ titleInputs model
        , loadArticlesButton
        , articlesContent model.sourceArticle model.destinationArticle
        ]


titleInputs : Model -> Html Msg
titleInputs { sourceTitleInput, destinationTitleInput } =
    Form.row []
        [ Form.col [] [ sourceArticleTitleInput sourceTitleInput ]
        , Form.col [] [ destinationArticleTitleInput destinationTitleInput ]
        ]


sourceArticleTitleInput : String -> Html Msg
sourceArticleTitleInput =
    articleTitleInput "From..." SourceArticleTitleChange


destinationArticleTitleInput : String -> Html Msg
destinationArticleTitleInput =
    articleTitleInput "To..." DestinationArticleTitleChange


articleTitleInput : String -> (String -> Msg) -> String -> Html Msg
articleTitleInput placeholderText toMsg title =
    Input.text
        [ Input.onInput toMsg
        , Input.value title
        , Input.placeholder placeholderText
        ]


loadArticlesButton : Html Msg
loadArticlesButton =
    Form.row [ Row.centerLg ]
        [ Form.col [ Col.lgAuto ]
            [ Button.button
                [ Button.primary, Button.onClick FetchArticlesRequest ]
                [ text "Find path" ]
            ]
        ]


articlesContent : RemoteArticle -> RemoteArticle -> Html msg
articlesContent sourceArticle destinationArticle =
    div [ style [ ( "display", "flex" ), ( "align-items", "top" ) ] ]
        [ displayRemoteArticle sourceArticle
        , displayRemoteArticle destinationArticle
        ]


displayRemoteArticle : RemoteArticle -> Html msg
displayRemoteArticle article =
    div [ style [ ( "flex", "1" ), ( "max-width", "50%" ) ] ]
        [ case article of
            RemoteData.NotAsked ->
                text ""

            RemoteData.Loading ->
                text "Loading..."

            RemoteData.Success article ->
                text "Loaded!"

            RemoteData.Failure error ->
                displayError error
        ]


displayError : ArticleError -> Html msg
displayError error =
    case error of
        ArticleNotFound ->
            text "Not found"

        InvalidTitle ->
            text "Invalid title"

        UnknownError errorCode ->
            text ("Unknown error: " ++ errorCode)

        NetworkError error ->
            text ("Network error: " ++ toString error)
