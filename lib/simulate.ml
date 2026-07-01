(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.utils,pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.yojson,pa_ppx.deriving_plugins.located_yojson,pa_ppx.import *)

open Pa_ppx_utils
open Pa_ppx_located_yojson
open Exec
module M = Mimick

let sim1 j = match j with
    M.PredictionContext_ENTER_merge (pc1, pc2, rootIsWildcard, mc_opt) ->
    let pc1 = PC.of_mimick pc1 in
    let pc2 = PC.of_mimick pc2 in
    let mc_opt = Option.map PC.MC.of_mimick mc_opt in
    let pc3 = PC.merge pc1 pc2 rootIsWildcard mc_opt in
    ()
