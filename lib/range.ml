(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.utils,pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.located_yojson,pa_ppx.deriving_plugins.yojson,pa_ppx.deriving_plugins.located_yojson,pa_ppx.import *)

open Pa_ppx_utils
open Pa_ppx_base
open Ppxutil
open Std

type t =
  { start : int
  ; stop : int
  ; step : int
  }
[@@deriving yojson,located_yojson, show]

let dump pps t =
  if t.step = 1 then
    Fmt.(pf pps "<%d..%d>" t.start t.stop)
  else
  Fmt.(pf pps "<%d..%d/%d>" t.start t.stop t.step)

let mk ?(step=1) ?start stop =
  let start = match start with
      None -> 0
    | Some n -> n in
  if start > stop then
    Fmt.(failwithf "Range.mk: Invalid arguments: start (%d) > stop (%d)" start stop) ;
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

let must_merge r1 r2 =
  assert (0 = compare r1 r2)
  ; outSome(merge r1 r2)

let contains r n =
  r.start <= n && n < r.stop
