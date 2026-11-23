open OUnit2
open Levels
open Level

(* ---------- Helpers ---------- *)

let p row col = { row; col }

let get_ok = function
  | Ok x -> x
  | Error _ -> assert_failure "expected Ok, got Error"

(* Assert that [r] is an error whose message is [expected]. Comparing whole
   messages checks the line numbers too. *)
let assert_error_msg to_string expected r =
  match r with
  | Ok _ -> assert_failure ("expected an error: " ^ expected)
  | Error e -> assert_equal ~printer:Fun.id expected (to_string e)

let level_error expected r = assert_error_msg Level_file.error_to_string expected r
let save_error expected r = assert_error_msg Save.error_to_string expected r
let make_error expected r = assert_error_msg Fun.id expected r

let pos_printer q = Printf.sprintf "{row=%d; col=%d}" q.row q.col
let rows_printer rows = "\n" ^ String.concat "\n" rows

(* A small valid level written as a list of rows. *)
let w = Wall
let f = Floor

let small_rows =
  [
    [ w; w; w; w; w ];
    [ w; f; Key "r"; Door "r"; w ];
    [ w; Switch "s"; Gate ("s", true); Exit; w ];
    [ w; w; w; w; w ];
  ]

let small = get_ok (make ~name:"small" ~start:(p 1 1) small_rows)

(* ---------- Level.make and accessors ---------- *)

let level_tests =
  [
    ( "accessors on a valid level" >:: fun _ ->
      assert_equal "small" (name small);
      assert_equal 5 (width small);
      assert_equal 4 (height small);
      assert_equal ~printer:pos_printer (p 1 1) (start small);
      assert_equal ~printer:pos_printer (p 2 3) (exit small) );
    ( "tile_at inside and outside the grid" >:: fun _ ->
      assert_equal (Key "r") (tile_at small (p 1 2));
      assert_equal (Gate ("s", true)) (tile_at small (p 2 2));
      assert_equal Floor (tile_at small (p 1 1));
      assert_equal Wall (tile_at small (p (-1) 2));
      assert_equal Wall (tile_at small (p 2 5));
      assert_equal Wall (tile_at small (p 4 0)) );
    ( "in_bounds at the corners and just outside" >:: fun _ ->
      assert_bool "top-left" (in_bounds small (p 0 0));
      assert_bool "bottom-right" (in_bounds small (p 3 4));
      assert_bool "below" (not (in_bounds small (p 4 4)));
      assert_bool "right" (not (in_bounds small (p 3 5)));
      assert_bool "negative" (not (in_bounds small (p 0 (-1)))) );
    ( "tiles lists special squares in reading order" >:: fun _ ->
      assert_equal
        [
          (p 1 2, Key "r");
          (p 1 3, Door "r");
          (p 2 1, Switch "s");
          (p 2 2, Gate ("s", true));
          (p 2 3, Exit);
        ]
        (tiles small) );
    ( "to_rows draws every symbol and the player" >:: fun _ ->
      assert_equal ~printer:rows_printer
        [ "#####"; "#@kD#"; "#sgE#"; "#####" ]
        (to_rows small) );
    ( "char_of_tile for closed gate and floor" >:: fun _ ->
      assert_equal 'G' (char_of_tile (Gate ("x", false)));
      assert_equal ' ' (char_of_tile Floor) );
    ( "make rejects a name with a space" >:: fun _ ->
      make_error "the name \"my level\" must be one word with no spaces"
        (make ~name:"my level" ~start:(p 1 1) small_rows) );
    ( "make rejects an empty level" >:: fun _ ->
      make_error "the level has no rows" (make ~name:"x" ~start:(p 0 0) []) );
    ( "make rejects a level that is too short" >:: fun _ ->
      make_error "the level must have at least 3 rows"
        (make ~name:"x" ~start:(p 0 0) [ [ w; w; w ]; [ w; w; w ] ]) );
    ( "make rejects a ragged level" >:: fun _ ->
      make_error "row 1 has 4 squares but row 0 has 5"
        (make ~name:"x" ~start:(p 1 1)
           [ [ w; w; w; w; w ]; [ w; f; Exit; w ]; [ w; w; w; w; w ] ]) );
    ( "make rejects a gap in the outer wall" >:: fun _ ->
      make_error
        "the edge of the level must be walls, but row 1 column 4 is not"
        (make ~name:"x" ~start:(p 1 1)
           [ [ w; w; w; w; w ]; [ w; f; Exit; f; f ]; [ w; w; w; w; w ] ]) );
    ( "make rejects a start outside the grid" >:: fun _ ->
      make_error "the start (row 9, column 1) is outside the level"
        (make ~name:"x" ~start:(p 9 1) small_rows) );
    ( "make rejects a start on a key" >:: fun _ ->
      make_error "the start (row 1, column 2) must be on an empty floor square"
        (make ~name:"x" ~start:(p 1 2) small_rows) );
    ( "make rejects a level with no exit" >:: fun _ ->
      make_error "the level has no exit"
        (make ~name:"x" ~start:(p 1 1)
           [ [ w; w; w; w ]; [ w; f; f; w ]; [ w; w; w; w ] ]) );
    ( "make rejects a level with two exits" >:: fun _ ->
      make_error "the level has more than one exit"
        (make ~name:"x" ~start:(p 1 1)
           [ [ w; w; w; w; w ]; [ w; f; Exit; Exit; w ]; [ w; w; w; w; w ] ]) );
    ( "make rejects a door with no key" >:: fun _ ->
      make_error "door \"blue\" has no key with the same label"
        (make ~name:"x" ~start:(p 1 1)
           [
             [ w; w; w; w; w ];
             [ w; f; Key "red"; Door "blue"; w ];
             [ w; Exit; w; w; w ];
             [ w; w; w; w; w ];
           ]) );
    ( "make allows a key with no door" >:: fun _ ->
      assert_bool "decoy key is fine"
        (Result.is_ok
           (make ~name:"x" ~start:(p 1 1)
              [ [ w; w; w; w; w ]; [ w; f; Key "a"; Exit; w ]; [ w; w; w; w; w ] ]))
    );
    ( "make rejects a switch with no gate" >:: fun _ ->
      make_error "switch \"a\" has no gate with the same label"
        (make ~name:"x" ~start:(p 1 1)
           [ [ w; w; w; w; w ]; [ w; f; Switch "a"; Exit; w ]; [ w; w; w; w; w ] ])
    );
    ( "make rejects a gate with no switch" >:: fun _ ->
      make_error "gate \"a\" has no switch with the same label"
        (make ~name:"x" ~start:(p 1 1)
           [
             [ w; w; w; w; w ];
             [ w; f; Gate ("a", false); Exit; w ];
             [ w; w; w; w; w ];
           ]) );
  ]

(* ---------- Level_file ---------- *)

let demo = get_ok (Level_file.load "../../levels/demo.txt")

let parse_tests =
  [
    ( "demo level loads with the expected layout" >:: fun _ ->
      assert_equal "demo" (name demo);
      assert_equal 10 (width demo);
      assert_equal 7 (height demo);
      assert_equal ~printer:pos_printer (p 1 1) (start demo);
      assert_equal ~printer:pos_printer (p 4 8) (exit demo);
      assert_equal
        [ (p 2 7, Door "red"); (p 3 3, Key "red"); (p 4 8, Exit) ]
        (tiles demo) );
    ( "labels are given out in reading order" >:: fun _ ->
      let lvl = get_ok (Level_file.load "data/switches.txt") in
      assert_equal
        [
          (p 1 3, Switch "a");
          (p 1 5, Gate ("a", false));
          (p 2 1, Key "x");
          (p 2 2, Switch "b");
          (p 2 4, Gate ("b", true));
          (p 2 7, Door "x");
          (p 3 1, Gate ("a", false));
          (p 3 6, Exit);
        ]
        (tiles lvl) );
    ( "missing label lines use the default label" >:: fun _ ->
      let lvl = get_ok (Level_file.parse "map:\n#####\n#@kD#\n#E  #\n#####\n") in
      assert_equal "unnamed" (name lvl);
      assert_equal (Key "default") (tile_at lvl (p 1 2));
      assert_equal (Door "default") (tile_at lvl (p 1 3)) );
    ( "default_name is used only when there is no name line" >:: fun _ ->
      let text = "map:\n####\n#@E#\n####\n" in
      assert_equal "lvl1" (name (get_ok (Level_file.parse ~default_name:"lvl1" text)));
      assert_equal "mine"
        (name (get_ok (Level_file.parse ~default_name:"lvl1" ("name: mine\n" ^ text)))) );
    ( "load names a level after its file" >:: fun _ ->
      let tmp = Filename.temp_file "my level" ".txt" in
      Out_channel.with_open_bin tmp (fun oc ->
          output_string oc "map:\n####\n#@E#\n####\n");
      let loaded = get_ok (Level_file.load tmp) in
      Sys.remove tmp;
      assert_equal ~printer:Fun.id
        (String.map
           (fun c -> if c = ' ' then '_' else c)
           (Filename.remove_extension (Filename.basename tmp)))
        (name loaded) );
    ( "dots and spaces are both floor" >:: fun _ ->
      let a = get_ok (Level_file.parse "map:\n#####\n#@..#\n#..E#\n#####\n") in
      let b = get_ok (Level_file.parse "map:\n#####\n#@  #\n#  E#\n#####\n") in
      assert_equal a b );
    ( "comments, blank lines, CRLF endings and trailing spaces are accepted"
    >:: fun _ ->
      let text =
        "; a comment\r\n\r\nname: crlf  \r\n  ; indented comment\r\nmap:\r\n####   \r\n#@E#\r\n####\r\n\r\n\r\n"
      in
      let lvl = get_ok (Level_file.parse text) in
      assert_equal "crlf" (name lvl);
      assert_equal ~printer:rows_printer [ "####"; "#@E#"; "####" ] (to_rows lvl) );
    ( "to_string writes the expected text" >:: fun _ ->
      assert_equal ~printer:Fun.id
        "name: small\nkeys: r\ndoors: r\nswitches: s\ngates: s\nmap:\n#####\n#@kD#\n#sgE#\n#####\n"
        (Level_file.to_string small) );
    ( "to_string then parse gives back the demo level" >:: fun _ ->
      assert_equal demo (get_ok (Level_file.parse (Level_file.to_string demo))) );
    ( "to_string then parse gives back the switches level" >:: fun _ ->
      let lvl = get_ok (Level_file.load "data/switches.txt") in
      assert_equal lvl (get_ok (Level_file.parse (Level_file.to_string lvl))) );
  ]

let parse_error_tests =
  let err name text expected =
    name >:: fun _ -> level_error expected (Level_file.parse text)
  in
  [
    err "missing map line" "name: x\n" "line 1: missing \"map:\" line before the grid";
    err "header line without a colon" "name: x\nhello\nmap:\n"
      "line 2: expected \"field: value\" or \"map:\", got \"hello\"";
    err "unknown field" "name: x\ndoor: red\nmap:\n" "line 2: unknown field \"door\"";
    err "duplicate name" "name: x\nname: y\nmap:\n" "line 2: \"name\" is given twice";
    err "duplicate labels" "keys: a\nkeys: b\nmap:\n" "line 2: \"keys\" is given twice";
    err "empty name" "name:\nmap:\n" "line 1: \"name\" is empty";
    err "name with two words" "name: my level\nmap:\n"
      "line 1: the name must be one word, got \"my level\"";
    err "text after map:" "map: ###\n" "line 1: nothing may follow \"map:\" on the same line";
    err "empty map" "name: x\nmap:\n\n\n" "line 2: the map is empty";
    err "unknown symbol reports line and column" "name: x\nmap:\n#####\n#@x #\n#####\n"
      "line 4: unknown symbol 'x' in column 3";
    err "tab is not floor" "map:\n####\n#@\t#\n####\n" "line 3: unknown symbol '\\t' in column 3";
    err "ragged row" "map:\n#####\n#@E#\n#####\n"
      "line 3: this row is 4 characters wide but the first row is 5";
    err "blank line inside the map" "map:\n####\n#@E#\n\n####\n" "line 4: blank line inside the map";
    err "no start" "name: x\nmap:\n####\n# E#\n####\n" "line 2: the map has no start square (@)";
    err "two starts reports the second" "map:\n#####\n#@ E#\n# @ #\n#####\n"
      "line 4: the map has more than one start square (@)";
    err "too many labels" "name: x\nkeys: a b\nmap:\n####\n#@k#\n#E #\n####\n"
      "line 2: \"keys\" lists 2 label(s) but the map has 1 k tile(s)";
    err "too few gate labels" "switches: a\ngates: a\nmap:\n#####\n#@sG#\n#EgG#\n#####\n"
      "line 2: \"gates\" lists 1 label(s) but the map has 3 G or g tile(s)";
    err "valid syntax but no exit" "map:\n####\n#@ #\n####\n" "invalid level: the level has no exit";
    err "mismatched door label" "keys: red\ndoors: blue\nmap:\n#####\n#@kD#\n#E  #\n#####\n"
      "invalid level: door \"blue\" has no key with the same label";
    err "open edge" "map:\n####\n#@E \n####\n"
      "line 3: this row is 3 characters wide but the first row is 4";
    err "door in the outer wall" "map:\n####\n#@ED\n####\n"
      "invalid level: the edge of the level must be walls, but row 1 column 3 is not";
    ( "file that does not exist" >:: fun _ ->
      match Level_file.load "data/no_such_file.txt" with
      | Error (Level_file.Cannot_read _ as e) ->
          assert_bool "message"
            (String.starts_with ~prefix:"cannot read level file: "
               (Level_file.error_to_string e))
      | _ -> assert_failure "expected Cannot_read" );
    ( "file with no exit" >:: fun _ ->
      level_error "invalid level: the level has no exit" (Level_file.load "data/no_exit.txt") );
  ]

(* Random valid levels survive a round trip through the file format. Row 1
   always starts with the player, the exit, a key, a switch and its gate, so
   that any random filling of the other squares is a valid level. *)
let random_level =
  let open QCheck2.Gen in
  let interior_tile =
    oneof_list
      [ Floor; Floor; Wall; Key "a"; Key "b"; Door "a"; Switch "s";
        Gate ("s", false); Gate ("s", true) ]
  in
  let* width = int_range 7 12 and* height = int_range 3 8 in
  let+ cells = list_size (return (width * height)) interior_tile in
  let tile r c =
    if r = 0 || c = 0 || r = height - 1 || c = width - 1 then Wall
    else if r = 1 && c <= 5 then
      List.nth [ Floor; Exit; Key "a"; Switch "s"; Gate ("s", false) ] (c - 1)
    else List.nth cells ((r * width) + c)
  in
  get_ok
    (make ~name:"random" ~start:(p 1 1)
       (List.init height (fun r -> List.init width (tile r))))

let roundtrip_property =
  QCheck_ounit.to_ounit2_test
    (QCheck2.Test.make ~count:300 ~name:"random levels round-trip through to_string"
       ~print:Level_file.to_string random_level (fun lvl ->
         Level_file.parse (Level_file.to_string lvl) = Ok lvl))

(* ---------- Save ---------- *)

let temp_path () =
  let path = Filename.temp_file "escape_save" ".txt" in
  Sys.remove path;
  path

let save_tests =
  [
    ( "empty has no scores" >:: fun _ ->
      assert_equal None (Save.best Save.empty "demo");
      assert_equal [] (Save.bests Save.empty) );
    ( "record keeps the fewest moves" >:: fun _ ->
      let s = Save.record Save.empty "demo" 30 in
      assert_equal (Some 30) (Save.best s "demo");
      let s = Save.record s "demo" 40 in
      assert_equal (Some 30) (Save.best s "demo");
      let s = Save.record s "demo" 22 in
      assert_equal (Some 22) (Save.best s "demo") );
    ( "record does not change other levels" >:: fun _ ->
      let s = Save.record (Save.record Save.empty "demo" 30) "seed-7" 50 in
      assert_equal (Some 30) (Save.best s "demo");
      assert_equal (Some 50) (Save.best s "seed-7");
      assert_equal None (Save.best s "other") );
    ( "record accepts zero moves" >:: fun _ ->
      assert_equal (Some 0) (Save.best (Save.record Save.empty "demo" 0) "demo") );
    ( "record rejects bad ids and negative moves" >:: fun _ ->
      assert_raises (Invalid_argument "Save.record: invalid level id my level")
        (fun () -> Save.record Save.empty "my level" 3);
      assert_raises (Invalid_argument "Save.record: invalid level id ") (fun () ->
          Save.record Save.empty "" 3);
      assert_raises (Invalid_argument "Save.record: negative move count") (fun () ->
          Save.record Save.empty "demo" (-1)) );
    ( "every level name is a valid save id" >:: fun _ ->
      assert_bool "demo" (Save.valid_id (name demo));
      assert_bool "space" (not (Save.valid_id "a b")) );
    ( "to_string sorts by level id" >:: fun _ ->
      let s = Save.record (Save.record Save.empty "zeta" 5) "alpha" 9 in
      assert_equal ~printer:Fun.id "escape-room-save 1\nbest alpha 9\nbest zeta 5\n"
        (Save.to_string s) );
    ( "of_string reads what to_string writes" >:: fun _ ->
      let s = Save.record (Save.record Save.empty "demo" 20) "seed-99" 41 in
      assert_equal [ ("demo", 20); ("seed-99", 41) ]
        (Save.bests (get_ok (Save.of_string (Save.to_string s)))) );
    ( "of_string tolerates blank lines, CRLF and extra spaces" >:: fun _ ->
      let s = get_ok (Save.of_string "escape-room-save 1\r\n\r\n  best   demo  7 \r\n") in
      assert_equal [ ("demo", 7) ] (Save.bests s) );
    ( "load of a missing file is empty progress" >:: fun _ ->
      assert_equal [] (Save.bests (get_ok (Save.load (temp_path ())))) );
    ( "load reads a saved file" >:: fun _ ->
      assert_equal [ ("demo", 25); ("seed-42", 31) ]
        (Save.bests (get_ok (Save.load "data/good_save.txt"))) );
    ( "save then load gives the same scores and leaves no temp file" >:: fun _ ->
      let path = temp_path () in
      let s = Save.record (Save.record Save.empty "demo" 20) "b" 3 in
      assert_equal (Ok ()) (Save.save path s);
      let first = get_ok (Save.load path) in
      assert_equal (Save.bests s) (Save.bests first);
      (* Saving again replaces the old contents. *)
      assert_equal (Ok ()) (Save.save path (Save.record s "demo" 18));
      assert_equal (Some 18) (Save.best (get_ok (Save.load path)) "demo");
      assert_bool "no .tmp left" (not (Sys.file_exists (path ^ ".tmp")));
      Sys.remove path );
    ( "save into a missing directory is an Io error" >:: fun _ ->
      match Save.save "no_such_dir/save.txt" Save.empty with
      | Error (Save.Io _ as e) ->
          assert_bool "message"
            (String.starts_with ~prefix:"cannot access save file: "
               (Save.error_to_string e))
      | _ -> assert_failure "expected Io error" );
    ( "load of a directory is an Io error" >:: fun _ ->
      match Save.load "data" with
      | Error (Save.Io _) -> ()
      | _ -> assert_failure "expected Io error" );
  ]

let save_error_tests =
  let err name text expected = name >:: fun _ -> save_error expected (Save.of_string text) in
  [
    err "empty file" "" "save file is damaged (line 1): this is not an escape room save file";
    err "wrong first line" "hello\nbest demo 3\n"
      "save file is damaged (line 1): this is not an escape room save file";
    err "newer version" "escape-room-save 2\n"
      "save file is damaged (line 1): unsupported save version \"2\"";
    err "move count is not a number" "escape-room-save 1\nbest demo 12\nbest x ten\n"
      "save file is damaged (line 3): move count \"ten\" is not a non-negative whole number";
    err "negative move count" "escape-room-save 1\nbest demo -4\n"
      "save file is damaged (line 2): move count \"-4\" is not a non-negative whole number";
    err "level listed twice" "escape-room-save 1\nbest demo 4\nbest demo 3\n"
      "save file is damaged (line 3): level \"demo\" appears twice";
    err "unknown entry" "escape-room-save 1\nscore demo 4\n"
      "save file is damaged (line 2): expected \"best <level> <moves>\", got \"score demo 4\"";
    ( "load reports a damaged file" >:: fun _ ->
      save_error
        "save file is damaged (line 2): move count \"twelve\" is not a non-negative whole number"
        (Save.load "data/bad_save.txt") );
  ]

let () =
  run_test_tt_main
    ("levels"
    >::: [
           "Level" >::: level_tests;
           "Level_file" >::: parse_tests;
           "Level_file errors" >::: parse_error_tests;
           roundtrip_property;
           "Save" >::: save_tests;
           "Save errors" >::: save_error_tests;
         ])
