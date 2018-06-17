module Setup.Update exposing (update)

import RemoteData exposing (WebData, RemoteData(Loading, NotAsked))
import Common.Article.Model exposing (RemoteArticle)
import Common.Title.Model as Title exposing (Title, RemoteTitlePair)
import Model exposing (Model)
import Messages exposing (Msg)
import Setup.Messages exposing (SetupMsg(..))
import Setup.Model exposing (SetupModel, UserInput)
import Setup.Service as Service
import Pathfinding.Init


update : SetupMsg -> SetupModel -> ( Model, Cmd Msg )
update message model =
    case message of
        SourceArticleTitleChange value ->
            setSourceTitle model value

        DestinationArticleTitleChange value ->
            setDestinationTitle model value

        FetchRandomTitlesRequest ->
            fetchRandomTitles model

        FetchRandomTitlesResponse titles ->
            setRandomTitles model titles

        FetchArticlesRequest ->
            fetchArticles model

        FetchSourceArticleResponse article ->
            setSourceArticle model article
                |> maybeBeginPathfinding

        FetchDestinationArticleResponse article ->
            setDestinationArticle model article
                |> maybeBeginPathfinding


setSourceTitle : SetupModel -> UserInput -> ( Model, Cmd Msg )
setSourceTitle model sourceTitleInput =
    ( Model.Setup
        { model
            | source = NotAsked
            , sourceTitleInput = sourceTitleInput
        }
    , Cmd.none
    )


setDestinationTitle : SetupModel -> UserInput -> ( Model, Cmd Msg )
setDestinationTitle model destinationTitleInput =
    ( Model.Setup
        { model
            | destination = NotAsked
            , destinationTitleInput = destinationTitleInput
        }
    , Cmd.none
    )


fetchArticles : SetupModel -> ( Model, Cmd Msg )
fetchArticles model =
    let
        updatedModel =
            { model | source = Loading, destination = Loading }

        requests =
            [ Service.fetchArticle FetchSourceArticleResponse model.sourceTitleInput
            , Service.fetchArticle FetchDestinationArticleResponse model.destinationTitleInput
            ]
    in
        ( Model.Setup updatedModel
        , requests
            |> Cmd.batch
            |> Cmd.map Messages.Setup
        )


setSourceArticle : SetupModel -> RemoteArticle -> SetupModel
setSourceArticle model source =
    { model | source = source }


setDestinationArticle : SetupModel -> RemoteArticle -> SetupModel
setDestinationArticle model destination =
    { model | destination = destination }


maybeBeginPathfinding : SetupModel -> ( Model, Cmd Msg )
maybeBeginPathfinding model =
    let
        sourceAndDestination =
            RemoteData.toMaybe <| RemoteData.map2 (,) model.source model.destination
    in
        case sourceAndDestination of
            Just ( source, destination ) ->
                Pathfinding.Init.init source destination

            Nothing ->
                ( Model.Setup model, Cmd.none )


fetchRandomTitles : SetupModel -> ( Model, Cmd Msg )
fetchRandomTitles model =
    ( Model.Setup { model | randomTitles = Loading }
    , Service.fetchRandomTitlePair FetchRandomTitlesResponse |> Cmd.map Messages.Setup
    )


setRandomTitles : SetupModel -> RemoteTitlePair -> ( Model, Cmd Msg )
setRandomTitles model randomTitles =
    let
        updatedModel =
            { model | randomTitles = randomTitles }

        updatedModelWithInputsSet =
            randomTitles
                |> RemoteData.map (setTitleInputs updatedModel)
                |> RemoteData.withDefault updatedModel
    in
        ( Model.Setup updatedModelWithInputsSet
        , Cmd.none
        )


setTitleInputs : SetupModel -> ( Title, Title ) -> SetupModel
setTitleInputs model ( titleA, titleB ) =
    { model
        | source = NotAsked
        , sourceTitleInput = Title.value titleA
        , destination = NotAsked
        , destinationTitleInput = Title.value titleB
    }
