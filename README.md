# CS 3110 Team Project: Escape Room Puzzle Generator

## Project Description

Our project is an **Escape Room Puzzle Generator**, a terminal-based puzzle game built in OCaml. The game will generate random puzzle levels containing walls, keys, locked doors, switches, and gates.

Each generated level will be checked by a breadth-first search (BFS) solver to ensure it is solvable before the player attempts it.

Players will navigate through puzzles, collect keys, unlock doors, activate switches, and attempt to reach the exit in as few moves as possible.

## Team Members

- Naman Soni — ns2227
- Gamunu Withana — gw362
- Kevin Dang — kd548
- Thai Koehnle — tak86
- Matthew Wang — mw2326

## Planned Features

1. **Random Level Generation:** Generate puzzles with different layouts and difficulty levels.
2. **Puzzle Solver:** Use BFS to verify solvability and calculate the shortest path.
3. **Game Engine:** Handle movement, key collection, doors, switches, and winning conditions.
4. **Terminal Interface:** Display a text-based map and process player input.
5. **Save and Load:** Store game progress, best scores, and level seeds.
6. **Hint System:** Suggest the next move along a shortest path to the exit.

## Game Controls

The planned terminal interface will use the following symbols:

| Symbol | Meaning     |
| ------ | ----------- |
| `#`    | Wall        |
| `@`    | Player      |
| `k`    | Key         |
| `D`    | Locked door |
| `s`    | Switch      |
| `G`    | Gate        |
| `E`    | Exit        |

Players will use W, A, S, and D to move through the level.

## MS2 Development Plan

For MS2, we plan to create a playable prototype that can:

- Load a handwritten puzzle from a text file.
- Display the puzzle in the terminal.
- Allow players to move, collect keys, and unlock doors.
- Detect when the player reaches the exit.
- Use the solver to determine the shortest possible solution.

We will also benchmark solver performance using five levels with increasing numbers of locks and switches before implementing the full generator.

## Development Workflow

- Each team member works on their own Git branch.
- Changes are submitted through pull requests.
- Every pull request requires at least one approval before merging.
- Code merged into `main` must build successfully and pass `dune test`.
- Implementation modules will have documented `.mli` interfaces.
- AI-assisted contributions will follow the course's academic integrity guidelines and be disclosed during code review.

## Team Contract

Our team contract describes our communication expectations, responsibilities, decision-making process, and code review policies.

**Team Contract:** [https://drive.google.com/file/d/1EOhBCNVB0GToKkbAFdkWd2Hv0MakktaF/view?usp=sharing](https://drive.google.com/file/d/1EOhBCNVB0GToKkbAFdkWd2Hv0MakktaF/view?usp=sharing)
