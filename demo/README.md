# Terminal prototype (MS2)

Run `dune exec demo/terminal_demo.exe` from the project root. Press W, A, S,
or D without Enter. The demo prints the corresponding command immediately.
Press Q to quit. If single-key mode is unavailable, type commands followed by
Enter instead.

This demo uses a static example grid and inventory; it does not implement
movement rules. The terminal module in `lib/terminal.ml` is independent of
the game engine. To integrate it, convert the current level and player state
into grid strings, inventory item names, and a move count, then call
`Terminal.draw`. Wrap the game loop in `Terminal.with_input` and obtain
commands with `Terminal.read_command`. The engine handles the resulting
commands and supplies the updated state for the next draw.

Run `dune test` to check formatting and command parsing. The single-key
experiment should also be tried interactively on each teammate's laptop.
