open Escape.Rules

let tile_of_char = function
  | '.' | '@' -> Floor
  | '#' -> Wall
  | 'E' -> Exit
  | 'a' -> Key 1
  | 'b' -> Key 2
  | 'c' -> Key 3
  | 'A' -> Door 1
  | 'B' -> Door 2
  | 'C' -> Door 3
  | 'x' -> Switch 1
  | 'y' -> Switch 2
  | 'z' -> Switch 3
  | 'X' -> Gate 1
  | 'Y' -> Gate 2
  | 'Z' -> Gate 3
  | c -> failwith (Printf.sprintf "Picture.level: unknown symbol %C" c)

let level lines =
  let start = ref { row = -1; col = -1 } in
  let grid =
    lines
    |> List.mapi (fun row line ->
           Array.init (String.length line) (fun col ->
               if line.[col] = '@' then start := { row; col };
               tile_of_char line.[col]))
    |> Array.of_list
  in
  make_level grid !start
