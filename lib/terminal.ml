type command = Up | Left | Down | Right | Undo | Restart | Hint | Quit

let command_of_char c =
  match Char.lowercase_ascii c with
  | 'w' -> Some Up
  | 'a' -> Some Left
  | 's' -> Some Down
  | 'd' -> Some Right
  | 'u' -> Some Undo
  | 'r' -> Some Restart
  | 'h' -> Some Hint
  | 'q' -> Some Quit
  | _ -> None

let render ~grid ~inventory ~moves =
  let items =
    match inventory with
    | [] -> "(empty)"
    | _ -> String.concat ", " inventory
  in
  String.concat "\n"
    ([ "Escape Room"; "" ] @ grid
    @ [ ""; "Inventory: " ^ items; "Moves: " ^ string_of_int moves;
        ""; "WASD: move | U: undo | R: restart | H: hint | Q: quit"; "" ])

let draw ~grid ~inventory ~moves =
  if Unix.isatty Unix.stdout then print_string "\027[2J\027[H";
  print_string (render ~grid ~inventory ~moves);
  flush stdout

let with_input f =
  let original =
    try
      if Unix.isatty Unix.stdin then Some (Unix.tcgetattr Unix.stdin)
      else None
    with Unix.Unix_error _ -> None
  in
  match original with
  | None -> f ()
  | Some settings ->
      let single_key =
        { settings with c_icanon = false; c_echo = false; c_vmin = 1; c_vtime = 0 }
      in
      let enabled =
        try
          Unix.tcsetattr Unix.stdin Unix.TCSANOW single_key;
          true
        with Unix.Unix_error _ -> false
      in
      if enabled then
        Fun.protect f ~finally:(fun () ->
            Unix.tcsetattr Unix.stdin Unix.TCSANOW settings)
      else f ()

let rec read_command () =
  match input_char stdin with
  | exception End_of_file -> Quit
  | c -> (
      match command_of_char c with
      | Some command -> command
      | None -> read_command ())
