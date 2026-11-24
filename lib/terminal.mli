(** Terminal rendering and keyboard input for the escape room game. *)

type command = Up | Left | Down | Right | Undo | Restart | Hint | Quit

val command_of_char : char -> command option
(** [command_of_char c] returns the command bound to [c], ignoring case,
    or [None] if [c] is not a recognized command. *)

val render : grid:string list -> inventory:string list -> moves:int -> string
(** [render ~grid ~inventory ~moves] formats the grid, inventory, move count,
    and controls. Each string in [grid] is one row, with the player already
    marked by [@]. *)

val draw : grid:string list -> inventory:string list -> moves:int -> unit
(** Displays a rendered view, clearing the screen when output is a terminal. *)

val with_input : (unit -> 'a) -> 'a
(** Runs a function with single-key, non-echoing input when stdin is a terminal.
    Restores the original terminal settings on return or exception. If terminal
    settings are unavailable, input uses the normal line-buffered behavior. *)

val read_command : unit -> command
(** Reads until a recognized command is entered. End of input returns [Quit].
    Use within [with_input] for single-key input. *)
