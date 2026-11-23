(* levelcheck FILE...

   Loads each level file and prints the level as the player will first see it,
   or the error that stops it from loading. Exits with status 1 if any file
   fails. Use it to check handwritten levels before committing them. *)

open Levels

let describe_tile (p, t) =
  let where = Printf.sprintf "(row %d, col %d)" p.Level.row p.Level.col in
  match t with
  | Level.Key l -> Some (Printf.sprintf "  key %S at %s" l where)
  | Level.Door l -> Some (Printf.sprintf "  door %S at %s" l where)
  | Level.Switch l -> Some (Printf.sprintf "  switch %S at %s" l where)
  | Level.Gate (l, o) ->
      Some
        (Printf.sprintf "  gate %S at %s, starts %s" l where
           (if o then "open" else "closed"))
  | Level.Floor | Level.Wall | Level.Exit -> None

let check path =
  match Level_file.load path with
  | Error e ->
      Printf.printf "%s: %s\n" path (Level_file.error_to_string e);
      false
  | Ok lvl ->
      Printf.printf "%s: level %S, %d x %d\n" path (Level.name lvl)
        (Level.width lvl) (Level.height lvl);
      List.iter print_endline (Level.to_rows lvl);
      List.iter print_endline (List.filter_map describe_tile (Level.tiles lvl));
      true

let () =
  match List.tl (Array.to_list Sys.argv) with
  | [] ->
      prerr_endline "usage: levelcheck FILE...";
      exit 2
  | paths ->
      let results = List.map check paths in
      if List.mem false results then exit 1
