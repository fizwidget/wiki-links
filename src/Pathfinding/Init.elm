module Pathfinding.Init exposing (init)

import Common.Model.Article exposing (Article)
import Model exposing (Model(Pathfinding))
import Messages exposing (Msg(Pathfinding))
import Pathfinding.Update exposing (onArticleSuccess)
import Pathfinding.Model exposing (PathfindingModel)


init : Article -> Article -> ( Model, Cmd Msg )
init source destination =
    onArticleSuccess (initialModel source destination) source


initialModel : Article -> Article -> PathfindingModel
initialModel source destination =
    { source = source
    , destination = destination
    , stops = [ source.title ]
    , error = Nothing
    }
