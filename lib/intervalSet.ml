(**pp -syntax camlp5o *)

type t = {
    intervals : Range.t list
  }

let mk () = { intervals = [] }

let add t v =
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
