(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.deriving_plugins.std,pa_ppx.here *)

open OUnit2

open Pa_ppx_utils

open Antlr
open Antlrtest
open Stringtemplate
open Camlp5_adapter

Pa_ppx_runtime.Exceptions.Ploc.pp_loc_verbose := true ;;

let caches = Simulate.Caches.mk () ;;
Exec.file_init ~dfast_cache:caches.dfast ~acs_cache:caches.acs ~ac_cache:caches.ac () ;;



let check_triple_pair i a b =
  let open Exec.T in
  let open St_util in
  let raw_a = triple2raw a in
  let raw_b = triple2raw b in
  let msg = Fmt.(str "check_triple_pair: mismatched raw start/end.@.a: %a@. b: %a@."
                   pp_triple a
                   pp_triple b
                ) in
  assert_equal ~msg ((Std.outSome raw_a.stop) + 1) (Std.outSome raw_b.start)

let check_pairs_i f l =
  let rec checkrec i l =
    match l with
      [] | [_] -> ()
      | h::t::l ->
         f i h t ;
         checkrec (i+1) (t::l)
  in checkrec 0 l

let check_locations triples =
  if triples = [] then failwith "check_locations: no tokens" ;
  check_pairs_i check_triple_pair triples

let test_raw_tokens ctxt =
  "< writeln()>" |> ST.triple_of_string ~all_channels:true |>  Std.list_of_stream |> check_locations
  ; {| import "foo" |} |> STG.triple_of_string ~all_channels:true |>  Std.list_of_stream |> check_locations

let test_pa_st2 ctxt =
  ()
  ; assert_equal () (ignore([%here_string {|abc def|}] |> ST.located_patterns_of_here_string |> Std.list_of_stream))

let test_pa_stg ctxt =
  ()
  ; assert_equal () (ignore([%here_string {| import "foo" |}] |> STG.located_patterns_of_here_string |> Std.list_of_stream))

let suite = "Test location handling" >::: [
      "raw tokens"   >:: test_raw_tokens
    ; "parse st2"   >:: test_pa_st2
    ]

let _ = 
if not !Sys.interactive then
  run_test_tt_main suite
else ()

