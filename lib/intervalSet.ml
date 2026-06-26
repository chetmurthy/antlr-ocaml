(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.utils,pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.located_yojson,pa_ppx.deriving_plugins.yojson,pa_ppx.deriving_plugins.located_yojson,pa_ppx.import *)

type t = {
    intervals : Range.t list
  }
[@@deriving yojson,located_yojson, show]

let dump pps t =
  match t.intervals with
    [] -> Fmt.(pf pps "{}")
  | l -> Fmt.(pf pps "{%a}" (list ~sep:(const string ", ") Range.dump) l)

let mk () = { intervals = [] }

let ofList l = { intervals = l }

let add v t =
  let open Range in
  let rec addrec acc v = function
      [] -> (List.rev acc) @ [v]
    | (i::tl) as l ->
       match Range.compare v i with
         -1 ->
         (List.rev acc) @ (v :: i :: tl)
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

