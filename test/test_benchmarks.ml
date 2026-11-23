(* Structural and witness checks for fixtures, not the team's game engine. *)

let read_file path =
  let channel = open_in path in
  Fun.protect
    ~finally:(fun () -> close_in channel)
    (fun () -> really_input_string channel (in_channel_length channel))

let check condition message = if not condition then failwith message

let check_level n =
  let prefix = Printf.sprintf "../benchmarks/locks-%d" n in
  let rows = String.split_on_char '\n' (String.trim (read_file (prefix ^ ".txt"))) in
  let grid = Array.of_list (List.map Bytes.of_string rows) in
  let height = Array.length grid in
  let width = Bytes.length grid.(0) in
  check (height = 7 + (2 * n) && width = 6 * n + 3) "Wrong dimensions";
  let count symbol =
    Array.fold_left
      (fun total row ->
        Bytes.fold_left (fun total c -> total + if c = symbol then 1 else 0)
          total row)
      0 grid
  in
  Array.iteri
    (fun y row ->
      check (Bytes.length row = width) "Nonrectangular level";
      Bytes.iteri
        (fun x c ->
          check (String.contains "# @kDE" c) "Unknown symbol";
          if x = 0 || y = 0 || x = width - 1 || y = height - 1 then
            check (c = '#') "Open boundary")
        row)
    grid;
  check (count '@' = 1 && count 'E' = 1) "Start/exit count";
  check (count 'k' = n && count 'D' = n) "Key/door count";
  let x = ref 0 and y = ref 0 and keys = ref 0 in
  Array.iteri
    (fun row cells ->
      Bytes.iteri
        (fun col c -> if c = '@' then (x := col; y := row))
        cells)
    grid;
  let moves = String.trim (read_file (prefix ^ ".moves")) in
  check (String.length moves = n * ((2 * (height - 3)) + 6))
    "Unexpected witness length";
  String.iter
    (fun move ->
      let dx, dy =
        match move with
        | 'w' -> (0, -1)
        | 'a' -> (-1, 0)
        | 's' -> (0, 1)
        | 'd' -> (1, 0)
        | _ -> failwith "Unknown move"
      in
      x := !x + dx;
      y := !y + dy;
      check (!x >= 0 && !x < width && !y >= 0 && !y < height)
        "Witness leaves grid";
      let cell = Bytes.get grid.(!y) !x in
      check (cell <> '#') "Witness hits wall";
      if cell = 'D' then (
        check (!keys > 0) "Witness reaches locked door without key";
        decr keys;
        Bytes.set grid.(!y) !x ' ');
      if cell = 'k' then (
        incr keys;
        Bytes.set grid.(!y) !x ' '))
    moves;
  check (Bytes.get grid.(!y) !x = 'E') "Witness misses exit";
  check (count 'k' = 0 && count 'D' = 0 && !keys = 0)
    "Witness did not use every key and door";
  Printf.printf "Level %d: structure and %d-move witness pass\n" n
    (String.length moves)

let () = List.iter check_level [ 1; 2; 3; 4; 5 ]
