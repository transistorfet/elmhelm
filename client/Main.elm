
import Dom
import Html
import Task
import Html.Attributes exposing (id, class, value, placeholder, type_, style)
import Html.Events exposing (onInput, onClick, onBlur, onSubmit)
import Http
import Json.Encode
import Json.Decode exposing (Decoder, map)
import Json.Decode.Pipeline exposing (decode, required)
--import WebSocket


main = Html.program {
  init = init,
  view = view,
  update = update,
  --subscriptions = subscriptions }
  subscriptions = \_ -> Sub.none }



type alias Model = {
  notes: List Note,
  new: Note
}

type alias NoteId = Int

type alias Note = {
  id: NoteId,
  title: TextField,
  body: TextField
}

type alias TextField = {
  text: String,
  editing: Bool
}


init : (Model, Cmd Msg)
init = {
  notes = [
    { id = 1,
      title = { text = "Notey Notes", editing = False },
      body = { text = "These are a bunch of notes about how notes are notey.", editing = False } },
    { id = 2,
      title = { text = "More Notes", editing = False },
      body = { text = "Wow, there are some many notes here.", editing = False } }
  ],
  new = emptyNote } ! [ fetchNotesCmd ]

emptyNote = {
  id = 0,
  title = { text = "", editing = False },
  body = { text = "", editing = False } }


-- UPDATE

type Msg =
  NoOp
  | Reset
  | Edit NoteId String Bool
  | Update NoteId String String
  | EditNew String Bool
  | UpdateNew String String
  | Insert
  | Delete NoteId

  | NotesFetched (Result Http.Error (List Note))
  | NoteInserted (Result Http.Error Bool)
  | NoteUpdated (Result Http.Error Bool)
  | NoteDeleted (Result Http.Error Bool)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NoOp -> model ! []
    Reset -> model ! []
    Edit id field state ->
      { model | notes = List.map (modifyNote id (\note -> updateNote field msg note)) model.notes }
      ! [
        if state == True then
          Task.attempt (\_ -> NoOp) (Dom.focus <| "note-" ++ toString id)
        else
          updateNoteCmd id field (findNoteField model.notes id field) ]
    Update id field text ->
      { model | notes = List.map (modifyNote id (\note -> updateNote field msg note)) model.notes }
      ! []
    EditNew field state ->
      { model | new = updateNote field msg model.new }
      ! []
    UpdateNew field text ->
      { model | new = updateNote field msg model.new }
      ! []
    Insert ->
      { model | notes = List.append model.notes [ model.new ], new = emptyNote }
      ! [ insertNoteCmd model.new ]
    Delete id ->
      { model | notes = List.filter (\note -> note.id /= id) model.notes }
      ! [ deleteNoteCmd id ]

    NotesFetched (Ok data) ->
      { model | notes = data }
      ! []
    NoteInserted (Ok data) ->
      model
      ! [ fetchNotesCmd ]
    NoteUpdated (Ok data) ->
      model
      ! [ fetchNotesCmd ]
    NoteDeleted (Ok data) ->
      model
      ! [ fetchNotesCmd ]
    _ ->
      model
      ! []

modifyNote : NoteId -> (Note -> Note) -> Note -> Note
modifyNote id f note =
  if note.id == id then
    f note
  else
    note

updateNote field msg note =
  case field of
    "title" -> { note | title = updateTextField msg note.title }
    "body" -> { note | body = updateTextField msg note.body }
    _ -> note

updateTextField msg model =
  case msg of
    Edit index field state ->
      { model | editing = state }
    Update index field text ->
      { model | text = text }
    EditNew field state ->
      { model | editing = state }
    UpdateNew field text ->
      { model | text = text }
    _ -> model

findNoteField : (List Note) -> NoteId -> String -> String
findNoteField list id field =
  case list of
    [] -> ""
    (x::xs) ->
      if x.id == id then
        case field of
          "title" -> x.title.text
          "body" -> x.body.text
          _ -> ""
      else
        findNoteField xs id field


-- API CALLS

fetchNotesCmd : Cmd Msg
fetchNotesCmd =
  Http.send NotesFetched (Http.get "http://localhost:8088/api/notes" decodeNotes)

insertNoteCmd : Note -> Cmd Msg
insertNoteCmd note =
  Http.send NoteInserted (restRequest "http://localhost:8088/api/notes" (encodeNote note) Json.Decode.bool "PUT")

updateNoteCmd : NoteId -> String -> String -> Cmd Msg
updateNoteCmd id field value =
  Http.send NoteUpdated (restRequest ("http://localhost:8088/api/notes/" ++ toString id ++ "/" ++ field) (Json.Encode.object [(field, Json.Encode.string value)]) Json.Decode.bool "POST")

deleteNoteCmd : NoteId -> Cmd Msg
deleteNoteCmd id =
  Http.send NoteDeleted (restRequest ("http://localhost:8088/api/notes/" ++ toString id) (Json.Encode.object []) Json.Decode.bool "DELETE")


restRequest : String -> Json.Encode.Value -> Decoder a -> String -> Http.Request a
restRequest url encode decoder method =
    Http.request
        { body = encode |> Http.jsonBody
        , expect = Http.expectJson decoder
        , headers = []
        , method = method
        , timeout = Nothing
        , url = url
        , withCredentials = False
        }

encodeNote : Note -> Json.Encode.Value
encodeNote note =
  Json.Encode.object
    [ ("id", Json.Encode.int note.id)
    , ("title", Json.Encode.string note.title.text)
    , ("body", Json.Encode.string note.body.text)
    ]

decodeNotes : Decoder (List Note)
decodeNotes =
  Json.Decode.list decodeNote

decodeNote : Decoder Note
decodeNote =
  decode Note
    |> required "id" Json.Decode.int
    |> required "title" decodeTextField
    |> required "body" decodeTextField

decodeTextField : Decoder TextField
decodeTextField =
  map toTextField Json.Decode.string

toTextField text =
  { text = text, editing = False }


-- SUBSCRIPTIONS

--subscriptions : Model -> Sub Msg
--subscriptions model =
--  WebSocket.listen "ws://echo.websocket.org" Connected


-- VIEW

view : Model -> Html.Html Msg
view model =
  Html.div [] [
    Html.ul [] (List.map noteView model.notes)
    , newNoteView model.new
  ]

newNoteView note =
  Html.div [] [
    Html.form [ onSubmit Insert ] [
      Html.input [ placeholder "Title", value note.title.text, onInput (UpdateNew "title") ] []
      , Html.br [] []
      , Html.textarea [ placeholder "Body", value note.body.text, onInput (UpdateNew "body") ] []
      , Html.br [] []
      , Html.button [ type_ "submit" ] [ Html.text "Create" ]
    ]
  ]

noteView note =
  Html.li [] (
    [
      Html.button [ style [ ("float", "right") ], onClick (Delete note.id) ] [ Html.text "X" ],
      textInputView note.id "title" note.title,
      textInputView note.id "body" note.body
    ]
  )

textInputView noteId field data =
  if data.editing then
    Html.div [] [
      Html.textarea [ id ("note-" ++ toString noteId), onInput (Update noteId field), onBlur (Edit noteId field False) ] [ Html.text data.text ] ]
  else
    Html.div [ onClick (Edit noteId field True) ] [ Html.text data.text ]

