(* These checks connect real level files to the team's rules and solver.
   The conversion below is test-only until the shared adapter is merged. *)
module L = Levels.Level
module R = Escape.Rules
module S = Escape.Solver

let check condition message = if not condition then failwith message

let read_file path =
  let channel = open_in path in
  Fun.protect
    ~finally:(fun () -> close_in channel)
    (fun () -> really_input_string channel (in_channel_length channel))

let load path =
  match Levels.Level_file.load path with
  | Ok level -> level
  | Error error -> failwith (Levels.Level_file.error_to_string error)

let rules_level source =
  let labels =
    L.tiles source
    |> List.filter_map (function
      | _, (L.Key name | L.Door name) -> Some name
      | _ -> None)
    |> List.sort_uniq String.compare
  in
  let id name =
    let rec find i = function
      | [] -> failwith "Missing label"
      | x :: rest -> if x = name then i else find (i + 1) rest
    in
    find 0 labels
  in
  let tile = function
    | L.Wall -> R.Wall
    | L.Floor -> R.Floor
    | L.Exit -> R.Exit
    | L.Key name -> R.Key (id name)
    | L.Door name -> R.Door (id name)
    | L.Switch _ | L.Gate _ -> failwith "These fixtures use keys and doors only"
  in
  let grid =
    Array.init (L.height source) (fun row ->
        Array.init (L.width source) (fun col ->
            tile (L.tile_at source { row; col })))
  in
  let start = L.start source in
  R.make_level grid { row = start.row; col = start.col }

let replay state path =
  List.fold_left
    (fun state direction ->
      match R.move state direction with
      | R.Moved next -> next
      | R.Blocked _ -> failwith "Path contains a blocked move")
    state path

let check_level n =
  let prefix = Printf.sprintf "../benchmarks/locks-%d" n in
  let source = load (prefix ^ ".txt") in
  check
    (L.width source = (6 * n) + 3 && L.height source = 7 + (2 * n))
    "Wrong dimensions";
  let count predicate =
    List.length (List.filter (fun (_, t) -> predicate t) (L.tiles source))
  in
  check (count (function L.Key _ -> true | _ -> false) = n) "Key count";
  check (count (function L.Door _ -> true | _ -> false) = n) "Door count";
  let level = rules_level source in
  let moves = String.trim (read_file (prefix ^ ".moves")) in
  let path =
    String.to_seq moves |> List.of_seq
    |> List.map (fun c ->
        match R.direction_of_char c with
        | Some direction -> direction
        | None -> failwith "Unknown witness command")
  in
  let expected = n * ((2 * (L.height source - 3)) + 6) in
  check (List.length path = expected) "Witness length";
  let won = replay (R.init level) path in
  check (R.is_won won) "Witness misses exit";
  check
    (List.length (R.keys_held won) = n)
    "Witness must collect each distinct key";
  let result = S.search (R.init level) in
  (match result.path with
  | None -> failwith "Solver cannot solve fixture"
  | Some solution ->
      check
        (R.is_won (replay (R.init level) solution))
        "Solver path misses exit";
      check (List.length solution = expected) "Unexpected shortest path length");
  Printf.printf
    "Level %d: real loader, witness, and solver pass; par %d; %d states\n" n
    expected result.explored

let () = List.iter check_level [ 1; 2; 3; 4; 5 ]
