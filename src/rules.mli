(** The shared game rules.

    This module is the single source of truth for how the game works. The
    game engine uses it to play a level, and the solver uses it to search
    one, so the rules the solver plans with are exactly the rules the player
    plays by.

    Everything here is immutable: every function returns a new value and
    never changes its input. *)

(** {1 Positions and directions} *)

type pos = {
  row : int;  (** 0 is the top row *)
  col : int;  (** 0 is the leftmost column *)
}
(** A square on the grid. *)

type direction =
  | Up
  | Down
  | Left
  | Right

val all_directions : direction list
(** [all_directions] is [[Up; Down; Left; Right]]. *)

val step_pos : pos -> direction -> pos
(** [step_pos p d] is the square next to [p] in direction [d]. It does not
    check that the result is inside the grid. *)

val direction_of_char : char -> direction option
(** [direction_of_char c] maps ['w'], ['a'], ['s'], ['d'] (either case) to
    [Up], [Left], [Down], [Right]. Any other character gives [None]. *)

(** {1 Tiles and levels} *)

(** What a square holds. Keys, doors, switches, and gates carry an id. A key
    with id [n] opens every door with id [n]. Stepping on the switch with id
    [n] flips every gate with id [n] between closed and open. *)
type tile =
  | Floor
  | Wall
  | Exit
  | Key of int
  | Door of int
  | Switch of int
  | Gate of int

type level
(** A level: a rectangular grid of tiles plus a start square. A value of
    this type is always valid (see {!make_level}). *)

exception Invalid_level of string
(** Raised by {!make_level} with a message saying what is wrong. *)

val make_level : tile array array -> pos -> level
(** [make_level grid start] is the level with rows [grid] where the player
    starts at [start]. The grid is copied, so changing [grid] afterwards does
    not change the level.

    Raises [Invalid_level] if the grid has no rows, the rows are empty or of
    different lengths, [start] is outside the grid or not a [Floor] tile, or
    the grid has no [Exit]. *)

val rows : level -> int
(** [rows lvl] is the number of rows in [lvl]. *)

val cols : level -> int
(** [cols lvl] is the number of columns in [lvl]. *)

val start : level -> pos
(** [start lvl] is where the player begins. *)

val in_bounds : level -> pos -> bool
(** [in_bounds lvl p] is whether [p] is inside the grid. *)

val tile_at : level -> pos -> tile
(** [tile_at lvl p] is the original tile at [p], before any keys are picked
    up. Raises [Invalid_argument] if [p] is out of bounds. *)

(** {1 Game states} *)

type state
(** Where the player is, which keys they hold, which switches are on, and
    how many moves they have made. *)

val init : level -> state
(** [init lvl] is the state at the start of [lvl]: player on the start
    square, no keys, every switch off (so every gate closed), zero moves. *)

val level : state -> level
(** [level s] is the level [s] is being played on. *)

val player : state -> pos
(** [player s] is the player's square. *)

val keys_held : state -> int list
(** [keys_held s] is the ids of the keys the player has, in increasing
    order with no duplicates. *)

val has_key : state -> int -> bool
(** [has_key s n] is whether the player holds key [n]. *)

val switch_on : state -> int -> bool
(** [switch_on s n] is whether switch group [n] is on. *)

val gate_open : state -> int -> bool
(** [gate_open s n] is whether the gates with id [n] are open. Gates start
    closed and are open exactly when switch group [n] is on. *)

val moves : state -> int
(** [moves s] is the number of successful moves made so far. Blocked moves
    do not count. *)

val current_tile : state -> pos -> tile
(** [current_tile s p] is what is at [p] right now. It is the same as
    {!tile_at} except that a key the player already holds shows as [Floor].
    Raises [Invalid_argument] if [p] is out of bounds. *)

val is_won : state -> bool
(** [is_won s] is whether the player is standing on the exit. *)

(** {1 Moving} *)

(** Why a move did not happen. *)
type blocked =
  | Out_of_bounds
  | Hit_wall
  | Locked_door of int  (** the id of the key that is needed *)
  | Closed_gate of int  (** the id of the switch that opens it *)
  | Already_won

type outcome =
  | Moved of state
  | Blocked of blocked

val move : state -> direction -> outcome
(** [move s d] tries to move the player one square in direction [d].

    - Walls and squares outside the grid block the move.
    - A door with id [n] blocks the move unless the player holds key [n].
      With the key, the player walks onto the door. Keys are not used up.
    - A gate with id [n] blocks the move unless gate [n] is open.
    - Walking onto a key picks it up.
    - Walking onto a switch flips that switch group.
    - Once [is_won s] is true, every move is [Blocked Already_won].

    A successful move adds one to {!moves}. A blocked move returns no new
    state, so the caller keeps the old one. *)

val next_states : state -> (direction * state) list
(** [next_states s] is every successful move from [s], paired with the
    direction taken, in the order of {!all_directions}. The solver uses this
    to expand a state. *)

(** {1 Comparing states} *)

type key
(** The part of a state that decides what can happen next: the player's
    square, the keys held, and the switches that are on. Two states with
    the same key behave the same, even if their move counts differ. *)

val key : state -> key
(** [key s] is the key of [s]. *)

val compare_key : key -> key -> int
(** [compare_key] is a total order on keys, so they can go in a [Set] or
    [Map] (for example the solver's visited set). *)

(** {1 Showing a state} *)

val char_of_tile : tile -> char
(** [char_of_tile t] is the symbol for [t]: ['.'] floor, ['#'] wall,
    ['E'] exit, ['k'] key, ['D'] door, ['s'] switch, ['G'] gate. *)

val to_string : state -> string
(** [to_string s] draws the grid one row per line, with ['@'] on the
    player's square, picked up keys shown as floor, and open gates shown as
    ['_']. Every line, including the last, ends in ['\n']. Useful for
    testing and debugging. *)
