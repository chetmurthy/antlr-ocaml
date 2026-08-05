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
  ; assert_equal () (ignore({|abc def|} |> Pa_st.Template.of_string))
  ; assert_equal () (ignore({|Hello, <name>!|} |> Pa_st.Template.of_string))
  ; assert_equal () (ignore({|{<writeln("\"I\"")>}|} |> Pa_st.Template.of_string))
  ; assert_equal () (ignore({|{<name>}|} |> Pa_st.Template.of_string))
  ; assert_equal () (ignore ({|{<ToStringTree("$ctx"):writeln()>}|} |> Pa_st.Template.of_string))
  ; assert_equal () (ignore ({|{<InitIntMember("i","0")>}|} |> Pa_st.Template.of_string))
  ; assert_equal () (ignore ({|{<LANotEquals("2",{T<ParserToken("Parser", "NL")>})>}|} |> Pa_st.Template.of_string))
  ; assert_equal () (ignore ({|<TreeNodeWithAltNumField(X="T")>|} |> Pa_st.Template.of_string))

  ; assert_equal () (ignore (Pa_st.Template.load ~file:"fixtures/antlrtest.7/Makefile"))
  ; assert_equal () (ignore (Pa_st.Template.load ~file:"fixtures/antlrtest.7/Test.py"))
  ; assert_equal () (ignore (Pa_st.Template.load ~file:"fixtures/antlrtest.7/TestLexer.py"))

let test_parse_stg ctxt =
  let open Stringtemplate in
  ()
  ; assert_equal () (ignore({| import "foo" |} |> Pa_stg.Group.of_string))
  ; assert_equal () (ignore({| 
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

 |} |> Pa_stg.Group.of_string))

let test_parse_grammar txt ctxt =
  let open Stringtemplate in
  ignore(Pa_st.Template.of_string txt)

let test_parse_descriptor file ctxt =
  let open Stringtemplate in
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
  |>
    List.iter (fun f ->
        Fmt.(pf stderr "[%s]@." f) ;
        (test_parse_descriptor f ()))

let test_parse_st_file file ctxt =
  let open Stringtemplate in
  ()
  ; assert_equal () (ignore (Pa_st.Template.load ~file))

let parse_fixed_files = 
  [
    "fixtures/antlrtest.7/Makefile"
  ; "fixtures/antlrtest.7/Test.py"
  ; "fixtures/antlrtest.7/TestLexer.py"
  ]
  |> List.map (fun f -> (f >:: test_parse_st_file f))


let list_all_stg () =
  [
    "/home/chet/Hack/Antlr/src/antlr4/runtime-testsuite/resources/org/antlr/v4/test/runtime/templates"
  ; "/home/chet/Hack/Antlr/src/antlr4/tool/resources/org/antlr/v4/tool/templates/codegen"
  ; "/home/chet/Hack/Antlr/src/antlr4/tool/resources/org/antlr/v4/tool/templates"
  ; "/home/chet/Hack/Github/antlr/stringtemplate4/"
  ]
  |> List.map Fpath.v
  |> Bos.OS.Path.fold (fun a b -> a::b) []
  |> Result.get_ok
  |> List.filter (Fpath.has_ext "stg")
  |> List.map Fpath.to_string

let test_parse_stg_file file ctxt =
  let open Stringtemplate in
  ()
  ; assert_equal () (ignore (Pa_stg.Group.load ~file))

let test_parse_all_stg ctxt =
  (list_all_stg())
  |>
    List.iter (fun f ->
        Fmt.(pf stderr "[%s]@." f) ;
        (test_parse_stg_file f ()))

let suite = "Test Stringtemplate" >::: [
      "parse st"   >:: test_parse_st
    ; "parse stg"   >:: test_parse_stg
    ; "parse fixed files" >::: parse_fixed_files
    ; "parse descriptors" >:: test_parse_all_descriptors
    ; "parse stg files" >:: test_parse_all_stg
    ]

let _ = 
if not !Sys.interactive then
  run_test_tt_main suite
else ()

