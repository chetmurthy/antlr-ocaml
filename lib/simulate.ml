(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.utils,pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.yojson,pa_ppx.deriving_plugins.located_yojson,pa_ppx.import *)

open Pa_ppx_utils
open Pa_ppx_located_yojson
open Exec
module M = Mimick

let tracelog = ref []

let emit () =
  let l = !tracelog  in
  tracelog := [] ;
  List.rev l

let sim1' j = match j with
    M.PredictionContext_ENTER_merge (pc1, pc2, rootIsWildcard, mc_opt) ->
    Std.push tracelog j ;
    let pc1 = PC.of_mimick pc1 in
    let pc2 = PC.of_mimick pc2 in
    let mc_opt = Option.map PC.MC.of_mimick mc_opt in
    let pc3 = PC.merge pc1 pc2 rootIsWildcard mc_opt in
    let pc3 = PC.to_mimick pc3 in
    Std.push tracelog (M.PredictionContext_EXIT_merge pc3) ;
    emit ()

let sim1 j =
  let jlog = j |> [%of_located_yojson: M.json_log_t] |> Json.raise_failwith_error_msg in
  let l = sim1' jlog in
  let l = List.map [%to_located_yojson: M.json_log_t] l in
  Stream.of_list l
