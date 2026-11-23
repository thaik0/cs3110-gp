(** A game in progress: the current state plus the history needed for undo
    and restart. The display and input code should drive the game through
    this module, and leave the rules themselves to {!Rules}. *)

type t
(** A game being played on one level. *)

val start : Rules.level -> t
(** [start lvl] is a new game at the beginning of [lvl]. *)

val current : t -> Rules.state
(** [current g] is the state the player sees right now. *)

val step : t -> Rules.direction -> t * Rules.blocked option
(** [step g d] tries to move in direction [d]. On success it is the updated
    game and [None]. If the move is blocked it is [g] unchanged and
    [Some reason], so the display can say why. *)

val undo : t -> t option
(** [undo g] is the game one successful move earlier, or [None] if no moves
    have been made. *)

val restart : t -> t
(** [restart g] is a new game at the beginning of the same level. *)

val can_undo : t -> bool
(** [can_undo g] is whether [undo g] would give [Some _]. *)

val is_won : t -> bool
(** [is_won g] is [Rules.is_won (current g)]. *)
