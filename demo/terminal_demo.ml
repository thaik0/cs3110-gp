(* A standalone terminal experiment, not the game engine. *)
let grid = [ "#########"; "#@  k  D#"; "#       #"; "#      E#"; "#########" ]

let command_name = function
  | Terminal.Up -> "up"
  | Terminal.Left -> "left"
  | Terminal.Down -> "down"
  | Terminal.Right -> "right"
  | Terminal.Undo -> "undo"
  | Terminal.Restart -> "restart"
  | Terminal.Hint -> "hint"
  | Terminal.Quit -> "quit"

let rec loop () =
  match Terminal.read_command () with
  | Terminal.Quit -> print_endline "Goodbye!"
  | command ->
      Printf.printf "Received: %s\n%!" (command_name command);
      loop ()

let () =
  Sys.catch_break true;
  Terminal.draw ~grid ~inventory:[ "red key" ] ~moves:3;
  try Terminal.with_input loop with Sys.Break -> print_endline "Goodbye!"
