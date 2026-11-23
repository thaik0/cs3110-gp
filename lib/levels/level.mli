(** The static layout of one level: what is on each square before the player
    moves. A level does not change during play. Which keys are held, which
    doors are open, and which gates are toggled is game state, owned by the
    rules module.

    Values of type [t] can only be built with {!make}, which checks the layout.
    Every other module can rely on these facts about any level:
    - the grid is a rectangle at least 3 by 3, with walls all around the edge;
    - there is exactly one start square and exactly one exit;
    - every door has at least one key with the same label;
    - every switch controls at least one gate, and every gate has a switch. *)

type pos = {
  row : int;  (** 0 is the top row *)
  col : int;  (** 0 is the leftmost column *)
}
(** A square on the grid. *)

(** What is on a square. Labels connect pieces: a key opens doors with the
    same label, and a switch toggles every gate with the same label. *)
type tile =
  | Floor
  | Wall
  | Exit
  | Key of string
  | Door of string  (** locked until opened with a matching key *)
  | Switch of string
  | Gate of string * bool
      (** [Gate (label, starts_open)]: the label of its switch, and whether
          the gate is open when the level begins *)

type t
(** A checked level. *)

val make : name:string -> start:pos -> tile list list -> (t, string) result
(** [make ~name ~start rows] builds a level from its rows, top to bottom. The
    start square must be [Floor], and [name] must be one word with no spaces
    (it is used as the level's id in save files). Returns [Error msg] describing the first
    rule above that is broken. *)

val name : t -> string
(** A short name for the level, such as ["demo"]. *)

val width : t -> int
val height : t -> int

val start : t -> pos
(** The square where the player begins. *)

val exit : t -> pos
(** The square of the only [Exit] tile. *)

val in_bounds : t -> pos -> bool

val tile_at : t -> pos -> tile
(** [tile_at lvl p] is the tile at [p]. Squares outside the grid count as
    [Wall], so callers don't need to check bounds before moving. *)

val tiles : t -> (pos * tile) list
(** Every square that is not [Floor] or [Wall], in reading order (top to
    bottom, then left to right). Useful for listing keys, doors, switches, and
    gates. *)

val char_of_tile : tile -> char
(** The symbol drawn for a tile when the level begins: [#] wall, space for
    floor, [E] exit, [k] key, [D] door, [s] switch, [G] closed gate, [g] open
    gate. Labels are not shown. *)

val to_rows : t -> string list
(** The level as text rows, with [@] on the start square. Matches the [grid]
    argument of [Terminal.render]. *)
