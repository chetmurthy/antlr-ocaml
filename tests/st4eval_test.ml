(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.deriving_plugins.std,pa_ppx.here *)

open OUnit2

open Pa_ppx_utils

open Antlr
open Antlrtest
open Stringtemplate
open Eval

Pa_ppx_runtime.Exceptions.Ploc.pp_loc_verbose := true ;;

let caches = Simulate.Caches.mk () ;;
Exec.file_init ~dfast_cache:caches.dfast ~acs_cache:caches.acs ~ac_cache:caches.ac () ;;

module STPa = Stringtemplate.Pa.STG2_STPa
module STGPa = Stringtemplate.Pa.STG2_STGPa

let stparse s =
  let t =
    s
    |> STPa.Template.of_string
    |> St_ops.coalesce
    |> St_ops.insert_indentation
  in
  assert (St_ops.balanced_indentation t) ;
  t

let steval env t =
  let open Doit in
  let ctxt = Context.mk() in
  (t
   |> eval_elements ctxt env Indent.mt
   |> render_attr_value) ()
  |> FIW.render_stream
  |> Std.list_of_stream
  |> String.concat ""

let test_eval_simple ctxt =
  let open Stringtemplate in
  let printer x = Fmt.(str "%a" Dump.string x) in
  ()
  ; assert_equal ~printer "Hello, FooBar!"
      (steval [["name",MV [STRING "Foo"; STRING "Bar"]]]
         (stparse {|<"Hello">, <name>!|}))
  ; assert_equal ~printer {|
  Hello, FooBar!
|}
      (steval [["name",MV [STRING "Foo"; STRING "Bar"]]]
         (stparse {|
  <"Hello">, <name>!
|}))
  ; assert_equal ~printer {|
  Hello, Foo
  Bar!
|}
      (steval [["name",MV [STRING "Foo"; STRING "Bar"]]]
         (stparse {|
  <"Hello">, <name; separator="\n">!
|}))



let suite = "Test St4 evaluation" >::: [
      "eval simple"   >:: test_eval_simple
    ]

let _ = 
if not !Sys.interactive then
  run_test_tt_main suite
else ()

