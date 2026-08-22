(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.deriving_plugins.std,pa_ppx.here *)

open OUnit2

open Pa_ppx_utils

open Antlr
open Antlrtest
open ST4
open Sttypes2
open Eval

Pa_ppx_runtime.Exceptions.Ploc.pp_loc_verbose := true ;;

let caches = Simulate.Caches.mk () ;;
Exec.file_init ~dfast_cache:caches.dfast ~acs_cache:caches.acs ~ac_cache:caches.ac () ;;

module STPa = ST4.Pa.STG2_STPa
module STGPa = ST4.Pa.STG2_STGPa

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
  let group = Eval.Group.mk () in
  let ctxt = Context.mk group in
  (t
   |> eval_elements ctxt env Indent.mt
   |> render_attr_value) ()
  |> FIW.render_stream
  |> Std.list_of_stream
  |> String.concat ""

let test_environ ctxt =
  let open ST4 in
  let open Pa_ppx_located_sexp in
  assert_equal ~printer:Environ.show_attr_val_t
    (Environ.MEXPR ([%here_string "#inside x"]
     |> STPa.Mexpr.of_here_string))
    ({| (MEXPR "x") |}
     |> Sexp.of_string 
     |> Environ.attr_val_t_of_located_sexp)

let test_eval_simple ctxt =
  let open ST4 in
  let printer x = Fmt.(str "%a" Dump.string x) in
  let env = Environ.[
        [
          ("name",MV [STRING "Foo"; STRING "Bar"])
        ; ("x", MEXPR ([%here_string "#inside name"] |> STPa.Mexpr.of_here_string))
        ]
            ] in
  ()
  ; assert_equal ~printer "Hello, FooBar!"
      (steval env
         (stparse {|<"Hello">, <name>!|}))
  ; assert_equal ~printer "Hello, FooBar!"
      (steval env
         (stparse {|<"Hello">, <x>!|}))
  ; assert_equal ~printer {|
  Hello, FooBar!
|}
      (steval env
         (stparse {|
  <"Hello">, <name>!
|}))
  ; assert_equal ~printer {|
  Hello, Foo
  Bar!
|}
      (steval env
         (stparse {|
  <"Hello">, <name; separator="\n">!
|}))



let suite = "Test St4 evaluation" >::: [
      "environ"   >:: test_environ
    ; "eval simple"   >:: test_eval_simple
    ]

let _ = 
if not !Sys.interactive then
  run_test_tt_main suite
else ()

