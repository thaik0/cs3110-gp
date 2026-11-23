open Level

type error =
  | Cannot_read of string
  | Syntax of {
      line : int;
      message : string;
    }
  | Invalid_level of string

let error_to_string = function
  | Cannot_read msg -> "cannot read level file: " ^ msg
  | Syntax { line; message } -> Printf.sprintf "line %d: %s" line message
  | Invalid_level msg -> "invalid level: " ^ msg

let ( let* ) = Result.bind
let syntax line fmt = Printf.ksprintf (fun message -> Error (Syntax { line; message })) fmt

(* The four kinds of labelled tile, in the order their header lines are
   written. *)
type kind = K_key | K_door | K_switch | K_gate

let kinds = [ K_key; K_door; K_switch; K_gate ]

let header_of_kind = function
  | K_key -> "keys"
  | K_door -> "doors"
  | K_switch -> "switches"
  | K_gate -> "gates"

let symbol_of_kind = function
  | K_key -> "k"
  | K_door -> "D"
  | K_switch -> "s"
  | K_gate -> "G or g"

(* Labels used for a kind whose header line is left out. *)
let default_label = "default"

let is_space c = c = ' ' || c = '\t' || c = '\r'

let rstrip s =
  let n = ref (String.length s) in
  while !n > 0 && is_space s.[!n - 1] do
    decr n
  done;
  String.sub s 0 !n

let words s = List.filter (( <> ) "") (String.split_on_char ' ' (String.trim s))

(* ---------- Header: everything before the "map:" line ---------- *)

type header = {
  name : string option;
  labels : (kind * (int * string list)) list;
      (* each kind's labels, with the line they were written on *)
}

(* [parse_header hdr lines] reads header lines up to "map:". Returns the
   header, the line number of "map:", and the numbered lines after it. *)
let rec parse_header hdr = function
  | [] -> syntax 1 "missing \"map:\" line before the grid"
  | (n, raw) :: rest -> (
      let line = String.trim raw in
      if line = "" || line.[0] = ';' then parse_header hdr rest
      else
        match String.index_opt line ':' with
        | None -> syntax n "expected \"field: value\" or \"map:\", got %S" line
        | Some i -> (
            let field = String.trim (String.sub line 0 i) in
            let value = String.sub line (i + 1) (String.length line - i - 1) in
            match field with
            | "map" ->
                if String.trim value <> "" then
                  syntax n "nothing may follow \"map:\" on the same line"
                else Ok (hdr, n, rest)
            | "name" -> (
                if hdr.name <> None then syntax n "\"name\" is given twice"
                else
                  match words value with
                  | [ w ] -> parse_header { hdr with name = Some w } rest
                  | [] -> syntax n "\"name\" is empty"
                  | _ -> syntax n "the name must be one word, got %S" (String.trim value))
            | _ -> (
                match List.find_opt (fun k -> header_of_kind k = field) kinds with
                | None -> syntax n "unknown field %S" field
                | Some k ->
                    if List.mem_assoc k hdr.labels then
                      syntax n "%S is given twice" field
                    else
                      parse_header
                        { hdr with labels = (k, (n, words value)) :: hdr.labels }
                        rest)))

(* ---------- Map: the grid of symbols ---------- *)

(* A square as read from the map, before labels are attached. *)
type cell = Plain of tile | Start | Labelled of kind * bool

let cell_of_char = function
  | '#' -> Some (Plain Wall)
  | '.' | ' ' -> Some (Plain Floor)
  | 'E' -> Some (Plain Exit)
  | '@' -> Some Start
  | 'k' -> Some (Labelled (K_key, false))
  | 'D' -> Some (Labelled (K_door, false))
  | 's' -> Some (Labelled (K_switch, false))
  | 'G' -> Some (Labelled (K_gate, false))
  | 'g' -> Some (Labelled (K_gate, true))
  | _ -> None

(* Drop blank lines at the end of the file, then reject any blank line left
   inside the grid. *)
let map_lines map_line lines =
  let lines = List.map (fun (n, l) -> (n, rstrip l)) lines in
  let rec drop_blank = function (_, "") :: t -> drop_blank t | l -> l in
  let lines = List.rev (drop_blank (List.rev lines)) in
  match List.find_opt (fun (_, l) -> l = "") lines with
  | Some (n, _) -> syntax n "blank line inside the map"
  | None -> (
      match lines with
      | [] -> syntax map_line "the map is empty"
      | _ -> Ok lines)

let parse_row (n, line) =
  let cells = ref [] in
  let bad = ref None in
  String.iteri
    (fun i c ->
      match cell_of_char c with
      | Some cell -> cells := cell :: !cells
      | None -> if !bad = None then bad := Some (i, c))
    line;
  match !bad with
  | Some (i, c) -> syntax n "unknown symbol %C in column %d" c (i + 1)
  | None -> Ok (List.rev !cells)

let parse_map map_line lines =
  let* lines = map_lines map_line lines in
  let width = String.length (snd (List.hd lines)) in
  let* rows =
    List.fold_left
      (fun acc ((n, line) as l) ->
        let* rows = acc in
        if String.length line <> width then
          syntax n "this row is %d characters wide but the first row is %d"
            (String.length line) width
        else
          let* row = parse_row l in
          Ok ((n, row) :: rows))
      (Ok []) lines
  in
  Ok (List.rev rows)

(* Find the single "@" and return its position. *)
let find_start rows first_line =
  let starts =
    List.concat
      (List.mapi
         (fun row (n, cells) ->
           List.concat
             (List.mapi
                (fun col c -> if c = Start then [ (n, { row; col }) ] else [])
                cells))
         rows)
  in
  match starts with
  | [ (_, p) ] -> Ok p
  | [] -> syntax first_line "the map has no start square (@)"
  | _ :: (n, _) :: _ -> syntax n "the map has more than one start square (@)"

(* ---------- Attaching labels in reading order ---------- *)

let count_kind rows k =
  List.fold_left
    (fun acc (_, cells) ->
      acc + List.length (List.filter (function Labelled (k', _) -> k' = k | _ -> false) cells))
    0 rows

(* The labels for each kind, in reading order, after checking that the
   header lists exactly one label per tile. *)
let labels_for hdr rows k =
  let count = count_kind rows k in
  match List.assoc_opt k hdr.labels with
  | None -> Ok (List.init count (fun _ -> default_label))
  | Some (n, ls) ->
      if List.length ls = count then Ok ls
      else
        syntax n "%S lists %d label(s) but the map has %d %s tile(s)"
          (header_of_kind k) (List.length ls) count (symbol_of_kind k)

let attach_labels hdr rows =
  let* queues =
    List.fold_left
      (fun acc k ->
        let* qs = acc in
        let* ls = labels_for hdr rows k in
        Ok ((k, ref ls) :: qs))
      (Ok []) kinds
  in
  let next k =
    let q = List.assoc k queues in
    match !q with
    | l :: rest ->
        q := rest;
        l
    | [] -> assert false (* counts were checked in [labels_for] *)
  in
  let tile_of_cell = function
    | Plain t -> t
    | Start -> Floor
    | Labelled (K_key, _) -> Key (next K_key)
    | Labelled (K_door, _) -> Door (next K_door)
    | Labelled (K_switch, _) -> Switch (next K_switch)
    | Labelled (K_gate, starts_open) -> Gate (next K_gate, starts_open)
  in
  Ok (List.map (fun (_, cells) -> List.map tile_of_cell cells) rows)

(* ---------- Putting it together ---------- *)

let parse ?(default_name = "unnamed") text =
  let lines = List.mapi (fun i l -> (i + 1, l)) (String.split_on_char '\n' text) in
  let* hdr, map_line, rest = parse_header { name = None; labels = [] } lines in
  let* rows = parse_map map_line rest in
  let* start = find_start rows map_line in
  let* tiles = attach_labels hdr rows in
  let name = Option.value hdr.name ~default:default_name in
  match Level.make ~name ~start tiles with
  | Ok lvl -> Ok lvl
  | Error msg -> Error (Invalid_level msg)

let name_of_path path =
  let base = Filename.remove_extension (Filename.basename path) in
  String.map (fun c -> if is_space c then '_' else c) base

let read_file path =
  try Ok (In_channel.with_open_bin path In_channel.input_all)
  with Sys_error msg -> Error (Cannot_read msg)

let load path =
  let* text = read_file path in
  parse ~default_name:(name_of_path path) text

let to_string lvl =
  let labels_of k =
    List.filter_map
      (fun (_, t) ->
        match (k, t) with
        | K_key, Key l | K_door, Door l | K_switch, Switch l | K_gate, Gate (l, _) ->
            Some l
        | _ -> None)
      (Level.tiles lvl)
  in
  let header_lines =
    List.filter_map
      (fun k ->
        match labels_of k with
        | [] -> None
        | ls -> Some (header_of_kind k ^ ": " ^ String.concat " " ls))
      kinds
  in
  String.concat "\n"
    ((("name: " ^ Level.name lvl) :: header_lines) @ ("map:" :: Level.to_rows lvl))
  ^ "\n"
