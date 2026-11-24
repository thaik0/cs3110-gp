  $ printf 'aq' | ../bin/main.exe ../levels/demo.txt test.save | grep -E 'Escape Room|Can.t move there|Goodbye'
  Escape Room
  Escape Room
  Can't move there.
  Goodbye!

  $ printf 'dddddsdq' | ../bin/main.exe ../levels/demo.txt test.save | grep -E 'Need the|Goodbye'
  Need the red key.
  Goodbye!

  $ printf 'ssssddwwurq' | ../bin/main.exe ../levels/demo.txt test.save | grep -E 'Inventory:|Moves:' | tail -6
  Inventory: red key
  Moves: 8
  Inventory: (empty)
  Moves: 7
  Inventory: (empty)
  Moves: 0

  $ printf 'ssssddwwssdddwwwddss' | ../bin/main.exe ../levels/demo.txt test.save | grep -E 'You escaped|Best:'
  You escaped in 20 moves!
  Best: 20 moves
  $ cat test.save
  escape-room-save 1
  best demo 20
