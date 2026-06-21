(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.deriving_plugins.std *)

open OUnit2
open Antlrtest

let test_template ctxt =
  let module T = Stg.Template in
  let open Stg in
  let printer = show_stg_t_list in
  ()
  ; assert_equal ~printer [TEXT {|\<|}] (T.pa {|\<|})
  ; assert_equal ~printer [TEXT {| w \< l i > s |}] (T.pa {| w \< l i > s |})

let test_group ctxt =
  let module T = Stg.Template in
  let module G = Stg.Group in
  let printer = [%show: G.include_definition list] in
  ()
  ; assert_equal ~printer [G.{ name = "writeln"; formals=["s"]; rhs=T.pa "print(<s>, file=self._output)" }]
      (G.pa {|writeln(s) ::= <<print(<s>, file=self._output)>>|})
  ; assert_equal ~printer [G.{ name = "Not"; formals=["v"]; rhs=T.pa "not <v>" }]
      (G.pa {|Not(v) ::= "not <v>"|})
  ; assert_equal ~printer [G.{ name = "InitIntMember"; formals=["n";"v"]; rhs=T.pa "<n> = <v>" }]
      (G.pa {|InitIntMember(n,v) ::= <%<n> = <v>%>|})
  ; assert_equal ~printer [G.{ name = "P"; formals=[]; rhs=T.pa {| w \< l i > s |} }]
      (G.pa {|P() ::= << w \< l i > s >>|})

let suite = "Test Antlrtest" >::: [
      "template"   >:: test_template
    ; "group"   >:: test_group
    ]

let _ = 
if not !Sys.interactive then
  run_test_tt_main suite
else ()

