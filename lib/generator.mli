(** Proposed generator interface for MS3. No generator is implemented in MS2.
    Review this proposal with the loader, rules, and solver owners before use.
*)

type difficulty =
  | Easy
  | Medium
  | Hard
      (** Requested level complexity. Exact dimensions and lock counts are
          pending the solver timing experiment. *)

val generate :
  seed:int ->
  difficulty:difficulty ->
  is_solvable:(Levels.Level.t -> bool) ->
  (Levels.Level.t, string) result
(** [generate ~seed ~difficulty ~is_solvable] proposes a checked static level
    built through [Levels.Level.make]. The callback adapts that level to the
    rules/solver representation and reports whether a solution exists.

    Proposed contract: successful levels have one start, one exit, an enclosing
    wall, and pass [is_solvable]. Generation retries rejected candidates a
    bounded number of times and returns [Error message] on exhaustion. The retry
    limit will be chosen after timing measurements. With a deterministic
    callback, the same seed and difficulty produce the same result, independent
    of global random state. Exceptions from the callback propagate.

    Keys and doors use matching string labels in [Levels.Level.t]. Keys are
    reusable under the current rules. Difficulty sizes, retry limits, and the
    shared adapter remain to be agreed before implementation. *)
