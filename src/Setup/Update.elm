module Setup.Update exposing (update)

import RemoteData exposing (WebData, RemoteData(Loading, NotAsked))
import Common.Article.Service as Article
import Common.Article.Model exposing (RemoteArticle)
import Common.Title.Model as Title exposing (Title, RemoteTitlePair)
import Common.Title.Service as Title
import Model exposing (Model)
import Messages exposing (Msg)
import Setup.Messages exposing (SetupMsg(..))
import Setup.Model exposing (SetupModel, UserInput)
import Pathfinding.Init


update : SetupMsg -> SetupModel -> ( Model, Cmd Msg )
update message model =
    case message of
        SourceArticleTitleChange value ->
            setSourceTitle model value

        DestinationArticleTitleChange value ->
            setDestinationTitle model value

        FetchArticlesRequest ->
            requestArticles model

        FetchSourceArticleResponse article ->
            setSourceArticle model article

        FetchDestinationArticleResponse article ->
            setDestinationArticle model article

        FetchRandomTitlesRequest ->
            requestRandomTitles model

        FetchRandomTitlesResponse titles ->
            setRandomTitles model titles


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


requestArticles : SetupModel -> ( Model, Cmd Msg )
requestArticles model =
    let
        updatedModel =
            { model | source = Loading, destination = Loading }

        requests =
            [ Article.requestRemote FetchSourceArticleResponse model.sourceTitleInput
            , Article.requestRemote FetchDestinationArticleResponse model.destinationTitleInput
            ]
    in
        ( Model.Setup updatedModel
        , requests
            |> Cmd.batch
            |> Cmd.map Messages.Setup
        )


setSourceArticle : SetupModel -> RemoteArticle -> ( Model, Cmd Msg )
setSourceArticle model source =
    ( { model | source = source }, Cmd.none )
        |> beginPathfindingIfArticlesLoaded


setDestinationArticle : SetupModel -> RemoteArticle -> ( Model, Cmd Msg )
setDestinationArticle model destination =
    ( { model | destination = destination }, Cmd.none )
        |> beginPathfindingIfArticlesLoaded


beginPathfindingIfArticlesLoaded : ( SetupModel, Cmd Msg ) -> ( Model, Cmd Msg )
beginPathfindingIfArticlesLoaded ( model, cmd ) =
    RemoteData.map2 Pathfinding.Init.init model.source model.destination
        |> RemoteData.toMaybe
        |> Maybe.withDefault ( Model.Setup model, cmd )


requestRandomTitles : SetupModel -> ( Model, Cmd Msg )
requestRandomTitles model =
    ( Model.Setup { model | randomTitles = Loading }
    , Title.requestRandomPair FetchRandomTitlesResponse |> Cmd.map Messages.Setup
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
        | sourceTitleInput = Title.value titleA
        , destinationTitleInput = Title.value titleB
        , source = NotAsked
        , destination = NotAsked
    }
