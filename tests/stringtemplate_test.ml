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
  ; assert_equal () (ignore (Pa.Template.load ~file:"fixtures/antlrtest.7/Makefile"))
  ; assert_equal () (ignore (Pa.Template.load ~file:"fixtures/antlrtest.7/Test.py"))
  ; assert_equal () (ignore (Pa.Template.load ~file:"fixtures/antlrtest.7/TestLexer.py"))

let test_parse_file file ctxt =
  let open Stringtemplate in
  ()
  ; assert_equal () (ignore (Pa.Template.load ~file))

let test_parse_all_grammars () =
  let g4list =
    [Fpath.v "_generated"]
    |> Bos.OS.Path.fold (fun a b -> a::b) []
    |> Result.get_ok
    |> List.filter (Fpath.has_ext "g4")
  in
 let tests =
   g4list |>
     List.map (fun f ->
         let f = Fpath.to_string f in
         f >:: (test_parse_file f))
 in
 tests

let parse_fixed_files = 
  "parse fixed files" >:::
    ([
        "fixtures/antlrtest.7/Makefile"
      ; "fixtures/antlrtest.7/Test.py"
      ; "fixtures/antlrtest.7/TestLexer.py"
      ] |> List.map (fun f -> (f >:: test_parse_file f)))

let suite = "Test Stringtemplate" >::: [
      "parse st"   >:: test_parse_st
    ; "parse fixed files" >: parse_fixed_files
(*
    ; "parse grammars" >::: (test_parse_all_grammars())
 *)
    ]

let _ = 
if not !Sys.interactive then
  run_test_tt_main suite
else ()

