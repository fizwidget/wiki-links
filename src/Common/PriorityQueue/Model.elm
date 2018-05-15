module Common.PriorityQueue.Model
    exposing
        ( PriorityQueue
        , Priority
        , empty
        , insert
        , removeHighestPriority
        , removeHighestPriorities
        , getHighestPriority
        , isEmpty
        , toSortedList
        )

import PairingHeap exposing (PairingHeap)


type PriorityQueue a
    = PriorityQueue (PairingHeap Priority a)


type alias Priority =
    Float


empty : PriorityQueue a
empty =
    PriorityQueue PairingHeap.empty


insert : PriorityQueue a -> (a -> Priority) -> List a -> PriorityQueue a
insert (PriorityQueue pairingHeap) getPriority values =
    let
        getNegatedPriority =
            getPriority >> negate

        withNegatedPriority =
            \value -> ( getNegatedPriority value, value )

        valuesWithNegatedPriorities =
            List.map withNegatedPriority values

        updatedPairingHeap =
            List.foldl PairingHeap.insert pairingHeap valuesWithNegatedPriorities
    in
        PriorityQueue updatedPairingHeap


getHighestPriority : PriorityQueue a -> Maybe a
getHighestPriority (PriorityQueue pairingHeap) =
    PairingHeap.findMin pairingHeap
        |> Maybe.map Tuple.second


removeHighestPriority : PriorityQueue a -> ( Maybe a, PriorityQueue a )
removeHighestPriority (PriorityQueue pairingHeap) =
    ( PairingHeap.findMin pairingHeap |> Maybe.map Tuple.second
    , PairingHeap.deleteMin pairingHeap |> PriorityQueue
    )


removeHighestPriorities : PriorityQueue a -> Int -> ( List a, PriorityQueue a )
removeHighestPriorities priorityQueue howMany =
    let
        helper priorityQueue howMany removedValues =
            if howMany > 0 then
                let
                    ( value, updatedPriorityQueue ) =
                        removeHighestPriority priorityQueue
                in
                    helper updatedPriorityQueue (howMany - 1) (value :: removedValues)
            else
                ( removedValues, priorityQueue )
    in
        helper priorityQueue howMany []
            |> Tuple.mapFirst (List.filterMap identity)


isEmpty : PriorityQueue a -> Bool
isEmpty (PriorityQueue pairingHeap) =
    PairingHeap.findMin pairingHeap
        |> Maybe.map (always False)
        |> Maybe.withDefault True


toSortedList : PriorityQueue a -> List a
toSortedList (PriorityQueue pairingHeap) =
    PairingHeap.toSortedList pairingHeap
        |> List.map Tuple.second
