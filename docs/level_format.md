# Level files and save files

Owner: Kevin Dang (backup: Matthew Wang). Code is in `lib/levels/`, tests are in
`test/levels/`.

## Level file format

A level file has a header, then a `map:` line, then the grid.

```
; MS2 demo level: pick up the key, open the door, reach the exit.
name: demo
keys: red
doors: red
map:
##########
#@.....#.#
#.####.D.#
#.#k.#.#.#
#.#..#.#E#
#......###
##########
```

### Header

- Lines starting with `;` are comments. Blank lines are ignored.
- `name: <one word>` is the level's id, used for best scores in the save file.
  If it is left out, the file name is used (`levels/demo.txt` becomes `demo`).
- `keys:`, `doors:`, `switches:`, `gates:` each give one label per tile of that
  kind, in **reading order** (top row first, left to right).
  - A key opens doors with the same label.
  - A switch toggles every gate with the same label.
  - If a line is left out, every tile of that kind gets the label `default`.
    So a level with one key and one door needs no label lines at all.
- Each field may appear at most once. Unknown fields are errors, which catches
  typos such as `door:`.

### Grid symbols

| Symbol      | Meaning                           |
| ----------- | --------------------------------- |
| `#`         | wall                              |
| `.` or space| floor                             |
| `@`         | player start (floor underneath)   |
| `E`         | exit                              |
| `k`         | key                               |
| `D`         | locked door                       |
| `s`         | switch                            |
| `G`         | gate, closed at the start         |
| `g`         | gate, open at the start           |

### Rules checked when loading

- Every row has the same width after trailing spaces are removed. Blank lines
  after the grid are ignored, but blank lines inside it are errors.
- The outer edge is all walls, and the grid is at least 3 by 3.
- There is exactly one `@` and exactly one `E`.
- Each label line has exactly as many labels as there are tiles of that kind.
- Every door label matches some key. A key with no door is allowed as a decoy.
- Every switch label matches some gate, and every gate label matches some switch.

Errors give the line number, and the column for unknown symbols:

```
$ dune exec tools/levelcheck.exe -- levels/demo.txt
```

prints the level as the player will see it, or the first error, for example
`line 4: unknown symbol '?' in column 3`. Run it on any level you write by hand.

Whether a level can be **solved** is not checked here. That is the solver's job.

## Interfaces (implemented)

- `Levels.Level` (`lib/levels/level.mli`) is the static layout shared by the
  rules, solver, generator, and display. `Level.make` is the only way to build a
  level, so every `Level.t` satisfies the rules above. The generator should use
  it too. `tile_at` treats squares outside the grid as `Wall`. `to_rows` gives
  the `grid` argument for `Terminal.render`.
- `Levels.Level_file` (`lib/levels/level_file.mli`) provides `load`, `parse`,
  `to_string`, and an `error` type: `Cannot_read`, `Syntax {line; message}`, or
  `Invalid_level`. Use `error_to_string` to show an error to the player.
- `Levels.Save` (`lib/levels/save.mli`) stores best move counts by level id.
  `load` on a missing file returns empty progress. `save` writes a temporary
  file and renames it, so a crash mid-save keeps the old file. Damaged files
  give `Corrupt {line; message}`.

Save file example:

```
escape-room-save 1
best demo 20
```

## Open questions for the team

- **Door semantics (Naman):** does walking into a door with the key open it
  *and* move onto it in one move? The demo level's par is 20 if yes, 21 if
  opening takes its own move. Is a key used up when it opens a door? The format
  works either way.
- **Proposed for MS3:** add `run <difficulty> <level-number> <seed>` to the save
  file for "continue". This waits on the generator's difficulty type (Matthew).
  Old version-1 files will still load.
