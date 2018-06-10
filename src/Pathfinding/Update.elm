module Pathfinding.Update exposing (update, updateWithArticle)

import Result exposing (Result(Ok, Err))
import Common.Article.Service as Article
import Common.Article.Model exposing (Article, ArticleResult, ArticleError)
import Common.Title.Model as Title exposing (Title)
import Common.Path.Model as Path exposing (Path)
import Common.PriorityQueue.Model as PriorityQueue
import Model exposing (Model)
import Messages exposing (Msg)
import Finished.Init
import Setup.Init
import Pathfinding.Messages exposing (PathfindingMsg(FetchArticleResponse, BackToSetup))
import Pathfinding.Model exposing (PathfindingModel)
import Pathfinding.Util as Util


update : PathfindingMsg -> PathfindingModel -> ( Model, Cmd Msg )
update message model =
    case message of
        FetchArticleResponse pathSoFar articleResult ->
            updateWithResult
                (decrementInFlightRequests model)
                pathSoFar
                articleResult

        BackToSetup ->
            Setup.Init.init


updateWithResult : PathfindingModel -> Path -> ArticleResult -> ( Model, Cmd Msg )
updateWithResult model pathSoFar articleResult =
    case articleResult of
        Ok article ->
            if hasReachedDestination article.title model.destination then
                destinationReached pathSoFar
            else
                updateWithArticle model pathSoFar article

        Err error ->
            updateWithError model error


updateWithArticle : PathfindingModel -> Path -> Article -> ( Model, Cmd Msg )
updateWithArticle model pathSoFar article =
    let
        updatedPriorityQueue =
            Util.addLinksToQueue
                model.priorityQueue
                model.destination
                pathSoFar
                article.links

        updatedModel =
            { model | priorityQueue = updatedPriorityQueue }
    in
        followHighestPriorityPaths updatedModel


updateWithError : PathfindingModel -> ArticleError -> ( Model, Cmd Msg )
updateWithError model error =
    let
        updatedModel =
            { model | errors = error :: model.errors }
    in
        followHighestPriorityPaths updatedModel


followHighestPriorityPaths : PathfindingModel -> ( Model, Cmd Msg )
followHighestPriorityPaths model =
    let
        maxPathsToRemove =
            inFlightRequestLimit - model.inFlightRequests

        ( highestPriorityPaths, updatedPriorityQueue ) =
            PriorityQueue.removeHighestPriorities model.priorityQueue maxPathsToRemove

        isSearchExhausted =
            List.isEmpty highestPriorityPaths && model.inFlightRequests == 0

        updatedModel =
            { model | priorityQueue = updatedPriorityQueue }
    in
        if isSearchExhausted then
            Finished.Init.initWithPathNotFound
        else
            followPaths updatedModel highestPriorityPaths


followPaths : PathfindingModel -> List Path -> ( Model, Cmd Msg )
followPaths model pathsToFollow =
    ifPathReachedDestination pathsToFollow model.destination
        |> Maybe.map destinationReached
        |> Maybe.withDefault (fetchNextArticles model pathsToFollow)


ifPathReachedDestination : List Path -> Article -> Maybe Path
ifPathReachedDestination paths destination =
    paths
        |> List.filter (\path -> hasReachedDestination (Path.nextStop path) destination)
        |> List.sortBy Path.length
        |> List.head


destinationReached : Path -> ( Model, Cmd Msg )
destinationReached path =
    Finished.Init.initWithPath path


fetchNextArticles : PathfindingModel -> List Path -> ( Model, Cmd Msg )
fetchNextArticles model pathsToFollow =
    let
        articleRequests =
            List.map fetchNextArticle pathsToFollow

        updatedModel =
            incrementRequests model (List.length articleRequests)
    in
        if hasMadeTooManyRequests model then
            Finished.Init.initWithTooManyRequestsError
        else
            ( Model.Pathfinding updatedModel, Cmd.batch articleRequests )


fetchNextArticle : Path -> Cmd Msg
fetchNextArticle pathSoFar =
    Article.request
        (FetchArticleResponse pathSoFar >> Messages.Pathfinding)
        (Path.nextStop pathSoFar |> Title.value)


hasReachedDestination : Title -> Article -> Bool
hasReachedDestination nextTitle destination =
    nextTitle == destination.title


hasMadeTooManyRequests : PathfindingModel -> Bool
hasMadeTooManyRequests { totalRequestCount } =
    totalRequestCount > 200


inFlightRequestLimit : Int
inFlightRequestLimit =
    4


decrementInFlightRequests : PathfindingModel -> PathfindingModel
decrementInFlightRequests model =
    { model | inFlightRequests = model.inFlightRequests - 1 }


incrementRequests : PathfindingModel -> Int -> PathfindingModel
incrementRequests model requestCount =
    { model
        | inFlightRequests = model.inFlightRequests + requestCount
        , totalRequestCount = model.totalRequestCount + requestCount
    }
