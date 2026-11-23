(** Converts a validated file level to the game engine's level representation. *)

type t
(** An engine level together with its original tile labels. *)

val of_level : Levels.Level.t -> (t, string) result
(** Converts matching labels to matching integer IDs. Returns an error for
    initially open gates, which the current engine does not support. *)

val level : t -> Escape.Rules.level
(** The converted level. *)

val label : t -> int -> string
(** The original label for an engine tile ID. *)
