(** Breadth-first search over game states.

    The solver plays by exactly the same rules as the player: it expands a
    state with {!Rules.next_states}, and treats two states as the same when
    they have the same {!Rules.key} (the player's square, the keys held, and
    the switches that are on). A square can be a dead end or the way forward
    depending on what the player carries, so positions alone are not enough.

    Breadth-first search explores states in order of how many moves it takes
    to reach them, so the first won state it finds is reached by a shortest
    sequence of moves. *)

type result = {
  path : Rules.direction list option;
      (** a shortest sequence of moves to a won state, or [None] if no won
          state can be reached *)
  explored : int;
      (** how many distinct states (by {!Rules.key}) the search discovered,
          including the starting state; useful for measuring cost *)
}

val search : Rules.state -> result
(** [search s] runs breadth-first search from [s]. If [s] is already won,
    [path] is [Some []]. *)

val solve : Rules.state -> Rules.direction list option
(** [solve s] is [(search s).path]. *)

val par : Rules.level -> int option
(** [par lvl] is the fewest moves needed to win [lvl] from its start, or
    [None] if [lvl] cannot be won. This is the score the game shows next to
    the player's move count. *)

val hint : Rules.state -> Rules.direction option
(** [hint s] is the first move of a shortest solution from [s], or [None] if
    [s] is already won or cannot be won from here. *)
