(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.deriving_plugins.std *)

open OUnit2
open Antlrtest

let test_template ctxt =
  let module T = Stg.Template in
  let open Stg in
  let printer = show_stg_t_list in
  ()
  ; assert_equal ~printer [TEXT {|<|}] (T.pa {|\<|})
  ; assert_equal ~printer [TEXT {| w < l i > s |}] (T.pa {| w \< l i > s |})
  ; assert_equal ~printer [TEXT "{"; INCLUDE ("writeln", [{|"\"S.A\""|}]); TEXT "}"]
      (T.pa {|{<writeln("\"S.A\"")>}|})
  ; assert_equal ~printer []
      (T.pa {|{<ToStringTree("$ctx"):writeln()>}|})

let test_group ctxt =
  let module T = Stg.Template in
  let module G = Stg.Group in
  let printer = [%show: G.include_definition list] in
  ()
  ; assert_equal ~printer ["writeln",G.{formals=["s"]; rhs=T.pa "print(<s>, file=self._output)" }]
      (G.pa {|writeln(s) ::= <<print(<s>, file=self._output)>>|})
  ; assert_equal ~printer ["Not",G.{formals=["v"]; rhs=T.pa "not <v>" }]
      (G.pa {|Not(v) ::= "not <v>"|})
  ; assert_equal ~printer ["InitIntMember",G.{formals=["n";"v"]; rhs=T.pa "<n> = <v>" }]
      (G.pa {|InitIntMember(n,v) ::= <%<n> = <v>%>|})
  ; assert_equal ~printer ["P",G.{formals=[]; rhs=T.pa {| w \< l i > s |} }]
      (G.pa {|P() ::= << w \< l i > s >>|})

let test_stg ctxt =
  let includes = Stg.Group.load (Fpath.v "fixtures/Python3.test.stg") in
  let env = Stg.Env.mt in
  let env = { (env) with includes = includes } in
  let trans ?(env=env) x = (Stg.transform ~file:"<none>" env x) in
  let printer x = x in
  ()
  ; assert_equal ~printer "x"  (trans {|x|})
  ; assert_equal ~printer "<" (trans {|\<|})
  ; assert_equal ~printer {|{print("S.A", file=self._output)}|} (trans {|{<writeln("\"S.A\"")>}|})
  ; assert_equal ~printer {|{print($label.y, file=self._output)}|} (trans {|{<writeln("$label.y")>}|})
  ; assert_equal ~printer {|{self.dumpDFA()}|} (trans {|{<DumpDFA()>}|})
  ; assert_equal ~printer {|{x = 0}|} (trans {|{<InitIntVar("x","0")>}|})
  ; assert_equal ~printer {|{$ctx.toStringTree(recog=self)}|} (trans {|{<ToStringTree("$ctx")>}|})
  ; assert_equal ~printer {|{print($ctx.toStringTree(recog=self), file=self._output)}|} (trans {|{<ToStringTree("$ctx"):writeln()>}|})
  ; assert_equal ~printer (trans {||}) {||}

let test_descriptor ctxt =
  let module D = Descriptor in
  let printer = [%show: [ `Delim of string * string | `Text of string ] list] in
  ()
  ; assert_equal ~printer [] (D.split_stanzas {||})
  ; assert_equal ~printer [`Delim ("type","")] (D.split_stanzas {|[type]|})
  ; assert_equal ~printer [`Delim ("notes","")] (D.split_stanzas {|[notes]|})
  ; assert_equal ~printer [`Delim ("input","")] (D.split_stanzas {|[input]|})
  ; assert_equal ~printer [`Delim ("input"," name=A type=B")] (D.split_stanzas {|[input name=A type=B]|})

let suite = "Test Antlrtest" >::: [
      "template"   >:: test_template
    ; "group"   >:: test_group
    ; "stg"   >:: test_stg
    ; "descriptor"   >:: test_descriptor
    ]

let _ = 
if not !Sys.interactive then
  run_test_tt_main suite
else ()

