(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.deriving_plugins.std *)

open OUnit2

open Pa_ppx_base
open Ppxutil
open Pa_ppx_utils
open Coll
open Antlr
open Parse_antlrv4

Pa_ppx_runtime.Exceptions.Ploc.pp_loc_verbose := true ;;

let caches = Simulate.Caches.mk () ;;
Exec.file_init ~dfast_cache:caches.dfast ~acs_cache:caches.acs ~ac_cache:caches.ac () ;;

let file_contents fname =
  fname |> Bos.OS.File.read |> Rresult.R.get_ok

let onlyDelim = function `Delim x -> Some x | _ -> None

let rec group_chunks chunks =
  match chunks with
    `Delim action :: `Text txt :: l ->
    (action, txt)::(group_chunks l)
  | `Text _ :: l -> group_chunks l
  | `Delim action1 :: `Delim action2 :: _ -> Fmt.(failwithf "group_chunks: two Delim without intervening text %s, %s" action1 action2)
  | `Delim action :: [] -> Fmt.(failwithf "group_chunks: trailing Delim %s" action)
  | [] -> []

let full ~kind ~read_ruleIndex ~read_individuals fname =
  let name2ruleIndex = read_ruleIndex fname in
  let name2actionIndexes = read_individuals fname in
  let name_repeats = Std2.hash_list_repeats (List.map fst name2ruleIndex) in
  if [] <> name_repeats then
    Fmt.(failwithf "Sempred.full: file %a has repeated %ss: %a@."
           Fpath.pp fname
           kind
           (list ~sep:(const string " ") string) name_repeats) ;
  let l1 = List.stable_sort Stdlib.compare (List.map fst name2ruleIndex) in
  let l2 = List.stable_sort Stdlib.compare (List.map fst name2actionIndexes) in
  if l1 <> l2 then
    Fmt.(failwithf "full: file %a different name2ruleIndex vs name2%sIndexes: %a <> %a@."
           Fpath.pp fname
           kind
           (brackets (list ~sep:(const string " ") string)) l1
           (brackets (list ~sep:(const string " ") string)) l2
    ) ;
  let name2ruleIndex = MHM.ofList 23 name2ruleIndex in
  name2actionIndexes
  |> List.concat_map
       (fun (name,l) ->
         let ruleIndex = MHM.map name2ruleIndex name in
         List.map (fun actionIndex -> ((name, ruleIndex), actionIndex)) l)


module Sempred = struct

let read_sempred_ruleIndex fname =
  fname
  |>  file_contents
  |> [%split {|preds\[(\d+)\] = self\.(\S+)_sempred|} / strings (!1,!2) ]
  |> List.filter_map onlyDelim
  |> List.map (fun (index,name) -> (name,int_of_string index))

let sempred_indexes txt =
  txt
  |> [%split {|predIndex == (\d+)|} / strings !1]
  |> List.filter_map onlyDelim
  |> List.map int_of_string

let chunks2sempredIndexes chunks =
  let grouped = group_chunks chunks in
  List.map (fun (sempred, txt) -> (sempred, sempred_indexes txt)) grouped

let read_sempreds fname =
    fname
    |>  file_contents
    |> [%split {|def (\S+?)_sempred|} / strings !1]
    |> chunks2sempredIndexes

let full fname =
  full ~kind:"sempred" ~read_ruleIndex:read_sempred_ruleIndex ~read_individuals:read_sempreds fname
end

module Action = struct
let read_action_ruleIndex fname =
  fname
  |>  file_contents
  |> [%split {|actions\[(\d+)\] = self\.(\S+)_action|} / strings (!1,!2) ]
  |> List.filter_map onlyDelim
  |> List.map (fun (index,name) -> (name,int_of_string index))

let action_indexes txt =
  txt
  |> [%split {|actionIndex == (\d+)|} / strings !1]
  |> List.filter_map onlyDelim
  |> List.map int_of_string

let chunks2actionIndexes chunks =
  let grouped = group_chunks chunks in
  List.map (fun (action, txt) -> (action, action_indexes txt)) grouped

let read_actions fname =
    fname
    |>  file_contents
    |> [%split {|def (\S+?)_action|} / strings !1]
    |> chunks2actionIndexes

let full fname =
  full ~kind:"action" ~read_ruleIndex:read_action_ruleIndex ~read_individuals:read_actions fname
end

let test_actions_sempreds ~path gramfile ctxt =
  let g =
    gramfile
    |> Fpath.to_string
    |> (fun file -> Pa.Grammar.load ~file)
    |> (Grammar_tools.load_imports ~path) in

  let grammar_actions =
    g
    |> Grammar_tools.grammar_actions
    |> List.map (fun (lab,(n,_)) -> (lab,n))
  in
  let grammar_sempreds =
    g
    |> Grammar_tools.grammar_sempreds
    |> List.map (fun (lab,(n,_)) -> (lab,n))
  in
  let pyfile = Fpath.(set_ext "py" gramfile) in
  let py_actions = Action.full pyfile in
  let py_sempreds = Sempred.full pyfile in
  let printer = [%show: ((string * int) * int) list] in
  ()
  ; assert_equal ~printer grammar_actions py_actions
  ; assert_equal ~printer grammar_sempreds py_sempreds

let test_all_grammars_actions_sempreds () =
  let path = [Fpath.v "fixtures/grammar-lib"] in
  let g4list =
    [Fpath.v "_generated"]
    |> Bos.OS.Path.fold (fun a b -> a::b) []
    |> Result.get_ok
    |> List.filter (Fpath.has_ext "g4")
    |> List.filter (fun p -> p |> Fpath.set_ext "py" |> Bos.OS.File.exists |> Rresult.R.get_ok)
  in
 let tests =
   g4list |>
     List.map (fun f ->
         (Fpath.to_string f) >:: (test_actions_sempreds ~path f))
 in
 tests

let suite = "Test Grammar tools" >::: [
      "simple"   >::: (test_all_grammars_actions_sempreds())
    ]

let _ = 
if not !Sys.interactive then
  run_test_tt_main suite
else ()

