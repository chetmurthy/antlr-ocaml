(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.deriving_plugins.std,pa_ppx.here *)

open OUnit2
open Antlr
open Antlrtest

Pa_ppx_runtime.Exceptions.Ploc.pp_loc_verbose := true ;;

let caches = Simulate.Caches.mk () ;;
Exec.file_init ~dfast_cache:caches.dfast ~acs_cache:caches.acs ~ac_cache:caches.ac () ;;

module STPa = ST4.Pa.STG2_STPa
(*
module STGPa = ST4.Pa_stg
 *)
module STGPa = ST4.Pa.STG2_STGPa

let test_parse_st ctxt =
  let open ST4 in
  ()
  ; assert_equal () (ignore([%here_string {|abc def|}] |> STPa.Template.of_here_string))
  ; assert_equal () (ignore([%here_string {|Hello, <name>!|}] |> STPa.Template.of_here_string))
  ; assert_equal () (ignore([%here_string {|{<writeln("\"I\"")>}|}] |> STPa.Template.of_here_string))
  ; assert_equal () (ignore([%here_string {|{<name>}|}] |> STPa.Template.of_here_string))
  ; assert_equal () (ignore ([%here_string {|{<ToStringTree("$ctx"):writeln()>}|}] |> STPa.Template.of_here_string))
  ; assert_equal () (ignore ([%here_string {|{<InitIntMember("i","0")>}|}] |> STPa.Template.of_here_string))
  ; assert_equal () (ignore ([%here_string {|{<LANotEquals("2",{T<ParserToken("Parser", "NL")>})>}|}] |> STPa.Template.of_here_string))
  ; assert_equal () (ignore ([%here_string {|<TreeNodeWithAltNumField(X="T")>|}] |> STPa.Template.of_here_string))
  ; assert_equal () (ignore ([%here_string "load <box({})>;"] |> STPa.Template.of_here_string))
  ; assert_equal () (ignore ([%here_string {|<a(x="x",y="y")>|}] |> STPa.Template.of_here_string))
  ; assert_equal () (ignore ([%here_string "Foo<\\ >bar<\\n>"] |> STPa.Template.of_here_string))
  ; assert_equal () (ignore ([%here_string "<subdir/b()>"] |> STPa.Template.of_here_string))
  ; assert_equal () (ignore ([%here_string {|<{<x>}>|}] |> STPa.Template.of_here_string))
  ; assert_equal () (ignore ([%here_string {|<{<x:{s|<s><s>}>}>|}] |> STPa.Template.of_here_string))
  ; assert_equal () (ignore ([%here_string {|<b(...)>|}] |> STPa.Template.of_here_string))

  ; assert_equal () (ignore (STPa.Template.load ~file:"fixtures/antlrtest.7/Makefile"))
  ; assert_equal () (ignore (STPa.Template.load ~file:"fixtures/antlrtest.7/Test.py"))
  ; assert_equal () (ignore (STPa.Template.load ~file:"fixtures/antlrtest.7/TestLexer.py"))

let test_parse_grammar g ctxt =
  let open ST4 in
  let module D = Descriptor in
  ignore(STPa.Template.of_string ~startloc:g.D.loc g.D.txt)

let test_parse_descriptor file ctxt =
  let open ST4 in
  let module D = Descriptor in
  let testname = [%match {|([^/]+/[^/]+)\.txt$|} / pcre2 strings !1 exc] file in
  let d = D.load ~testname file in
  (test_parse_grammar d.grammar) ()

let list_all_descriptors () =
  [
    "fixtures/descriptors"
  ; "fixtures/custom-descriptors"
  ; "/home/chet/Hack/Antlr/src/antlr4/runtime-testsuite/resources/org/antlr/v4/test/runtime/descriptors"
  ]
  |> List.map Fpath.v
  |> Bos.OS.Path.fold (fun a b -> a::b) []
  |> Result.get_ok
  |> List.filter (Fpath.has_ext "txt")
  |> List.map Fpath.to_string

let test_parse_all_descriptors ctxt =
  (list_all_descriptors())
  |> List.iter (fun f ->
         test_parse_descriptor f ())

let test_parse_st_file file ctxt =
  ()
  ; assert_equal () (ignore (STPa.Template.load ~file))

let parse_fixed_files = 
  [
    "fixtures/antlrtest.7/Makefile"
  ; "fixtures/antlrtest.7/Test.py"
  ; "fixtures/antlrtest.7/TestLexer.py"
  ]
  |> List.map (fun f -> (f >:: test_parse_st_file f))

let test_parse_stg ctxt =
  let open ST4 in
  ()
  ; assert_equal () (ignore([%here_string {| import "foo" |}] |> STGPa.Group.of_here_string))
  ; assert_equal () (ignore([%here_string {| 
cppTypeInitMap ::= [
    "int":"0",
    "long":"0",
    "float":"0.0f",
    "double":"0.0",
    "bool":"false",
    "short":"0",
    "char":"0",
    default: "nullptr" // anything other than a primitive type is an object
]

 |}] |> STGPa.Group.of_here_string))
  ; assert_equal () (ignore([%here_string {| 
stat(name,value="99") ::= "x=<value>; // <name>"
|}] |> STGPa.Group.of_here_string))
  ; assert_equal () (ignore([%here_string {| 
stat(name,value={<x>}) ::= "x=<value>; // <name>"
|}] |> STGPa.Group.of_here_string))

let test_load_stg ctxt =
  let open ST4 in
  let here_filecache = [
      ("foo.st",[%here_string {|foo() ::= "foo"|}])
    ] in
  ()
  ; assert_equal () (ignore([%here_string {| import "foo.st" |}]
                            |> Eval.Group.of_here_string ~stg:true ~here_filecache))
  ; assert_equal () (ignore([%here_string {| 
cppTypeInitMap ::= [
    "int":"0",
    "long":"0",
    "float":"0.0f",
    "double":"0.0",
    "bool":"false",
    "short":"0",
    "char":"0",
    default: "nullptr" // anything other than a primitive type is an object
]

 |}] |> STGPa.Group.of_here_string))
  ; assert_equal () (ignore([%here_string {| 
stat(name,value="99") ::= "x=<value>; // <name>"
|}] |> STGPa.Group.of_here_string))
  ; assert_equal () (ignore([%here_string {| 
stat(name,value={<x>}) ::= "x=<value>; // <name>"
|}] |> STGPa.Group.of_here_string))

let list_all_stg () =
  [
    "/home/chet/Hack/Antlr/src/antlr4/runtime-testsuite/resources/org/antlr/v4/test/runtime/templates"
  ; "/home/chet/Hack/Antlr/src/antlr4/tool/resources/org/antlr/v4/tool/templates/codegen"
  ; "/home/chet/Hack/Antlr/src/antlr4/tool/resources/org/antlr/v4/tool/templates"
  ; "/home/chet/Hack/Github/antlr/stringtemplate4/"
  ; "fixtures"
  ]
  |> List.map Fpath.v
  |> Bos.OS.Path.fold (fun a b -> a::b) []
  |> Result.get_ok
  |> List.filter (Fpath.has_ext "stg")
  |> List.map Fpath.to_string

let test_parse_stg_file file ctxt =
  let open ST4 in
  ()
  ; assert_equal () (ignore (STGPa.Group.load ~file))

let test_parse_all_stg ctxt =
  (list_all_stg())
  |>
    List.iter (fun f ->
        (test_parse_stg_file f ()))

let suite = "Test Stringtemplate" >::: [
      "parse st"   >:: test_parse_st
    ; "parse stg"   >:: test_parse_stg
    ; "load stg"   >:: test_load_stg
    ; "parse fixed files" >::: parse_fixed_files
    ; "parse descriptors" >:: test_parse_all_descriptors
    ; "parse stg files" >:: test_parse_all_stg
    ]

let _ = 
if not !Sys.interactive then
  run_test_tt_main suite
else ()

