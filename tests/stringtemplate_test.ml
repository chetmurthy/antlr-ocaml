(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.deriving_plugins.std *)

open OUnit2
open Antlr
open Antlrtest

Pa_ppx_runtime.Exceptions.Ploc.pp_loc_verbose := true ;;

let caches = Simulate.Caches.mk () ;;
Exec.file_init ~dfast_cache:caches.dfast ~acs_cache:caches.acs ~ac_cache:caches.ac () ;;

let test_parse_st ctxt =
  let open Stringtemplate in
  ()
  ; assert_equal () (ignore({|abc def|} |> Pa.Template.of_string))
  ; assert_equal () (ignore({|{<writeln("\"I\"")>}|} |> Pa.Template.of_string))
  ; assert_equal () (ignore({|{<name>}|} |> Pa.Template.of_string))
  ; assert_equal () (ignore ({|{<ToStringTree("$ctx"):writeln()>}|} |> Pa.Template.of_string))

let suite = "Test Stringtemplate" >::: [
      "parse st"   >:: test_parse_st
    ]

let _ = 
if not !Sys.interactive then
  run_test_tt_main suite
else ()

