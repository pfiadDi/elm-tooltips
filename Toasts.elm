module Toasts exposing (Msg(..), Toast, ToastStatus(..), createToast, defineToast, getTargetElement, getToastDimension, paintToast, positionToast, renderToasts, updateHY, updateStatus, updateWXY)

import Browser.Dom as Dom
import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Sha256 exposing (sha256)
import Task


type Msg
    = ToastInfo String (Result Dom.Error Dom.Element)
    | TargetInfo String (Result Dom.Error Dom.Element)


type ToastStatus
    = None
    | CollectDimensions
    | Show


type alias Toast =
    { textMsg : String
    , width : Maybe Float
    , height : Maybe Float
    , targetX : Maybe Float
    , targetY : Maybe Float
    , elementId : String
    , status : ToastStatus
    , y : Maybe Float
    }


defineToast : String -> String -> Toast
defineToast id textMsg =
    Toast textMsg Nothing Nothing Nothing Nothing id None Nothing


paintToast : Maybe Dom.Element -> Maybe Dom.Element -> String -> ( String, Html msg )
paintToast toastElement targetElement textMsg =
    let
        eleId =
            "i" ++ Sha256.sha256 textMsg

        position =
            case ( toastElement, targetElement ) of
                ( Nothing, Nothing ) ->
                    Html.Attributes.style "visibility" "hidden"

                ( _, Nothing ) ->
                    Html.Attributes.style "visibility" "hidden"

                ( Nothing, Just targetElement_ ) ->
                    Html.Attributes.style "width" (String.fromFloat targetElement_.element.width)

                _ ->
                    Html.Attributes.style "visibility" "hidden"
    in
    ( eleId
    , div [ Html.Attributes.class "toastContainer", Html.Attributes.id eleId, position ]
        [ div [ Html.Attributes.class "toastContent" ]
            [ p []
                [ text textMsg ]
            ]
        , div [ Html.Attributes.class "toastTriangle" ]
            []
        ]
    )


positionToast : Toast -> Html msg
positionToast toast =
    div
        [ Html.Attributes.class "toastContainer"
        , Html.Attributes.id toast.elementId
        , Html.Attributes.style "max-width" (String.fromFloat (Maybe.withDefault 0 toast.width) ++ "px")
        , Html.Attributes.style "left" (String.fromFloat (Maybe.withDefault 0 toast.targetX) ++ "px")
        , Html.Attributes.style "top" (String.fromFloat (Maybe.withDefault 0 toast.y) ++ "px")
        ]
        [ div [ Html.Attributes.class "toastContent" ]
            [ p []
                [ text toast.textMsg ]
            ]
        , div [ Html.Attributes.class "toastTriangle" ]
            []
        ]


createToast : Toast -> Html msg
createToast toast =
    div
        [ Html.Attributes.class "toastContainer"
        , Html.Attributes.id toast.elementId
        , Html.Attributes.style "visibility" "hidden"
        , Html.Attributes.style "max-width" (String.fromFloat (Maybe.withDefault 0 toast.width) ++ "px")
        ]
        [ div [ Html.Attributes.class "toastContent" ]
            [ p []
                [ text toast.textMsg ]
            ]
        , div [ Html.Attributes.class "toastTriangle" ]
            []
        ]


getToastDimension : String -> Cmd Msg
getToastDimension toastId =
    Dom.getElement toastId
        |> Task.attempt (ToastInfo toastId)


getTargetElement : String -> String -> Cmd Msg
getTargetElement toastid targetId =
    Dom.getElement targetId
        |> Task.attempt (TargetInfo toastid)


updateStatus_ : ToastStatus -> Maybe Toast -> Maybe Toast
updateStatus_ newStatus dictItem =
    case dictItem of
        Just toast ->
            Just { toast | status = newStatus }

        Nothing ->
            Nothing


updateStatus : Dict.Dict String Toast -> String -> ToastStatus -> Dict.Dict String Toast
updateStatus toasts key newStatus =
    Dict.update key (updateStatus_ newStatus) toasts


updateWXY_ : Float -> Float -> Float -> Maybe Toast -> Maybe Toast
updateWXY_ w x y dictItem =
    case dictItem of
        Just toast ->
            Just { toast | width = Just w, targetX = Just x, targetY = Just y }

        Nothing ->
            Nothing


updateWXY : Dict.Dict String Toast -> String -> Float -> Float -> Float -> Dict.Dict String Toast
updateWXY toasts key w x y =
    Dict.update key (updateWXY_ w x y) toasts


updateHY_ : Float -> Maybe Toast -> Maybe Toast
updateHY_ h dictItem =
    case dictItem of
        Just toast ->
            let
                y =
                    case toast.targetY of
                        Just targetY ->
                            targetY - h

                        Nothing ->
                            40.5
            in
            Just { toast | height = Just h, y = Just y, status = Show }

        Nothing ->
            Nothing


updateHY : Dict.Dict String Toast -> String -> Float -> Dict.Dict String Toast
updateHY toasts key h =
    Dict.update key (updateHY_ h) toasts


noHtml : Html msg
noHtml =
    text ""


renderToasts : Dict.Dict String Toast -> Html msg
renderToasts toasts =
    div [] <|
        List.map renderToast <|
            Dict.values toasts


renderToast : Toast -> Html msg
renderToast toast =
    case toast.status of
        CollectDimensions ->
            createToast toast

        Show ->
            positionToast toast

        None ->
            noHtml
