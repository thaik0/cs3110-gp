(* AF: [{now; past}] is a game whose current state is [now] and whose
   earlier states, most recent first, are [past].
   RI: [past] has exactly [Rules.moves now] states, and every state in it is
   on the same level as [now]. *)
type t = {
  now : Rules.state;
  past : Rules.state list;
}

let start lvl = { now = Rules.init lvl; past = [] }
let current g = g.now

let step g d =
  match Rules.move g.now d with
  | Rules.Moved s -> ({ now = s; past = g.now :: g.past }, None)
  | Rules.Blocked reason -> (g, Some reason)

let undo g =
  match g.past with
  | [] -> None
  | prev :: rest -> Some { now = prev; past = rest }

let restart g = start (Rules.level g.now)
let can_undo g = g.past <> []
let is_won g = Rules.is_won g.now
