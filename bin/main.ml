module Rules = Escape.Rules
module Engine = Escape.Engine
module Save = Levels.Save

let fail message =
  prerr_endline message;
  exit 1

let grid state =
  let level = Rules.level state in
  let player = Rules.player state in
  List.init (Rules.rows level) (fun row ->
      String.init (Rules.cols level) (fun col ->
          let pos : Rules.pos = { row; col } in
          if pos = player then '@'
          else
            match Rules.current_tile state pos with
            | Rules.Door id when Rules.has_key state id -> 'd'
            | Rules.Gate id when Rules.gate_open state id -> '_'
            | tile -> Rules.char_of_tile tile))

let blocked_message adapter = function
  | Rules.Out_of_bounds | Rules.Hit_wall -> "Can't move there."
  | Rules.Locked_door id -> "Need the " ^ Level_adapter.label adapter id ^ " key."
  | Rules.Closed_gate id -> "Gate is closed: " ^ Level_adapter.label adapter id
  | Rules.Already_won -> "Level already completed."

let play adapter name save_path progress =
  let rec loop game message =
    let state = Engine.current game in
    let inventory =
      List.map
        (fun id -> Level_adapter.label adapter id ^ " key")
        (Rules.keys_held state)
    in
    Terminal.draw ~grid:(grid state) ~inventory ~moves:(Rules.moves state);
    Option.iter print_endline message;
    if Engine.is_won game then (
      Printf.printf "You escaped in %d moves!\n" (Rules.moves state);
      let progress = Save.record progress name (Rules.moves state) in
      (match Save.best progress name with
      | Some best -> Printf.printf "Best: %d moves\n" best
      | None -> ());
      match Save.save save_path progress with
      | Ok () -> ()
      | Error error -> prerr_endline (Save.error_to_string error))
    else (
      flush stdout;
      let move direction =
        let next, blocked = Engine.step game direction in
        loop next (Option.map (blocked_message adapter) blocked)
      in
      match Terminal.read_command () with
      | Terminal.Up -> move Rules.Up
      | Terminal.Down -> move Rules.Down
      | Terminal.Left -> move Rules.Left
      | Terminal.Right -> move Rules.Right
      | Terminal.Undo -> (
          match Engine.undo game with
          | Some previous -> loop previous None
          | None -> loop game (Some "Nothing to undo."))
      | Terminal.Restart -> loop (Engine.restart game) None
      | Terminal.Hint -> loop game (Some "Hints will be available after solver integration.")
      | Terminal.Quit -> print_endline "Goodbye!")
  in
  Terminal.with_input (fun () ->
      loop (Engine.start (Level_adapter.level adapter)) None)

let () =
  let level_path, save_path =
    match Array.to_list Sys.argv with
    | [ _ ] -> ("levels/demo.txt", "escape-room.save")
    | [ _; path ] -> (path, "escape-room.save")
    | [ _; path; save ] -> (path, save)
    | _ -> fail "Usage: main.exe [level-file] [save-file]"
  in
  let source =
    match Levels.Level_file.load level_path with
    | Ok level -> level
    | Error error -> fail (Levels.Level_file.error_to_string error)
  in
  let adapter =
    match Level_adapter.of_level source with
    | Ok adapter -> adapter
    | Error message -> fail message
  in
  let progress =
    match Save.load save_path with
    | Ok progress -> progress
    | Error error -> fail (Save.error_to_string error)
  in
  Sys.catch_break true;
  try play adapter (Levels.Level.name source) save_path progress
  with Sys.Break -> print_endline "Goodbye!"
