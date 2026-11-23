# Solver

Owner: Gamunu Withana (backup: Naman Soni). Code is in `src/solver.ml`, tests
are in `test/test_solver.ml`, and the timing experiment is
`experiments/timing.ml`.

## Interface (implemented: `src/solver.mli`)

```ocaml
type result = {
  path : Rules.direction list option;  (* a shortest winning sequence *)
  explored : int;                      (* distinct states discovered *)
}

val search : Rules.state -> result
val solve : Rules.state -> Rules.direction list option
val par : Rules.level -> int option    (* fewest moves from the start *)
val hint : Rules.state -> Rules.direction option   (* for the Hint key *)
```

- The game shows `par lvl` next to the player's move count when they win.
- The terminal's `Hint` command calls `hint (Engine.current g)`.
- The generator will call `par` on each candidate level and throw away any
  level where it is `None`.

## Design

- **Same rules as the player.** The solver expands a state with
  `Rules.next_states` and checks `Rules.is_won`. It has no movement logic of
  its own, so the rules the solver plans with are exactly the rules the
  player plays by.
- **A state is more than a position.** Two states are treated as the same
  when they have the same `Rules.key`: the player's square, the keys held,
  and the switches that are on. A square can be a dead end without a key and
  the way forward with it, so remembering positions alone would make the
  solver wrongly call some levels unsolvable (the "key needed" and "switch
  needed" tests catch exactly this).
- **Breadth-first, so shortest.** States come off a FIFO queue in order of
  how many moves it took to reach them, so the first won state found is
  reached in the fewest moves. Each queued state carries its path as a
  reversed list; consing shares the tail, so this costs O(1) per state.
- **Hints from any state.** `hint` runs the same search from the player's
  current state, so it accounts for the keys they already hold.

## Validation (completed)

`dune test` runs 24 solver tests (`test/test_solver.ml`); all pass.

- **Hand-worked levels.** Each expected par was worked out by hand before
  running the tests: a corridor (3), an open room (4), a key behind the
  player (4), a switch behind the player (4), two keys in a chain (6), and
  three unsolvable levels (door without key, gate without reachable switch,
  walled-off exit).
- **Kevin's demo level** (`levels/demo.txt` on `kevin-ms2`): par 20, the
  value worked out independently in `docs/level_format.md` (8 moves to the
  key, 12 to the exit).
- **Paths are replayed, not trusted.** Every returned path is applied with
  `Rules.move`; the test fails if any move is blocked, if the path does not
  win, or if its length is not the par.
- **Hints.** First move in simple cases, the mid-game case (after picking up
  the key, the hint turns around), no hint once won or when unsolvable, and
  following hints from the start of the demo wins in exactly 20 moves.
- **Brute-force cross-check.** On 300 random 2-by-4 levels (seeded, so
  reproducible), the solver's par agrees with an exhaustive depth-limited
  search that tries every move sequence up to 12 moves and keeps no visited
  set, so it cannot share a mistake in the solver's notion of "same state".
- **Do the tests catch bugs?** Three deliberate bugs, one at a time:
  ignoring keys and switches in the visited set (10 tests fail), depth-first
  instead of breadth-first (4 fail), and dropping moves from the path
  (rejected by the compiler as an unused variable). The depth-first bug
  first made the hint-following test loop forever instead of failing; that
  test now stops after 100 moves.

## Timing experiment (completed)

MS1 question: every key or switch can double the number of states, so is
breadth-first search fast enough? The plan was to time five levels with 1 to
5 locks or switches, and cap locks or shrink grids if a hard-sized level took
more than about one second.

Run it with `dune exec experiments/timing.exe`. Part A is the planned
experiment (a chain of rooms; each lock's key or switch is in the far corner
of the room before it). Part B is a worst case for the generator: an open
room where every key and switch can be reached in any order, so the search
really meets every combination.

| Level | Size | Locks | Par | States | Time |
| --- | --- | --- | --- | --- | --- |
| chain-1 | 5 x 13 | 1 | 13 | 45 | 0.04 ms |
| chain-2 | 6 x 25 | 2 | 28 | 169 | 0.17 ms |
| chain-3 | 7 x 41 | 3 | 52 | 486 | 0.62 ms |
| chain-4 | 8 x 61 | 4 | 77 | 1,045 | 1.49 ms |
| chain-5 | 9 x 85 | 5 | 115 | 2,145 | 3.64 ms |
| vault-10-3 | 12 x 16 | 3 | 24 | 785 | 1.08 ms |
| vault-10-6 | 12 x 19 | 6 | 31 | 6,360 | 17 ms |
| vault-20-6 | 22 x 29 | 6 | 63 | 25,557 | 95 ms |
| vault-30-6 | 32 x 39 | 6 | 87 | 56,032 | 219 ms |
| vault-40-6 | 42 x 49 | 6 | 127 | 101,710 | 480 ms |

(CPU time on one machine, averaged over repeated runs for the fast levels.)

**Result:** every level, including the worst case, solves well under one
second. The state counts grow as (open squares) x 2^(keys + switches), as
predicted: vault-10-6 discovered 6,360 states against a maximum of
100 x 2^6 = 6,400. **Decision:** keep breadth-first search. Since the
generator may try several levels per difficulty, we propose limits of 6
keys and switches and about 30 x 30 squares for hard levels, which keeps
each solve near 0.2 s. We will re-run the experiment on the generator's real
output in MS3.

## Planned (not built yet)

- When the generator exists: time `par` on generated levels at each
  difficulty, and test that every level it returns has a par.
- Once the level loader and rules agree on one level type, run `par` on every
  file in `levels/` as a test.
