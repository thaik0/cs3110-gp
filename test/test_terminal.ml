let () =
  let open Terminal in
  List.iter
    (fun (c, expected) -> assert (command_of_char c = expected))
    [ ('w', Some Up); ('W', Some Up); ('a', Some Left); ('s', Some Down);
      ('d', Some Right); ('u', Some Undo); ('r', Some Restart);
      ('h', Some Hint); ('q', Some Quit); ('\n', None); ('x', None) ];
  let grid = [ "###"; "#@#"; "###" ] in
  assert
    (render ~grid ~inventory:[] ~moves:0 =
     "Escape Room\n\n###\n#@#\n###\n\nInventory: (empty)\nMoves: 0\n\nWASD: move | U: undo | R: restart | H: hint | Q: quit\n");
  assert
    (render ~grid ~inventory:[ "red key"; "blue key" ] ~moves:12 =
     "Escape Room\n\n###\n#@#\n###\n\nInventory: red key, blue key\nMoves: 12\n\nWASD: move | U: undo | R: restart | H: hint | Q: quit\n")
