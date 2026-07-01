(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.utils,pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.yojson,pa_ppx.deriving_plugins.located_yojson,pa_ppx.import *)

open Pa_ppx_utils
open Exec
module M = Mimick

let tracelog = ref []

let sim1 j = match j with
    M.PredictionContext_ENTER_merge (pc1, pc2, rootIsWildcard, mc_opt) ->
    Std.push tracelog j ;
    let pc1 = PC.of_mimick pc1 in
    let pc2 = PC.of_mimick pc2 in
    let mc_opt = Option.map PC.MC.of_mimick mc_opt in
    let pc3 = PC.merge pc1 pc2 rootIsWildcard mc_opt in
    let pc3 = PC.to_mimick pc3 in
    Std.push tracelog (M.PredictionContext_EXIT_merge pc3) ;
    ()
