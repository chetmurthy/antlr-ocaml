(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.deriving_plugins.std,pa_ppx.here *)

open OUnit2

open Pa_ppx_utils

open Antlr
open Antlrtest
open ST4.Api

Pa_ppx_runtime.Exceptions.Ploc.pp_loc_verbose := true ;;

let caches = Simulate.Caches.mk () ;;
Exec.file_init ~dfast_cache:caches.dfast ~acs_cache:caches.acs ~ac_cache:caches.ac () ;;

let stparse s = Template.of_string s
let steval env t = Template.Simple.eval env t

let test_eval_simple_1 ctxt =
  let printer x = Fmt.(str "%a" Dump.string x) in
  let env = [("name",["Foo"; "Bar"])] in
  ()
  ; assert_equal ~printer "Hello, FooBar!"
      (steval env
         (stparse {|<"Hello">, <name>!|}))
  ; assert_equal ~printer {|
  Hello, FooBar!
|}
      (steval env
         (stparse {|
  <"Hello">, <name>!
|}))


let test_eval_simple_2 ctxt =
  let printer x = Fmt.(str "%a" Dump.string x) in
  let env = [("name",["Foo"; "Bar"])] in
  ()
  ; assert_equal ~printer {|
  Hello, Foo
  Bar!
|}
      (steval env
         (stparse {|
  <"Hello">, <name; separator="\n">!
|}))



let suite = "Test St4 evaluation" >::: [
      "eval simple 1"   >:: test_eval_simple_1
    ; "eval simple 2"   >:: test_eval_simple_2
    ]

let _ = 
if not !Sys.interactive then
  run_test_tt_main suite
else ()

