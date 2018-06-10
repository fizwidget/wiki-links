module Pathfinding.Init exposing (init)

import Common.Article.Model exposing (Article)
import Common.PriorityQueue.Model as PriorityQueue
import Common.Path.Model as Path
import Model exposing (Model(Pathfinding))
import Messages exposing (Msg(Pathfinding))
import Pathfinding.Update exposing (updateWithArticle)
import Pathfinding.Model exposing (PathfindingModel)


init : Article -> Article -> ( Model, Cmd Msg )
init source destination =
    updateWithArticle
        (initialModel source destination)
        (Path.startingAt source.title)
        source


initialModel : Article -> Article -> PathfindingModel
initialModel source destination =
    { source = source
    , destination = destination
    , priorityQueue = PriorityQueue.empty
    , errors = []
    , inFlightRequests = 0
    , totalRequestCount = 0
    }
