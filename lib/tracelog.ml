(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.utils,pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.yojson,pa_ppx.deriving_plugins.located_yojson,pa_ppx.import *)

open Pa_ppx_located_yojson
module M = Mimick

let _enabled = ref false
let _oc = ref stdout

let enabled () = !_enabled
let oc() = !_oc

let write jlog =
  if enabled() then
    let j = [%to_located_yojson: M.json_log_t] jlog in
    Json.pp_hum_to_channel ~std:true (oc()) j

let writemsg txt =
  if enabled() then
  let j = (Ploc.dummy, `List [(Ploc.dummy, `String txt)]) in
    Json.pp_hum_to_channel ~std:true (oc()) j

