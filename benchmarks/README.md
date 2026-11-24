# Matthew's MS2 benchmark levels

Five fixed, increasingly large levels for the solver experiment. These are
not randomly generated. The generator is a proposed interface only, in
`lib/generator.mli`, using the team's `Levels.Level.t` static level type.

## File format and semantics

The `.txt` files use Kevin's loader format (`docs/level_format.md`): a `name:`,
`keys:`, and `doors:` header followed by `map:` and rectangular rows. Symbols
are `#` wall, `.` floor, `@` start, `k` key, `D` door, and `E` exit.
Labels are assigned in reading order. Each key has a distinct label and opens
only the corresponding door. Keys are reusable, as specified by Naman's rules.
The boundary is closed and there is exactly one start and exit.

Each matching `.moves` file supplies a `w/a/s/d` witness route. It visits the
key in each chamber and crosses that chamber's door before continuing.
For these layouts, the shortest route must visit each chamber's bottom key
and return to the top door row. Its length is
`locks * (2 * (height - 3) + 6)`.

| File | Width x height | Distinct key/door pairs | Expected and verified par | Solver states |
| --- | --- | --- | --- | --- |
| locks-1.txt | 9 x 9 | 1 | 18 | 71 |
| locks-2.txt | 15 x 11 | 2 | 44 | 182 |
| locks-3.txt | 21 x 13 | 3 | 78 | 388 |
| locks-4.txt | 27 x 15 | 4 | 120 | 720 |
| locks-5.txt | 33 x 17 | 5 | 170 | 1208 |

## Validation completed by Codex

Run `dune test` from the repository root. `test/test_benchmarks.ml` loads all
five files using `Levels.Level_file.load`, checks dimensions and key/door
counts, and replays each witness through `Escape.Rules.move`. Each witness
wins and collects all distinct keys. It then calls `Escape.Solver.search`,
replays the returned path through the rules, and checks the expected par.
All five fixture checks and the team's existing 142 unit tests pass.

The test contains a small test-only conversion from string labels in
`Levels.Level.t` to integer IDs in `Escape.Rules.level`, preserving matching
labels. It handles the key/door fixtures only and does not change or replace
Thai's pending production adapter. Once that adapter becomes a shared library,
the test should use it directly.

For a loader-only check:

```sh
dune exec tools/levelcheck.exe -- benchmarks/locks-1.txt
```

## Handoff and remaining work

Gamunu already implemented and documented a timing experiment on separate
chain and vault layouts in `experiments/timing.ml` and `docs/solver.md`.
These five files supplement that work; Matthew does not claim authorship of
Gamunu's solver or timing results. No timing measurements for these five file
fixtures have been recorded. Solver state counts above are not timings.

Before the team includes this contribution, Matthew and Gamunu should review
the levels and proposed generator interface. Independent human review is
pending. A solver timing runner for these files can use the shared adapter
once merged. Measure solver time without loading or printing, and report
machine, command, commit, repeated-run statistics, and failures. Chain layouts
alone do not establish performance for arbitrary generated puzzles.

Full random generation, deterministic seed tests, difficulty parameters,
retry limits, and checks on actual generated output remain MS3 work. The
proposed callback accepts `Levels.Level.t`; callers will need the shared
adapter before passing that level to the current solver.
