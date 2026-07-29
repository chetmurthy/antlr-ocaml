(**pp -syntax camlp5o *)

open OUnit2

open Pa_ppx_utils
open Antlr
open Parse_antlrv4

Pa_ppx_runtime.Exceptions.Ploc.pp_loc_verbose := true ;;

let caches = Simulate.Caches.mk () ;;
Exec.file_init ~dfast_cache:caches.dfast ~acs_cache:caches.acs ~ac_cache:caches.ac () ;;

let simple_test ctxt = ()

let parse_grammars_test () =
  let g4list =
    [Fpath.v "_generated"]
    |> Bos.OS.Path.fold (fun a b -> a::b) []
    |> Result.get_ok
    |> List.filter (Fpath.has_ext "g4")
    |> List.map Fpath.to_string
 in
 let test_parse f ctxt =
   let _ = Pa.Grammar.load ~file:f in () in
 let tests =
   g4list |>
     List.map (fun f ->
         f >:: (test_parse f))
 in
 tests

let suite = "Test library" >::: [
      "simple"   >:: simple_test
    ; "parse grammars"   >::: (parse_grammars_test())
    ]

let _ = 
if not !Sys.interactive then
  run_test_tt_main suite
else ()

