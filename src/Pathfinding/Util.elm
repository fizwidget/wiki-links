module Pathfinding.Util exposing (suggestNextArticle)

import Regex exposing (Regex, regex, find, escape, caseInsensitive, HowMany(All))
import Common.Model exposing (Title(..), Article, value)
import Pathfinding.Model exposing (PathfindingModel)


suggestNextArticle : PathfindingModel -> Article -> Maybe Title
suggestNextArticle model current =
    getCandidates current model
        |> calculateBestCandidate model.end


getCandidates : Article -> PathfindingModel -> List Title
getCandidates current model =
    current.links
        |> List.filter isValidTitle
        |> List.filter (\title -> title /= current.title)
        |> List.filter (isUnvisited model)


isUnvisited : PathfindingModel -> Title -> Bool
isUnvisited model title =
    (title /= model.start.title)
        && (not <| List.member title model.stops)


isValidTitle : Title -> Bool
isValidTitle (Title value) =
    let
        ignorePrefixes =
            [ "Category:"
            , "Template:"
            , "Wikipedia:"
            , "Help:"
            , "Special:"
            , "Template talk:"
            , "ISBN"
            , "International Standard Book Number"
            , "Digital object identifier"
            , "Portal:"
            , "Book:"
            , "User:"
            , "Commons"
            , "Talk:"
            , "Wikipedia talk:"
            , "User talk:"
            , "Module:"
            , "File:"
            ]
    in
        not <| List.any (\prefix -> String.startsWith prefix value) ignorePrefixes


calculateBestCandidate : Article -> List Title -> Maybe Title
calculateBestCandidate end candidateTitles =
    candidateTitles
        |> List.map (\title -> ( title, heuristic end title ))
        |> List.sortBy (\( title, count ) -> -count)
        |> List.take 3
        |> Debug.log "Occurence counts"
        |> List.head
        |> Maybe.map Tuple.first


heuristic : Article -> Title -> Int
heuristic article title =
    find All (title |> value |> escape |> wholeWord |> caseInsensitive) article.content |> List.length


wholeWord : String -> Regex
wholeWord target =
    "(^|\\s+|\")" ++ target ++ "(\\s+|$|\")" |> regex


type alias Link =
    { title : String
    , href : String
    }
