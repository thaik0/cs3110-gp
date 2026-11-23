open OUnit2
open Escape
open Rules

let string_of_dir = function
  | Up -> "Up"
  | Down -> "Down"
  | Left -> "Left"
  | Right -> "Right"

let string_of_path = function
  | None -> "None"
  | Some ds -> "Some [" ^ String.concat "; " (List.map string_of_dir ds) ^ "]"

let string_of_par = function
  | None -> "None"
  | Some n -> "Some " ^ string_of_int n

(* [replay s ds] applies the moves [ds] to [s] with the real rules, failing
   the test if any move is blocked. It checks the solver's answers with the
   same rules the player uses, independently of how the solver searched. *)
let replay s ds =
  List.fold_left
    (fun s d ->
      match move s d with
      | Moved s' -> s'
      | Blocked _ ->
          assert_failure ("solver path is blocked at " ^ string_of_dir d))
    s ds

(* [assert_par expected lines] checks [par], and that [solve]'s path is
   legal, wins, and has exactly [expected] moves. *)
let assert_par expected lines =
  let lvl = Picture.level lines in
  assert_equal expected (Solver.par lvl) ~printer:string_of_par;
  match Solver.solve (init lvl) with
  | None -> assert_equal None expected ~printer:string_of_par
  | Some ds ->
      assert_bool "path wins" (is_won (replay (init lvl) ds));
      assert_equal expected (Some (List.length ds)) ~printer:string_of_par

(* Kevin's demo level (levels/demo.txt on the kevin-ms2 branch), redrawn
   with picture symbols: key 'a' opens door 'A'. Its par was worked out by
   hand as 20 in docs/level_format.md: 8 moves to the key, then 12 to the
   exit through the door. *)
let demo =
  [
    "##########";
    "#@.....#.#";
    "#.####.A.#";
    "#.#a.#.#.#";
    "#.#..#.#E#";
    "#......###";
    "##########";
  ]

let par_tests =
  "par and solve"
  >::: [
         ( "corridor: 3 moves right" >:: fun _ ->
           assert_par (Some 3) [ "@..E" ] );
         ( "the only path is exactly the corridor" >:: fun _ ->
           assert_equal
             (Some [ Right; Right; Right ])
             (Solver.solve (init (Picture.level [ "@..E" ])))
             ~printer:string_of_path );
         ( "open room: shortest of many routes (distance 4)" >:: fun _ ->
           assert_par (Some 4) [ "@.."; "..."; "..E" ] );
         ( "key needed: go back for it (left, then 3 right)" >:: fun _ ->
           assert_par (Some 4) [ "a@AE" ] );
         ( "key path is exactly Left, Right, Right, Right" >:: fun _ ->
           assert_equal
             (Some [ Left; Right; Right; Right ])
             (Solver.solve (init (Picture.level [ "a@AE" ])))
             ~printer:string_of_path );
         ( "switch needed: turn it on, come back through the gate" >:: fun _ ->
           (* right onto x (gate opens), back to start, left onto the open
              gate, left onto the exit *)
           assert_par (Some 4) [ "EX@x" ] );
         ( "a switch on the way opens the gate ahead" >:: fun _ ->
           (* switch (1), open gate (2), floor (3), exit (4) *)
           assert_par (Some 4) [ "@xX.E" ] );
         ( "two keys in a chain" >:: fun _ ->
           (* left onto key a (1), back (2), door A (3), key b (4),
              door B (5), exit (6) *)
           assert_par (Some 6) [ "a@AbBE" ] );
         ( "door without its key: unsolvable" >:: fun _ ->
           assert_par None [ "@A.E" ] );
         ( "gate without a reachable switch: unsolvable" >:: fun _ ->
           assert_par None [ "@#x"; "X##"; "E##" ] );
         ( "exit walled off: unsolvable" >:: fun _ ->
           assert_par None [ "@.#E" ] );
         ( "Kevin's demo level: par 20, as worked out by hand" >:: fun _ ->
           assert_par (Some 20) demo );
       ]

let won_state lines =
  let lvl = Picture.level lines in
  replay (init lvl) (Option.get (Solver.solve (init lvl)))

let hint_tests =
  "hint"
  >::: [
         ( "first move toward the exit" >:: fun _ ->
           assert_equal (Some Right)
             (Solver.hint (init (Picture.level [ "@..E" ])))
         );
         ( "goes for the key first" >:: fun _ ->
           assert_equal (Some Left)
             (Solver.hint (init (Picture.level [ "a@AE" ])))
         );
         ( "demo: down toward the key, not right toward the door" >:: fun _ ->
           assert_equal (Some Down) (Solver.hint (init (Picture.level demo))) );
         ( "hint mid-game uses what the player holds" >:: fun _ ->
           (* after picking up the key, the best move is back to the right *)
           let s = replay (init (Picture.level [ "a@AE" ])) [ Left ] in
           assert_equal (Some Right) (Solver.hint s) );
         ( "no hint once won" >:: fun _ ->
           assert_equal None (Solver.hint (won_state [ "@..E" ])) );
         ( "no hint when unsolvable" >:: fun _ ->
           assert_equal None (Solver.hint (init (Picture.level [ "@A.E" ]))) );
         ( "solve from a won state is the empty path" >:: fun _ ->
           assert_equal (Some []) (Solver.solve (won_state [ "@..E" ]))
             ~printer:string_of_path );
         ( "following hints wins the demo in exactly par moves" >:: fun _ ->
           (* stops after 100 moves, so wrong hints that go in circles fail
              the test instead of looping forever *)
           let rec follow s n =
             if is_won s then n
             else if n >= 100 then assert_failure "hints never reach the exit"
             else
               match Solver.hint s with
               | None -> assert_failure "no hint before winning"
               | Some d -> follow (replay s [ d ]) (n + 1)
           in
           assert_equal 20
             (follow (init (Picture.level demo)) 0)
             ~printer:string_of_int );
       ]

let explored_tests =
  "explored"
  >::: [
         ( "corridor: every square discovered once" >:: fun _ ->
           (* start, then the 3 squares to the right; going back left finds
              nothing new *)
           assert_equal 4
             (Solver.search (init (Picture.level [ "@..E" ]))).explored
             ~printer:string_of_int );
         ( "unsolvable: the whole reachable area, then stop" >:: fun _ ->
           let r = Solver.search (init (Picture.level [ "@.#E" ])) in
           assert_equal None r.path ~printer:string_of_path;
           assert_equal 2 r.explored ~printer:string_of_int );
         ( "a switch doubles the states: positions x on/off" >:: fun _ ->
           (* 3 squares, each reachable with the switch off and on; the gate
              and exit are only reachable with it on, and the search stops at
              the exit before discovering anything past it *)
           let r = Solver.search (init (Picture.level [ "@x.XE" ])) in
           assert_bool "finds a solution" (r.path <> None);
           assert_bool "more states than squares" (r.explored > 5) );
       ]

(* An independent check: depth-limited search with no visited set. It tries
   every sequence of legal moves up to [limit] long, so it cannot be fooled
   by a wrong notion of "same state". It is exponential, so it only runs on
   tiny levels. [brute s limit] is the length of a shortest winning
   sequence of at most [limit] moves, or [None]. *)
let brute s limit =
  let rec can_win s depth =
    is_won s
    || depth > 0
       && List.exists (fun (_, s') -> can_win s' (depth - 1)) (next_states s)
  in
  let rec first k =
    if k > limit then None else if can_win s k then Some k else first (k + 1)
  in
  first 0

(* A random 2-by-4 level with '@' and 'E' at fixed corners and random tiles
   elsewhere, drawn from one random state seeded with 3110 so failures are
   reproducible. *)
let random_level rng =
  let symbols = [| '.'; '.'; '.'; '#'; 'a'; 'A'; 'x'; 'X'; 'b'; 'B' |] in
  let cell () = symbols.(Random.State.int rng (Array.length symbols)) in
  let row0 = String.init 4 (fun i -> if i = 0 then '@' else cell ()) in
  let row1 = String.init 4 (fun i -> if i = 3 then 'E' else cell ()) in
  [ row0; row1 ]

let brute_tests =
  "agrees with brute force"
  >::: [
         ( "300 random tiny levels" >:: fun _ ->
           let rng = Random.State.make [| 3110 |] in
           let limit = 12 in
           for _ = 1 to 300 do
             let lines = random_level rng in
             let lvl = Picture.level lines in
             let expected = brute (init lvl) limit in
             let actual =
               match Solver.par lvl with
               | Some n when n <= limit -> Some n
               | Some _ | None -> None
             in
             assert_equal expected actual ~printer:string_of_par
               ~msg:(String.concat " / " lines)
           done );
       ]

let () =
  run_test_tt_main
    ("solver" >::: [ par_tests; hint_tests; explored_tests; brute_tests ])
