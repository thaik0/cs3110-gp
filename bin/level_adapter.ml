module L = Levels.Level
module R = Escape.Rules

type t = { level : R.level; labels : string list }

let level t = t.level
let label t id = List.nth t.labels id

let of_level source =
  let tiles = L.tiles source in
  if List.exists (function _, L.Gate (_, true) -> true | _ -> false) tiles then
    Error "Initially open gates are not supported by the current game engine."
  else
    let labels =
      List.filter_map
        (function
          | _, (L.Key s | L.Door s | L.Switch s | L.Gate (s, _)) -> Some s
          | _ -> None)
        tiles
      |> List.sort_uniq String.compare
    in
    let id s = Option.get (List.find_index (String.equal s) labels) in
    let convert = function
      | L.Floor -> R.Floor
      | L.Wall -> R.Wall
      | L.Exit -> R.Exit
      | L.Key s -> R.Key (id s)
      | L.Door s -> R.Door (id s)
      | L.Switch s -> R.Switch (id s)
      | L.Gate (s, _) -> R.Gate (id s)
    in
    let grid =
      Array.init (L.height source) (fun row ->
          Array.init (L.width source) (fun col ->
              convert (L.tile_at source { row; col })))
    in
    let start = L.start source in
    let level = R.make_level grid { row = start.row; col = start.col } in
    Ok { level; labels }
