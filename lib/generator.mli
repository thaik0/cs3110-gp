(** Proposed generator interface for MS3. No generator is implemented in MS2.
    Review this proposal with the loader, rules, and solver owners before use. *)

type difficulty = Easy | Medium | Hard
(** Requested level complexity. Exact dimensions and lock counts are pending
    the solver timing experiment. *)

val generate :
  seed:int ->
  difficulty:difficulty ->
  is_solvable:(string list -> bool) ->
  (string list, string) result
(** [generate ~seed ~difficulty ~is_solvable] proposes a rectangular level as
    text rows, compatible with the terminal's grid representation. The loader
    or rules adapter used by [is_solvable] must interpret the same symbols.

    Proposed contract: successful levels have one start, one exit, an enclosing
    wall, and pass [is_solvable]. Generation retries rejected candidates a
    bounded number of times and returns [Error message] on exhaustion. The
    retry limit will be chosen after timing measurements. With a deterministic
    callback, the same seed and difficulty produce the same result, independent
    of global random state. Exceptions from the callback propagate.

    The shared level type, key/door pairing, switch/gate encoding, difficulty
    sizes, and retry limit remain design decisions, not implemented features.
    Replace [string list] with the team's shared level type if agreed. *)
