type pos = {
  row : int;
  col : int;
}

type tile =
  | Floor
  | Wall
  | Exit
  | Key of string
  | Door of string
  | Switch of string
  | Gate of string * bool

(* AF: [{ name; grid; start; exit }] is the level called [name] where the tile
   at row [r], column [c] is [grid.(r).(c)], the player starts at [start], and
   the exit is at [exit].
   RI: [grid] is a rectangle at least 3x3 whose edge squares are all [Wall];
   [start] is a [Floor] square; [exit] is the only [Exit] square; every [Door]
   label is also a [Key] label; [Switch] labels and [Gate] labels are the same
   set. [grid] is never exposed, so no caller can mutate it. *)
type t = {
  name : string;
  grid : tile array array;
  start : pos;
  exit : pos;
}

let name lvl = lvl.name
let height lvl = Array.length lvl.grid
let width lvl = Array.length lvl.grid.(0)
let start lvl = lvl.start
let exit lvl = lvl.exit

let in_bounds lvl p =
  p.row >= 0 && p.row < height lvl && p.col >= 0 && p.col < width lvl

let tile_at lvl p = if in_bounds lvl p then lvl.grid.(p.row).(p.col) else Wall

(* All squares of [grid] in reading order. *)
let all_squares grid =
  grid
  |> Array.to_list
  |> List.mapi (fun row cells ->
         cells |> Array.to_list |> List.mapi (fun col t -> ({ row; col }, t)))
  |> List.concat

let tiles lvl =
  List.filter
    (fun (_, t) -> t <> Floor && t <> Wall)
    (all_squares lvl.grid)

let char_of_tile = function
  | Floor -> ' '
  | Wall -> '#'
  | Exit -> 'E'
  | Key _ -> 'k'
  | Door _ -> 'D'
  | Switch _ -> 's'
  | Gate (_, false) -> 'G'
  | Gate (_, true) -> 'g'

let to_rows lvl =
  Array.to_list
    (Array.mapi
       (fun row cells ->
         String.init (Array.length cells) (fun col ->
             if { row; col } = lvl.start then '@' else char_of_tile cells.(col)))
       lvl.grid)

(* ---------- Checking a layout in [make] ---------- *)

let ( let* ) = Result.bind
let fail fmt = Printf.ksprintf (fun msg -> Error msg) fmt
let check cond fmt = Printf.ksprintf (fun msg -> if cond then Ok () else Error msg) fmt

let check_shape rows =
  match rows with
  | [] -> fail "the level has no rows"
  | first :: _ ->
      let w = List.length first in
      let* () = check (List.length rows >= 3) "the level must have at least 3 rows" in
      let* () = check (w >= 3) "the level must have at least 3 columns" in
      let bad =
        List.find_index (fun r -> List.length r <> w) rows
      in
      (match bad with
      | Some i ->
          fail "row %d has %d squares but row 0 has %d" i
            (List.length (List.nth rows i)) w
      | None -> Ok ())

let check_border grid =
  let h = Array.length grid and w = Array.length grid.(0) in
  let on_edge { row; col } = row = 0 || col = 0 || row = h - 1 || col = w - 1 in
  match
    List.find_opt
      (fun (p, t) -> on_edge p && t <> Wall)
      (all_squares grid)
  with
  | Some (p, _) ->
      fail "the edge of the level must be walls, but row %d column %d is not"
        p.row p.col
  | None -> Ok ()

let check_start grid start =
  let h = Array.length grid and w = Array.length grid.(0) in
  if start.row < 0 || start.row >= h || start.col < 0 || start.col >= w then
    fail "the start (row %d, column %d) is outside the level" start.row start.col
  else
    check
      (grid.(start.row).(start.col) = Floor)
      "the start (row %d, column %d) must be on an empty floor square" start.row
      start.col

let find_exit grid =
  match List.filter (fun (_, t) -> t = Exit) (all_squares grid) with
  | [ (p, _) ] -> Ok p
  | [] -> fail "the level has no exit"
  | _ :: _ :: _ -> fail "the level has more than one exit"

(* Labels of every tile that [pick] selects, without duplicates. *)
let labels grid pick =
  List.sort_uniq compare (List.filter_map (fun (_, t) -> pick t) (all_squares grid))

let check_labels grid =
  let keys = labels grid (function Key l -> Some l | _ -> None) in
  let doors = labels grid (function Door l -> Some l | _ -> None) in
  let switches = labels grid (function Switch l -> Some l | _ -> None) in
  let gates = labels grid (function Gate (l, _) -> Some l | _ -> None) in
  let missing xs ys = List.find_opt (fun x -> not (List.mem x ys)) xs in
  match (missing doors keys, missing switches gates, missing gates switches) with
  | Some l, _, _ -> fail "door %S has no key with the same label" l
  | _, Some l, _ -> fail "switch %S has no gate with the same label" l
  | _, _, Some l -> fail "gate %S has no switch with the same label" l
  | None, None, None -> Ok ()

let valid_name name =
  name <> "" && String.for_all (fun c -> c <> ' ' && c <> '\t' && c <> '\n' && c <> '\r') name

let make ~name ~start rows =
  let* () = check (valid_name name) "the name %S must be one word with no spaces" name in
  let* () = check_shape rows in
  let grid = Array.of_list (List.map Array.of_list rows) in
  let* () = check_border grid in
  let* () = check_start grid start in
  let* exit = find_exit grid in
  let* () = check_labels grid in
  Ok { name; grid; start; exit }
