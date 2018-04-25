# The Wikipedia Game (in Elm!)

Wikilinks is a 100% frontend Elm implementation of the [Wikipedia game](https://en.wikipedia.org/wiki/Wikipedia:Wiki_Game). It'll find a path between any two Wikipedia articles.

TODOs:
* Improve performance by performing requests in parallel.
* Experiment with improved pathfinding by penalising longer paths.
* Switch to `elm-css`.
* Completely decouple the different pages from each other.
* Come up with a better heuristic regex (current one doesn't handle quotes, trailing colon, etc).

Notes:
* Currently struggles with "World -> Hello".