(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.deriving_plugins.std,pa_ppx.here *)

open OUnit2
open Antlr
open Antlrtest

Pa_ppx_runtime.Exceptions.Ploc.pp_loc_verbose := true ;;

let caches = Simulate.Caches.mk () ;;
Exec.file_init ~dfast_cache:caches.dfast ~acs_cache:caches.acs ~ac_cache:caches.ac () ;;

module STPa = Stringtemplate.Pa.STG2_STPa
module STGPa = Stringtemplate.Pa.STG2_STGPa

let test_eval_simple ctxt =
  let open Stringtemplate in
  ()


let suite = "Test St4 evaluation" >::: [
      "eval simple"   >:: test_eval_simple
    ]

let _ = 
if not !Sys.interactive then
  run_test_tt_main suite
else ()

