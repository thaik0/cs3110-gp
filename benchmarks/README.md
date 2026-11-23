# Matthew's MS2 benchmark fixtures (draft)

These are five fixed, increasingly large levels for Gamunu's solver timing
experiment. Random generation is not implemented. The fixtures use the symbols
already listed in the project README: `#` wall, `@` start, space floor,
`k` key, `D` locked door, and `E` exit. Each file is a rectangular grid with
no header. Preserve spaces. Rows are separated by LF; there is a final LF.

**Integration assumption to confirm:** all keys are interchangeable, one key
opens one door, and an opened door remains open. A witness route is supplied
for every level and works with either consumable or reusable generic keys.
With reusable keys, later keys need not be collected, so these fixtures do not
necessarily increase inventory-state complexity as intended. If the team uses
colored keys or switch identifiers, adapt these fixtures to the agreed loader
format before timing. No loader currently exists in the repository.

| File | Width x height | Keys | Doors | Witness moves |
| --- | --- | --- | --- | --- |
| locks-1.txt | 9 x 9 | 1 | 1 | 18 |
| locks-2.txt | 15 x 11 | 2 | 2 | 44 |
| locks-3.txt | 21 x 13 | 3 | 3 | 78 |
| locks-4.txt | 27 x 15 | 4 | 4 | 120 |
| locks-5.txt | 33 x 17 | 5 | 5 | 170 |

The matching `.moves` files give a known route using `w/a/s/d`. Each route
visits a key in the current chamber, returns to the door row, crosses that
door, and repeats until it reaches the exit. These are witness paths, **not
claims about the shortest solution**. The automated fixture check verifies
the route with a small consumable-key model; the team's shared rules and
solver still need to run these fixtures.

## Timing handoff

Run the fixture checks from the repository root with `dune test`. The checks
are in `test/test_benchmarks.ml`; they validate dimensions, symbols, boundaries,
key/door counts, and each witness route. They do not test the team's loader,
rules, or solver, which are not implemented on this branch.

Gamunu owns the solver and timing experiment. Once the loader and rules exist:

1. Parse each `.txt` file with the real loader and check the witness with the
   shared rules. Run the solver and verify its returned path reaches the exit.
2. Measure solver time alone, excluding file reading, printing, and user input.
   Record the command, machine, OCaml version, and solver commit.
3. Run each level five times; report the median time, shortest-path length,
   and explored state count if available. Include failures and timeouts.
4. Compare results with the contract's approximately one-second target.
   These five layouts are an initial experiment, not evidence that all hard
   random levels will be fast. Add branching or switch-heavy cases as needed.

No solver timings have been measured and no solver-performance conclusion is
claimed. The draft interface is in `lib/generator.mli`. Review it with Gamunu
and Kevin before implementation; it changes no existing shared interface.
