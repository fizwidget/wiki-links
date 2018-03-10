module ChoosingEndpoints.Commands exposing (getArticles)

import Messages exposing (Msg(FetchSourceArticleResult, FetchDestinationArticleResult))
import Common.Service exposing (getArticle)


getArticles : String -> String -> Cmd Msg
getArticles sourceTitle destinationTitle =
    Cmd.batch
        [ getArticle sourceTitle FetchSourceArticleResult
        , getArticle destinationTitle FetchDestinationArticleResult
        ]
