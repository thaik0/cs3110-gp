module KeySet = Set.Make (struct
  type t = Rules.key

  let compare = Rules.compare_key
end)

type result = {
  path : Rules.direction list option;
  explored : int;
}

(* The frontier holds pairs [(s, rev_path)], where [rev_path] is the list of
   moves that reached [s], most recent first. Consing onto it shares the
   tail, so storing a path for every state costs O(1) per state. [seen]
   holds the key of every state ever added to the frontier, so no state is
   expanded twice. *)
let search start =
  let frontier = Queue.create () in
  Queue.add (start, []) frontier;
  let seen = ref (KeySet.singleton (Rules.key start)) in
  let rec loop () =
    match Queue.take_opt frontier with
    | None -> None
    | Some (s, rev_path) when Rules.is_won s -> Some (List.rev rev_path)
    | Some (s, rev_path) ->
        List.iter
          (fun (d, s') ->
            let k = Rules.key s' in
            if not (KeySet.mem k !seen) then begin
              seen := KeySet.add k !seen;
              Queue.add (s', d :: rev_path) frontier
            end)
          (Rules.next_states s);
        loop ()
  in
  let path = loop () in
  { path; explored = KeySet.cardinal !seen }

let solve s = (search s).path
let par lvl = Option.map List.length (solve (Rules.init lvl))

let hint s =
  match solve s with
  | Some (d :: _) -> Some d
  | Some [] | None -> None
