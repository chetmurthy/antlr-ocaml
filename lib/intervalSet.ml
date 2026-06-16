(**pp -syntax camlp5o -package pa_ppx.deriving_plugins.std *)

type t = {
    intervals : Range.t list
  }
  [@@deriving show]

let dump pps t =
  match t.intervals with
    [] -> Fmt.(pf pps "{}")
  | l -> Fmt.(pf pps "{%a}" (list ~sep:(const string ", ") Range.dump) l)

let mk () = { intervals = [] }

let add v t =
  let open Range in
  let rec addrec acc v = function
      [] -> (List.rev acc) @ [v]
    | (i::tl) as l ->
       match Range.compare v i with
         -1 ->
         (List.rev acc) @ (v :: tl)
       | 1 ->
          addrec (i::acc) v tl
       | 0 ->
          let v = match Range.merge i v with
              Some v -> v
            | None -> assert false in
          addrec acc v tl
  in
  { intervals = addrec [] v t.intervals }

let addOne n t =
  let v = Range.mk ~start:n (n+1) in
  add v t

