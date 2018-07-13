module Page.Finished
    exposing
        ( Model(Success, Error)
        , Error(PathNotFound, TooManyRequests)
        , view
        )

import Bootstrap.Button as ButtonOptions
import Common.Article exposing (Article)
import Common.Button as Button
import Common.Path as Path exposing (Path)
import Common.Title as Title exposing (Title)
import Css exposing (..)
import Html.Styled exposing (Html, fromUnstyled, toUnstyled, h2, h4, div, pre, input, button, text, form)
import Html.Styled.Attributes exposing (css, value, type_, placeholder)


-- Model


type Model
    = Success Path
    | Error
        { error : Error
        , source : Article
        , destination : Article
        }


type Error
    = PathNotFound
    | TooManyRequests



-- View


view : Model -> (Title -> Title -> backMsg) -> Html backMsg
view model toBackMsg =
    div [ css [ displayFlex, alignItems center, justifyContent center, flexDirection column ] ]
        [ viewModel model
        , viewBackButton model toBackMsg
        ]


viewModel : Model -> Html msg
viewModel model =
    case model of
        Success pathToDestination ->
            viewSuccess pathToDestination

        Error { source, destination, error } ->
            viewError source destination error


viewSuccess : Path -> Html msg
viewSuccess pathToDestination =
    div [ css [ textAlign center ] ]
        [ viewHeading
        , viewSubHeading
        , viewPath pathToDestination
        ]


viewHeading : Html msg
viewHeading =
    h2 [] [ text "Success!" ]


viewSubHeading : Html msg
viewSubHeading =
    h4 [] [ text "Path was... " ]


viewPath : Path -> Html msg
viewPath path =
    Path.inOrder path
        |> List.map Title.viewAsLink
        |> List.intersperse (text " → ")
        |> div []


viewError : Article -> Article -> Error -> Html msg
viewError source destination error =
    let
        baseErrorMessage =
            [ text "Sorry, couldn't find a path from "
            , Title.viewAsLink source.title
            , text " to "
            , Title.viewAsLink destination.title
            , text " 💀"
            ]
    in
        div [ css [ textAlign center ] ]
            (case error of
                PathNotFound ->
                    baseErrorMessage

                TooManyRequests ->
                    List.append
                        baseErrorMessage
                        [ div [] [ text "We made too many requests to Wikipedia! 😵" ] ]
            )


viewBackButton : Model -> (Title -> Title -> backMsg) -> Html backMsg
viewBackButton model toBackMsg =
    let
        onClick =
            toBackMsg (getSource model) (getDestination model)
    in
        div [ css [ margin (px 20) ] ]
            [ Button.view
                [ ButtonOptions.secondary, ButtonOptions.onClick onClick ]
                [ text "Back" ]
            ]


getSource : Model -> Title
getSource model =
    case model of
        Success path ->
            Path.beginning path

        Error { source } ->
            source.title


getDestination : Model -> Title
getDestination model =
    case model of
        Success path ->
            Path.end path

        Error { destination } ->
            destination.title
