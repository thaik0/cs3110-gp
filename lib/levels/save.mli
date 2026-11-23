(** The player's saved progress. For MS2 this holds the best (fewest) move
    count for each level the player has finished. MS3 will add the current run
    (difficulty, level number, and seed) to the same file.

    The file is plain text, for example:

    {v
escape-room-save 1
best demo 14
best seed-12345 31
    v}

    The first line names the format and its version, so an unrelated or
    newer file is reported instead of being misread. *)

type t
(** Saved progress. Values are immutable: {!record} returns a new value. *)

(** Why progress could not be loaded or saved. *)
type error =
  | Io of string  (** the file could not be read or written *)
  | Corrupt of {
      line : int;  (** 1-based line number in the file *)
      message : string;
    }  (** the file exists but is not a valid save file *)

val error_to_string : error -> string
(** A one-line message suitable for showing to the player. *)

val empty : t
(** No levels finished yet. *)

val valid_id : string -> bool
(** [valid_id id] is true if [id] can be used as a level id: non-empty with no
    whitespace. {!Level.name} always gives a valid id. *)

val best : t -> string -> int option
(** [best p id] is the fewest moves recorded for level [id], or [None] if the
    level has never been finished. *)

val record : t -> string -> int -> t
(** [record p id moves] notes that level [id] was finished in [moves] moves.
    The best score only changes if [moves] is lower than the old best.
    Raises [Invalid_argument] if [id] is not valid or [moves < 0]. *)

val bests : t -> (string * int) list
(** Every level's best score, sorted by level id. *)

val to_string : t -> string
(** The contents of a save file for [p]. *)

val of_string : string -> (t, error) result
(** [of_string text] reads the contents of a save file. Never returns [Io]. *)

val load : string -> (t, error) result
(** [load path] reads progress from [path]. If there is no file at [path] yet
    (the first time the game is played), returns [Ok empty]. *)

val save : string -> t -> (unit, error) result
(** [save path p] writes [p] to [path]. It writes a temporary file first and
    then renames it, so if the game stops partway through saving, the old
    save file is still intact. *)
