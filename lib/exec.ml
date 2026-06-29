(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.utils,pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.yojson,pa_ppx.deriving_plugins.located_yojson,pa_ppx.import *)

open Util
open Atn

module M = Mimick

type prediction_context_t = unit
type semantic_context_t = unit

type config_t = {
    state : M.deser_state_id
  ; alt : int
  ; context : prediction_context_t option
  ; semanticContext : semantic_context_t
  ; reachesIntoOuterContext : int
  ; precedenceFilterSuppressed : bool
  }
