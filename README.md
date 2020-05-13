# elm-tooltips for form fields
Tooltips which position relative to any element (I called them toast what I definitly not correct but now I stick with it :) )
The toasts are positioned absolute what gives you more flexiblity since you don't need to place hidden elements in containers close to the target elements. When a toast should be shown we not only want to positionate them close to the target element but it should fit the screen and it should have the width of the input field:



To achieve that we need two information:
1. The current position of the target element
2. And also the height of the toast, when the info text is insert and it has the width of the target element. 

Both information are highly dynamic since they depend on the length of the text, the current width of the target element (since often the width of the target element is responsive).

<img src="https://github.com/pfiadDi/elm-tooltips/blob/master/ReadMePicture.png?raw=true" width=500>


The overall logic therefore is:

- Toasts are definded in the model 
- When a toast is called
  - The HTML element is prepared
  - First we get the current position and dimension from the target element
      - We update the toast html and set the width to the width of the target element, the left position to the one of the target, and the top position to the one of the target element.
      - The toast is now OVER the target element
  - To position it above the target element we need to know the height of toast, so next we obtain the current element information of the toast
      - Now we update the toast top position with top from target minus height of toast
  - The toast is now in the correct position and we can show it. The status is set to Show and in the view rendered.
  
# Usage

A toast:
```
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
```

and a toast can have three states:

```
type ToastStatus
    = None -- it exits as toast in your model 
    | CollectDimensions -- a invisible html exisits and we obtaining positon information
    | Show -- everything is obtained and renderd. the toast is shown
```


All toasts in your model are a dict of toast:
```
type alias Model = {
...
formToasts : Dict.Dict String Toasts.Toast
...
}
```

And define it on init like that:

```
, formToasts =
        Dict.fromList
            [ ( "toastName", Toasts.defineToast "toastName" content.toastText )
            , ( "toastName2", Toasts.defineToast "toastName2" content.toastText2 )
            ...
            ]
```

You need a Toast msg which maps the messages from the module:

```
type Msg 
 = ...
 | Toast Toasts.Msg
 ...
```

In your update you need to handle two messages from a Toast:

```
Toast toastMsg ->
     case toastMsg of
       Toasts.TargetInfo toastId targetElement ->
          case targetElement of
             Ok targetElement_ ->
                -- update the toast element width, x and y position (this is a helper function which updated the dict in your model see below) 
                updateToastWXY targetElement_.element.width targetElement_.element.x targetElement_.element.y toastId model
                -- fire the second task to the the current toast dimensions
                    |> withCmd (Cmd.map Toast <| Toasts.getToastDimension toastId )
              Err error ->
                 ( model, Cmd.none )
                
        Toasts.ToastInfo toastId toastElement ->
           case toastElement of
              Ok toastElement_ ->
                 -- Wit this function the height and the y position is adjusted and the status is set to Show
                 updateToastHY toastElement_.element.height toastId model
                   |> withCmd Cmd.none
              Err error ->
                   ( model, Cmd.none )
```

You start the painting the toast in your update, e.g. in a case where a form field has a wrong input with

```
update ...
   case msg of
      WrongInput ->
        updateToastStatus Toasts.CollectDimensions "toastName" model
          |> withCmd (Cmd.map Toast (Toasts.getTargetElement "toastName" "targetElementHTMLId"))
```

If you want to delete a toast you do in your update:

```
update ...
   case msg of
      CorrectInput ->
        updateToastStatus Toasts.None "toastName" model
          |> withCmd Cmd.none
```


It's important to render the toast in your view outside every other element. Therefore as a child of your body, that the position of no other element makes a problem. You do by placing this function in your view:

```
view ...
 Toasts.renderToasts model.formToasts
```

## Helper functions

Those functions help you update the toast in your model and return your model. You can handle it differently but it is helpful:

### Update a toast status:
This function update a toast in the dict your model with the new status, either to start the processing of showing or to delete it. Since it takes your model and returns your model it is ready to be used with nested models.

```
updateToastStatus : Toasts.ToastStatus -> String -> Model -> Model
updateToastStatus nV toastId model =
    let
        updatedToasts =
            Toasts.updateStatus model.formToasts toastId nV
    in
    { model | formToasts = updatedToasts }
```

### Update Width, X, and Y
This is the second step in rendering, when the information from the target element comes in, with this function we update the toasts width and x and y position.

```
updateToastWXY : Float -> Float -> Float -> String -> Model -> Model
updateToastWXY w x y toastId model =
    let
        updatedToasts =
            Toasts.updateWXY model.formToasts toastId w x y
    in
    { model | formToasts = updatedToasts }
```

### Update Height and Y position
The last step to show the toast, this function update the last pieces and set the status to Show.

```
updateToastHY : Float -> String -> Model -> Model
updateToastHY h toastId model =
    let
        updatedToasts =
            Toasts.updateHY model.formToasts toastId h
    in
    { model | formToasts = updatedToasts }
```

