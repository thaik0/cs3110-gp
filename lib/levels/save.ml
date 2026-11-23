module M = Map.Make (String)

(* AF: a map from level id to the fewest moves recorded for that level.
   RI: every key satisfies [valid_id] and every value is >= 0. *)
type t = int M.t

type error =
  | Io of string
  | Corrupt of {
      line : int;
      message : string;
    }

let error_to_string = function
  | Io msg -> "cannot access save file: " ^ msg
  | Corrupt { line; message } ->
      Printf.sprintf "save file is damaged (line %d): %s" line message

let magic = "escape-room-save"
let version = "1"
let empty = M.empty

let valid_id id =
  id <> ""
  && String.for_all (fun c -> not (List.mem c [ ' '; '\t'; '\n'; '\r' ])) id

let best p id = M.find_opt id p

let record p id moves =
  if not (valid_id id) then invalid_arg ("Save.record: invalid level id " ^ id);
  if moves < 0 then invalid_arg "Save.record: negative move count";
  M.update id
    (function Some old -> Some (min old moves) | None -> Some moves)
    p

let bests p = M.bindings p

let to_string p =
  String.concat ""
    (Printf.sprintf "%s %s\n" magic version
    :: List.map (fun (id, n) -> Printf.sprintf "best %s %d\n" id n) (bests p))

let ( let* ) = Result.bind
let corrupt line fmt = Printf.ksprintf (fun message -> Error (Corrupt { line; message })) fmt
let words s = List.filter (( <> ) "") (String.split_on_char ' ' (String.trim s))

let parse_entry p (n, line) =
  match words line with
  | [] -> Ok p
  | [ "best"; id; moves ] -> (
      match int_of_string_opt moves with
      | Some m when m >= 0 ->
          if M.mem id p then corrupt n "level %S appears twice" id
          else Ok (M.add id m p)
      | _ -> corrupt n "move count %S is not a non-negative whole number" moves)
  | _ -> corrupt n "expected \"best <level> <moves>\", got %S" (String.trim line)

let of_string text =
  let lines =
    List.mapi
      (fun i l -> (i + 1, String.trim l))
      (String.split_on_char '\n' text)
  in
  match lines with
  | (_, first) :: rest -> (
      match words first with
      | [ m; v ] when m = magic ->
          if v <> version then corrupt 1 "unsupported save version %S" v
          else
            List.fold_left
              (fun acc entry ->
                let* p = acc in
                parse_entry p entry)
              (Ok empty) rest
      | _ -> corrupt 1 "this is not an escape room save file")
  | [] -> corrupt 1 "this is not an escape room save file"

let load path =
  if not (Sys.file_exists path) then Ok empty
  else
    match In_channel.with_open_bin path In_channel.input_all with
    | text -> of_string text
    | exception Sys_error msg -> Error (Io msg)

let save path p =
  let tmp = path ^ ".tmp" in
  try
    Out_channel.with_open_bin tmp (fun oc -> output_string oc (to_string p));
    Sys.rename tmp path;
    Ok ()
  with Sys_error msg -> Error (Io msg)
