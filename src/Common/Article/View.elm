module Common.Article.View exposing (viewError)

import Html.Styled exposing (Html, div, text)
import Common.Article.Model exposing (ArticleError(..))


viewError : ArticleError -> Html msg
viewError error =
    let
        errorMessage =
            case error of
                ArticleNotFound ->
                    "Couldn't find that article :("

                InvalidTitle ->
                    "Not a valid article title :("

                UnknownError errorCode ->
                    ("Unknown error: " ++ errorCode)

                HttpError error ->
                    ("Network error: " ++ toString error)
    in
        div [] [ text errorMessage ]
