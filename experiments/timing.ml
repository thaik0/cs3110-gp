(* The MS2 timing experiment: is breadth-first search fast enough?

   MS1 worry: every key or switch can double the number of states the solver
   searches. Plan: time the solver on five levels of growing size with 1 to 5
   locks or switches; if a hard-sized level takes more than about one second,
   cap the number of locks and switches or shrink the grid.

   Part A is that plan. Part B is a worst case for the generator: big open
   rooms where every key and switch can be reached in any order, so the
   number of states really is (squares) x (combinations of keys and
   switches).

   Run with:  dune exec experiments/timing.exe *)

open Escape

(* [chain ~room_w ~room_h locks] draws a row of rooms. The player starts in
   the first room and the exit is in the last. Between neighboring rooms is a
   wall with one opening, holding the lock: a door (key in the room before
   it) or a gate (switch in the room before it). Each key or switch sits in
   the corner farthest from the opening, so the solver has to detour for it.
   [locks] is a list of (pickup, lock) symbol pairs such as ('a', 'A'). *)
let chain ~room_w ~room_h locks =
  let rooms = List.length locks + 1 in
  let width = (rooms * (room_w + 1)) + 1 in
  let height = room_h + 2 in
  let grid = Array.make_matrix height width '.' in
  for r = 0 to height - 1 do
    for c = 0 to width - 1 do
      if r = 0 || r = height - 1 || c mod (room_w + 1) = 0 then
        grid.(r).(c) <- '#'
    done
  done;
  let mid = height / 2 in
  List.iteri
    (fun i (pickup, lock) ->
      let left = (i * (room_w + 1)) + 1 in
      let divider = (i + 1) * (room_w + 1) in
      grid.(height - 2).(left) <- pickup;
      grid.(mid).(divider) <- lock)
    locks;
  grid.(1).(1) <- '@';
  grid.(mid).(width - 2) <- 'E';
  Array.to_list (Array.map (fun row -> String.init width (Array.get row)) grid)

(* [vault ~size ~seed pickups locks] is a [size] x [size] open room. The
   [pickups] (keys and switches) are scattered at random squares chosen from
   [seed], and the exit is sealed in a corner behind [locks], one after
   another. Every pickup can be reached in any order, so the search really
   meets every combination. *)
let vault ~size ~seed pickups locks =
  let rng = Random.State.make [| seed |] in
  let n = List.length locks in
  let width = size + n + 3 in
  let height = size + 2 in
  let grid = Array.make_matrix height width '#' in
  for r = 1 to size do
    for c = 1 to size do
      grid.(r).(c) <- '.'
    done
  done;
  grid.(1).(1) <- '@';
  List.iter
    (fun p ->
      let rec place () =
        let r = 1 + Random.State.int rng size in
        let c = 1 + Random.State.int rng size in
        if grid.(r).(c) = '.' then grid.(r).(c) <- p else place ()
      in
      place ())
    pickups;
  (* a corridor of locks along the bottom row, leading to the exit *)
  List.iteri (fun i lock -> grid.(size).(size + 1 + i) <- lock) locks;
  grid.(size).(size + 1 + n) <- 'E';
  Array.to_list (Array.map (fun row -> String.init width (Array.get row)) grid)

(* [time f] is [(f (), seconds)], repeating [f] until at least 0.2 s have
   passed so that fast runs are measured accurately. *)
let time f =
  let start = Sys.time () in
  let result = f () in
  let runs = ref 1 in
  while Sys.time () -. start < 0.2 do
    ignore (f ());
    incr runs
  done;
  (result, (Sys.time () -. start) /. float_of_int !runs)

let report name lines locks =
  let lvl = Picture.level lines in
  let result, secs = time (fun () -> Solver.search (Rules.init lvl)) in
  let par =
    match result.Solver.path with
    | Some p -> string_of_int (List.length p)
    | None -> "none"
  in
  Printf.printf "%-18s %3d x %-3d %5d %5s %9d %10.2f\n%!" name (Rules.rows lvl)
    (Rules.cols lvl) locks par result.Solver.explored (secs *. 1000.)

let header title =
  Printf.printf "\n%s\n%-18s %9s %5s %5s %9s %10s\n" title "level" "size"
    "locks" "par"
    "states" "ms"

let () =
  let all = [ ('a', 'A'); ('x', 'X'); ('b', 'B'); ('y', 'Y'); ('c', 'C') ] in
  let take n l = List.filteri (fun i _ -> i < n) l in
  header "Part A: five levels, 1 to 5 locks or switches";
  for k = 1 to 5 do
    let lines = chain ~room_w:(3 + (2 * k)) ~room_h:(2 + k) (take k all) in
    report (Printf.sprintf "chain-%d" k) lines k
  done;
  print_endline "\nchain-5 (the largest Part A level):";
  List.iter print_endline (chain ~room_w:13 ~room_h:7 all);
  header "Part B: worst case, every pickup reachable in any order";
  let pickups = [ 'a'; 'b'; 'c'; 'x'; 'y'; 'z' ] in
  let locks = [ 'A'; 'B'; 'C'; 'X'; 'Y'; 'Z' ] in
  List.iter
    (fun (size, k) ->
      report
        (Printf.sprintf "vault-%d-%d" size k)
        (vault ~size ~seed:3110 (take k pickups) (take k locks))
        k)
    [ (10, 3); (10, 6); (20, 6); (30, 6); (40, 6) ]
