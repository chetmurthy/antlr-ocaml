
type t =
  { start : int
  ; stop : int
  ; step : int
  }

let mk ?(step=1) ?start stop =
  let start = match start with
      None -> 0
    | Some n -> n in
  assert (start <= stop) ;
  { start ; stop ; step }

let rec compare r1 r2 =
  if r1.start > r2.start then
    - (compare r2 r1)
  else (* r1.start <= r2.start *)
  if r1.stop < r2.start then
    -1
  else (* r1.start <= r2.start && r2.start <= r1.stop *)
    0

let merge r1 r2 =
  (* r1 precedes & overlaps r2 *)
  if (r1.start <= r2.start && r2.start <= r1.stop) then
    Some (mk ~start:r1.start (max r1.stop r2.stop))
  else if (r2.start <= r1.start && r1.start <= r2.stop) then
    (* r2 precedes & overlaps r1 *)
    Some (mk ~start:r2.start (max r1.stop r2.stop))
  else
    None
