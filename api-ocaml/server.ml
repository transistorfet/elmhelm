

open Lwt.Infix
open Cohttp
open Cohttp_lwt_unix
open Yojson.Basic
open Sqlite3

type note = {
  id: int;
  title: string;
  body: string
}

let run_query sql callback =
  let db = db_open "data.db" in
  Printf.printf "%s\n%!" sql;
  match exec_not_null db sql ~cb:callback with
  | Rc.OK -> ()
  | _ -> begin
    Printf.printf "\nDatabase Error: %s\n%!" (Sqlite3.errmsg db);
    assert false
  end


let cors_headers () =
  Cohttp.Header.add_list (Cohttp.Header.init ()) [
    ("access-control-allow-origin", "*");
    ("access-control-allow-headers", "Accept, Content-Type");
    ("access-control-allow-methods", "GET, HEAD, POST, DELETE, OPTIONS, PUT, PATCH")
  ]

let respond_with_string ?status:(status=`OK) ~body () =
  Server.respond_string ~status ~body ~headers:(cors_headers ()) ()



let get_notes _req _body =
  let notes = ref [] in
  run_query "SELECT * FROM notes" begin fun row _headers ->
    let note = {
      id = (Array.get row 0) |> int_of_string;
      title = (Array.get row 1);
      body = (Array.get row 2) } in
    notes := note :: !notes
  end;
  notes := List.rev !notes;
  let jres = pretty_to_string (`List (List.map (fun note ->
    `Assoc [ ("id", `Int note.id); ("title", `String note.title); ("body", `String note.body) ]) !notes)) in
  respond_with_string ~body:jres ()

let add_note _req body =
  Printf.printf "%s\n%!" body;
  let json = Yojson.Basic.from_string body in
  let open Yojson.Basic.Util in
  let title = json |> member "title" |> to_string in
  let body = json |> member "body" |> to_string in
  run_query (Printf.sprintf "INSERT INTO notes (title, body) VALUES ('%s', '%s')" title body) (fun _row _headers -> ());
  respond_with_string  ~body:"" ()

let update_note _req body params =
  Printf.printf "%s\n%!" body;
  let json = Yojson.Basic.from_string body in
  let open Yojson.Basic.Util in
  let title = json |> member "title" |> to_string in
  let body = json |> member "body" |> to_string in
  run_query (Printf.sprintf "UPDATE notes SET title = '%s', body = '%s' WHERE id = %s" title body (List.hd params)) (fun _row _headers -> ());
  respond_with_string ~body:"" ()

let update_field id field json =
  let open Yojson.Basic.Util in
  let value = json |> member field |> to_string in
  run_query (Printf.sprintf "UPDATE notes SET %s = '%s' WHERE id = %s" field value id) (fun _row _headers -> ());
  respond_with_string ~body:"" ()

let update_note_field _req body params =
  let json = Yojson.Basic.from_string body in
  match params with
  | id :: "title" :: [] -> update_field id "title" json
  | id :: "body" :: [] -> update_field id "body" json
  | _ -> respond_with_string ~status:`Bad_request ~body:"" ()

let delete_note _req body params =
  Printf.printf "%s\n%!" body;
  run_query (Printf.sprintf "DELETE FROM notes WHERE id = %s" (List.hd params)) (fun _row _headers -> ());
  respond_with_string ~body:"" ()



let match_route regexp path =
  Str.string_match (Str.regexp regexp) path 0

let route_params path =
  let rec group n l =
    try
      let nl = (Str.matched_group n path) :: l in
      group (n + 1) nl
    with Invalid_argument _ ->
      l
  in
    group 1 [] |> List.rev

let route req body =
  match (Request.meth req, Uri.path (Request.uri req)) with
  | (`GET, "/api/notes") -> get_notes req body
  | (`PUT, "/api/notes") -> add_note req body
  | (`POST, path) when match_route "^/api/notes/\\([0-9]+\\)$" path -> update_note req body (route_params path)
  | (`POST, path) when match_route "^/api/notes/\\([0-9]+\\)/\\([A-Za-z0-9]+\\)$" path -> update_note_field req body (route_params path)
  | (`DELETE, path) when match_route "^/api/notes/\\([0-9]+\\)$" path -> delete_note req body (route_params path)
  | (`OPTIONS, _) -> respond_with_string ~body:"" ()
  | _ -> respond_with_string ~status:`Not_found ~body:"Not Found" ()


let server_callback _conn req body =
  let uri = req |> Request.uri |> Uri.to_string in
  let meth = req |> Request.meth |> Code.string_of_method in
  Printf.printf "%s: %s\n" meth uri;
  body |> Cohttp_lwt.Body.to_string >>= fun body -> route req body


let run_server =
  print_endline "Ocaml HTTP server started on port 8088\n";
  Server.create ~mode:(`TCP (`Port 8088)) (Server.make ~callback:server_callback ())

let () =
  ignore (Lwt_main.run run_server)


