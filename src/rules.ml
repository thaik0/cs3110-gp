module IntSet = Set.Make (Int)

type pos = {
  row : int;
  col : int;
}

type direction =
  | Up
  | Down
  | Left
  | Right

let all_directions = [ Up; Down; Left; Right ]

let step_pos p = function
  | Up -> { p with row = p.row - 1 }
  | Down -> { p with row = p.row + 1 }
  | Left -> { p with col = p.col - 1 }
  | Right -> { p with col = p.col + 1 }

let direction_of_char c =
  match Char.lowercase_ascii c with
  | 'w' -> Some Up
  | 'a' -> Some Left
  | 's' -> Some Down
  | 'd' -> Some Right
  | _ -> None

type tile =
  | Floor
  | Wall
  | Exit
  | Key of int
  | Door of int
  | Switch of int
  | Gate of int

(* AF: [{grid; start}] is the level whose square at row [r], column [c] holds
   [grid.(r).(c)], with the player starting at [start].
   RI: [grid] has at least one row; every row has the same length, which is
   at least one; [start] is in bounds and is [Floor]; some square is [Exit].
   [grid] is never mutated after [make_level] copies it. *)
type level = {
  grid : tile array array;
  start : pos;
}

exception Invalid_level of string

let rows lvl = Array.length lvl.grid
let cols lvl = Array.length lvl.grid.(0)

let in_bounds lvl p =
  p.row >= 0 && p.row < rows lvl && p.col >= 0 && p.col < cols lvl

let tile_at lvl p =
  if in_bounds lvl p then lvl.grid.(p.row).(p.col)
  else invalid_arg "Rules.tile_at: position out of bounds"

let make_level grid start =
  let fail msg = raise (Invalid_level msg) in
  if Array.length grid = 0 then fail "the grid has no rows";
  let width = Array.length grid.(0) in
  if width = 0 then fail "the rows are empty";
  Array.iteri
    (fun i row ->
      if Array.length row <> width then
        fail (Printf.sprintf "row %d has a different length than row 0" i))
    grid;
  let lvl = { grid = Array.map Array.copy grid; start } in
  if not (in_bounds lvl start) then fail "the start is outside the grid";
  if tile_at lvl start <> Floor then fail "the start is not a floor tile";
  if not (Array.exists (Array.exists (fun t -> t = Exit)) lvl.grid) then
    fail "the level has no exit";
  lvl

let start lvl = lvl.start

(* AF: [{lvl; player; keys; switches; moves}] is the player standing at
   [player] in [lvl], holding the keys whose ids are in [keys], with the
   switch groups in [switches] turned on, after [moves] successful moves.
   RI: [player] is in bounds of [lvl] and is not a [Wall]; [moves >= 0]. *)
type state = {
  lvl : level;
  player : pos;
  keys : IntSet.t;
  switches : IntSet.t;
  moves : int;
}

let init lvl =
  {
    lvl;
    player = lvl.start;
    keys = IntSet.empty;
    switches = IntSet.empty;
    moves = 0;
  }

let level s = s.lvl
let player s = s.player
let keys_held s = IntSet.elements s.keys
let has_key s n = IntSet.mem n s.keys
let switch_on s n = IntSet.mem n s.switches
let gate_open = switch_on
let moves s = s.moves

let current_tile s p =
  match tile_at s.lvl p with
  | Key n when has_key s n -> Floor
  | t -> t

let is_won s = tile_at s.lvl s.player = Exit

type blocked =
  | Out_of_bounds
  | Hit_wall
  | Locked_door of int
  | Closed_gate of int
  | Already_won

type outcome =
  | Moved of state
  | Blocked of blocked

(* [arrive s p] is [s] with the player moved onto [p] and whatever is on [p]
   applied. Requires: the move onto [p] is allowed. *)
let arrive s p =
  let s = { s with player = p; moves = s.moves + 1 } in
  match tile_at s.lvl p with
  | Key n -> { s with keys = IntSet.add n s.keys }
  | Switch n ->
      let switches =
        if IntSet.mem n s.switches then IntSet.remove n s.switches
        else IntSet.add n s.switches
      in
      { s with switches }
  | Floor | Wall | Exit | Door _ | Gate _ -> s

let move s d =
  if is_won s then Blocked Already_won
  else
    let p = step_pos s.player d in
    if not (in_bounds s.lvl p) then Blocked Out_of_bounds
    else
      match tile_at s.lvl p with
      | Wall -> Blocked Hit_wall
      | Door n when not (has_key s n) -> Blocked (Locked_door n)
      | Gate n when not (gate_open s n) -> Blocked (Closed_gate n)
      | Floor | Exit | Key _ | Door _ | Switch _ | Gate _ -> Moved (arrive s p)

let next_states s =
  List.filter_map
    (fun d ->
      match move s d with
      | Moved s' -> Some (d, s')
      | Blocked _ -> None)
    all_directions

type key = pos * int list * int list

let key s = (s.player, IntSet.elements s.keys, IntSet.elements s.switches)
let compare_key = compare

let char_of_tile = function
  | Floor -> '.'
  | Wall -> '#'
  | Exit -> 'E'
  | Key _ -> 'k'
  | Door _ -> 'D'
  | Switch _ -> 's'
  | Gate _ -> 'G'

let to_string s =
  let buf = Buffer.create ((cols s.lvl + 1) * rows s.lvl) in
  for row = 0 to rows s.lvl - 1 do
    for col = 0 to cols s.lvl - 1 do
      let p = { row; col } in
      let c =
        if p = s.player then '@'
        else
          match current_tile s p with
          | Gate n when gate_open s n -> '_'
          | t -> char_of_tile t
      in
      Buffer.add_char buf c
    done;
    Buffer.add_char buf '\n'
  done;
  Buffer.contents buf
