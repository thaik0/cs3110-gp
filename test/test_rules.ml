open OUnit2
open Escape
open Rules

(* Test helper only, so tests can draw levels as pictures. This is NOT the
   real level file format (that belongs to the level loader). Symbols:
   '.' floor, '#' wall, 'E' exit, '@' start (a floor square),
   'a' 'b' keys 1 and 2, 'A' 'B' doors 1 and 2,
   'x' 'y' switches 1 and 2, 'X' 'Y' gates 1 and 2. *)
let level_of_strings lines =
  let start = ref { row = -1; col = -1 } in
  let tile_of_char row col = function
    | '.' -> Floor
    | '#' -> Wall
    | 'E' -> Exit
    | '@' ->
        start := { row; col };
        Floor
    | 'a' -> Key 1
    | 'b' -> Key 2
    | 'A' -> Door 1
    | 'B' -> Door 2
    | 'x' -> Switch 1
    | 'y' -> Switch 2
    | 'X' -> Gate 1
    | 'Y' -> Gate 2
    | c -> failwith (Printf.sprintf "bad test symbol %c" c)
  in
  let grid =
    lines
    |> List.mapi (fun row line ->
           Array.init (String.length line) (fun col ->
               tile_of_char row col line.[col]))
    |> Array.of_list
  in
  make_level grid !start

(* [moved s d] is the state after moving [s] in direction [d]. Fails the
   test if the move is blocked. *)
let moved s d =
  match move s d with
  | Moved s' -> s'
  | Blocked _ -> assert_failure "expected the move to succeed"

(* [moves_from s ds] applies every direction in [ds] in order. *)
let moves_from s ds = List.fold_left moved s ds

let assert_blocked expected s d =
  match move s d with
  | Moved _ -> assert_failure "expected the move to be blocked"
  | Blocked b -> assert_equal expected b

let pp_pos p = Printf.sprintf "(%d, %d)" p.row p.col
let pp_ints l = "[" ^ String.concat "; " (List.map string_of_int l) ^ "]"

let corridor = level_of_strings [ "@..E" ]

let raises_invalid name f =
  name >:: fun _ ->
  match f () with
  | _ -> assert_failure "expected Invalid_level"
  | exception Invalid_level _ -> ()

let level_tests =
  "make_level"
  >::: [
         raises_invalid "no rows" (fun () -> make_level [||] { row = 0; col = 0 });
         raises_invalid "empty row" (fun () ->
             make_level [| [||] |] { row = 0; col = 0 });
         raises_invalid "ragged rows" (fun () ->
             make_level [| [| Floor; Exit |]; [| Floor |] |] { row = 0; col = 0 });
         raises_invalid "start out of bounds" (fun () ->
             make_level [| [| Floor; Exit |] |] { row = 0; col = 5 });
         raises_invalid "start on a wall" (fun () ->
             make_level [| [| Wall; Exit |] |] { row = 0; col = 0 });
         raises_invalid "no exit" (fun () ->
             make_level [| [| Floor; Floor |] |] { row = 0; col = 0 });
         ( "size and start" >:: fun _ ->
           let lvl = level_of_strings [ "#####"; "#@.E#"; "#####" ] in
           assert_equal 3 (rows lvl) ~printer:string_of_int;
           assert_equal 5 (cols lvl) ~printer:string_of_int;
           assert_equal { row = 1; col = 1 } (start lvl) ~printer:pp_pos );
         ( "grid is copied" >:: fun _ ->
           let grid = [| [| Floor; Exit |] |] in
           let lvl = make_level grid { row = 0; col = 0 } in
           grid.(0).(1) <- Wall;
           assert_equal Exit (tile_at lvl { row = 0; col = 1 }) );
         ( "in_bounds" >:: fun _ ->
           assert_bool "inside" (in_bounds corridor { row = 0; col = 3 });
           assert_bool "right edge" (not (in_bounds corridor { row = 0; col = 4 }));
           assert_bool "negative" (not (in_bounds corridor { row = -1; col = 0 })) );
         ( "tile_at out of bounds" >:: fun _ ->
           assert_raises (Invalid_argument "Rules.tile_at: position out of bounds")
             (fun () -> tile_at corridor { row = 1; col = 0 }) );
       ]

let direction_tests =
  "directions"
  >::: [
         ( "step_pos" >:: fun _ ->
           let p = { row = 2; col = 2 } in
           assert_equal { row = 1; col = 2 } (step_pos p Up) ~printer:pp_pos;
           assert_equal { row = 3; col = 2 } (step_pos p Down) ~printer:pp_pos;
           assert_equal { row = 2; col = 1 } (step_pos p Left) ~printer:pp_pos;
           assert_equal { row = 2; col = 3 } (step_pos p Right) ~printer:pp_pos );
         ( "direction_of_char" >:: fun _ ->
           assert_equal (Some Up) (direction_of_char 'w');
           assert_equal (Some Left) (direction_of_char 'A');
           assert_equal (Some Down) (direction_of_char 's');
           assert_equal (Some Right) (direction_of_char 'D');
           assert_equal None (direction_of_char 'q') );
       ]

let movement_tests =
  "movement"
  >::: [
         ( "initial state" >:: fun _ ->
           let s = init corridor in
           assert_equal { row = 0; col = 0 } (player s) ~printer:pp_pos;
           assert_equal [] (keys_held s) ~printer:pp_ints;
           assert_equal 0 (moves s) ~printer:string_of_int;
           assert_bool "not won" (not (is_won s)) );
         ( "move onto floor" >:: fun _ ->
           let s = moved (init corridor) Right in
           assert_equal { row = 0; col = 1 } (player s) ~printer:pp_pos;
           assert_equal 1 (moves s) ~printer:string_of_int );
         ( "move is pure" >:: fun _ ->
           let s = init corridor in
           ignore (moved s Right);
           assert_equal { row = 0; col = 0 } (player s) ~printer:pp_pos );
         ( "wall blocks" >:: fun _ ->
           assert_blocked Hit_wall (init (level_of_strings [ "@#E" ])) Right );
         ( "edge blocks" >:: fun _ ->
           let s = init corridor in
           assert_blocked Out_of_bounds s Left;
           assert_blocked Out_of_bounds s Up;
           assert_blocked Out_of_bounds s Down );
         ( "reach exit wins" >:: fun _ ->
           let s = moves_from (init corridor) [ Right; Right; Right ] in
           assert_bool "won" (is_won s);
           assert_equal 3 (moves s) ~printer:string_of_int );
         ( "no moves after winning" >:: fun _ ->
           let s = moves_from (init corridor) [ Right; Right; Right ] in
           assert_blocked Already_won s Left );
       ]

let key_door_tests =
  "keys and doors"
  >::: [
         ( "door blocks without key" >:: fun _ ->
           assert_blocked (Locked_door 1) (init (level_of_strings [ "@AE" ])) Right );
         ( "pick up key" >:: fun _ ->
           let s = moved (init (level_of_strings [ "@aE" ])) Right in
           assert_bool "has key 1" (has_key s 1);
           assert_equal [ 1 ] (keys_held s) ~printer:pp_ints;
           assert_equal Floor (current_tile s { row = 0; col = 1 });
           assert_equal (Key 1) (tile_at (level s) { row = 0; col = 1 }) );
         ( "key opens matching door" >:: fun _ ->
           let s = moves_from (init (level_of_strings [ "@aAE" ])) [ Right; Right ] in
           assert_equal { row = 0; col = 2 } (player s) ~printer:pp_pos );
         ( "wrong key does not open door" >:: fun _ ->
           let s = moved (init (level_of_strings [ "@bAE" ])) Right in
           assert_blocked (Locked_door 1) s Right );
         ( "key is not used up" >:: fun _ ->
           let s =
             moves_from (init (level_of_strings [ "@aA.AE" ])) [ Right; Right; Right; Right ]
           in
           assert_equal { row = 0; col = 4 } (player s) ~printer:pp_pos;
           assert_bool "still has key" (has_key s 1) );
         ( "keys are sorted with no duplicates" >:: fun _ ->
           let s =
             moves_from (init (level_of_strings [ "@baE" ])) [ Right; Right; Left; Right ]
           in
           assert_equal [ 1; 2 ] (keys_held s) ~printer:pp_ints );
       ]

let switch_gate_tests =
  "switches and gates"
  >::: [
         ( "closed gate blocks" >:: fun _ ->
           let s = init (level_of_strings [ "@XE" ]) in
           assert_bool "gate closed" (not (gate_open s 1));
           assert_blocked (Closed_gate 1) s Right );
         ( "switch opens gate" >:: fun _ ->
           (* x @ X E : step left onto the switch, then walk through *)
           let s = moved (init (level_of_strings [ "x@XE" ])) Left in
           assert_bool "switch on" (switch_on s 1);
           assert_bool "gate open" (gate_open s 1);
           let s = moves_from s [ Right; Right ] in
           assert_equal { row = 0; col = 2 } (player s) ~printer:pp_pos );
         ( "stepping on switch again closes gate" >:: fun _ ->
           let s = moves_from (init (level_of_strings [ "x@XE" ])) [ Left; Right; Left ] in
           assert_bool "gate closed again" (not (gate_open s 1)) );
         ( "switch only affects its own gates" >:: fun _ ->
           let s = moves_from (init (level_of_strings [ "x@YE" ])) [ Left; Right ] in
           assert_blocked (Closed_gate 2) s Right );
       ]

let search_tests =
  "next_states and keys"
  >::: [
         ( "next_states in a corridor" >:: fun _ ->
           let ds = List.map fst (next_states (moved (init corridor) Right)) in
           assert_equal [ Left; Right ] ds );
         ( "next_states from a corner" >:: fun _ ->
           let lvl = level_of_strings [ "@."; ".E" ] in
           assert_equal [ Down; Right ] (List.map fst (next_states (init lvl))) );
         ( "next_states empty when won" >:: fun _ ->
           let s = moves_from (init corridor) [ Right; Right; Right ] in
           assert_equal [] (next_states s) );
         ( "same key ignores move count" >:: fun _ ->
           let s0 = init corridor in
           let s2 = moves_from s0 [ Right; Left ] in
           assert_equal 0 (compare_key (key s0) (key s2)) ~printer:string_of_int );
         ( "different keys held give a different key" >:: fun _ ->
           let s0 = moved (init (level_of_strings [ "@.aE" ])) Right in
           let s1 = moves_from s0 [ Right; Left ] in
           assert_bool "differ" (compare_key (key s0) (key s1) <> 0) );
       ]

let display_tests =
  "to_string"
  >::: [
         ( "draws grid" >:: fun _ ->
           let s = init (level_of_strings [ "####"; "#@aA"; "#xXE" ]) in
           assert_equal "####\n#@kD\n#sGE\n" (to_string s) ~printer:Fun.id );
         ( "picked up key and open gate" >:: fun _ ->
           let s =
             moves_from (init (level_of_strings [ "####"; "#@aA"; "#xXE" ])) [ Right; Left; Down ]
           in
           assert_equal "####\n#..D\n#@_E\n" (to_string s) ~printer:Fun.id );
       ]

(* The MS2 demo level: grab the key, open the door, hit the switch, go
   through the gate, reach the exit. *)
let demo = level_of_strings [ "#######"; "#@.a#.#"; "#.###.#"; "#x.A.XE"; "#######" ]

let engine_tests =
  "engine"
  >::: [
         ( "step success" >:: fun _ ->
           let g, err = Engine.step (Engine.start corridor) Right in
           assert_equal None err;
           assert_equal 1 (moves (Engine.current g)) ~printer:string_of_int );
         ( "step blocked keeps game" >:: fun _ ->
           let g = Engine.start corridor in
           let g', err = Engine.step g Left in
           assert_equal (Some Out_of_bounds) err;
           assert_equal (player (Engine.current g)) (player (Engine.current g')) );
         ( "undo at start" >:: fun _ ->
           assert_equal None (Engine.undo (Engine.start corridor));
           assert_bool "cannot undo" (not (Engine.can_undo (Engine.start corridor))) );
         ( "undo goes back one move" >:: fun _ ->
           let g, _ = Engine.step (Engine.start corridor) Right in
           let g, _ = Engine.step g Right in
           match Engine.undo g with
           | None -> assert_failure "expected undo"
           | Some g ->
               assert_equal { row = 0; col = 1 } (player (Engine.current g)) ~printer:pp_pos;
               assert_equal 1 (moves (Engine.current g)) ~printer:string_of_int );
         ( "undo puts the key back" >:: fun _ ->
           let g, _ = Engine.step (Engine.start (level_of_strings [ "@aE" ])) Right in
           match Engine.undo g with
           | None -> assert_failure "expected undo"
           | Some g -> assert_equal [] (keys_held (Engine.current g)) ~printer:pp_ints );
         ( "restart" >:: fun _ ->
           let g, _ = Engine.step (Engine.start corridor) Right in
           let g = Engine.restart g in
           assert_equal 0 (moves (Engine.current g)) ~printer:string_of_int;
           assert_bool "nothing to undo" (not (Engine.can_undo g)) );
         ( "full demo playthrough" >:: fun _ ->
           let path =
             [ Right; Right; Left; Left; Down; Down; Right; Right; Right; Right; Right ]
           in
           let g =
             List.fold_left
               (fun g d ->
                 match Engine.step g d with
                 | g, None -> g
                 | _, Some _ -> assert_failure "demo move was blocked")
               (Engine.start demo) path
           in
           assert_bool "won" (Engine.is_won g);
           assert_equal 11 (moves (Engine.current g)) ~printer:string_of_int );
       ]

let () =
  run_test_tt_main
    ("rules"
    >::: [
           level_tests;
           direction_tests;
           movement_tests;
           key_door_tests;
           switch_gate_tests;
           search_tests;
           display_tests;
           engine_tests;
         ])
