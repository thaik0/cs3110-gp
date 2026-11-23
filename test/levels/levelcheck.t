The demo level loads and is drawn as the player first sees it.

  $ ../../tools/levelcheck.exe ../../levels/demo.txt
  ../../levels/demo.txt: level "demo", 10 x 7
  ##########
  #@     # #
  # #### D #
  # #k # # #
  # #  # #E#
  #      ###
  ##########
    door "red" at (row 2, col 7)
    key "red" at (row 3, col 3)

A broken file is reported with its line and column, and exit status 1.

  $ printf 'name: bad\nmap:\n#####\n#@?E#\n#####\n' > bad.txt
  $ ../../tools/levelcheck.exe bad.txt
  bad.txt: line 4: unknown symbol '?' in column 3
  [1]

Several files can be checked at once; the exit status is 1 if any fail.

  $ ../../tools/levelcheck.exe data/switches.txt data/no_exit.txt missing.txt
  data/switches.txt: level "switches", 9 x 5
  #########
  #@ s G  #
  #ks g  D#
  #G    E #
  #########
    switch "a" at (row 1, col 3)
    gate "a" at (row 1, col 5), starts closed
    key "x" at (row 2, col 1)
    switch "b" at (row 2, col 2)
    gate "b" at (row 2, col 4), starts open
    door "x" at (row 2, col 7)
    gate "a" at (row 3, col 1), starts closed
  data/no_exit.txt: invalid level: the level has no exit
  missing.txt: cannot read level file: missing.txt: No such file or directory
  [1]
