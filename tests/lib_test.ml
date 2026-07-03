(**pp -syntax camlp5o *)

open OUnit2

open Pa_ppx_utils
open Antlr

let test_range ctxt =
  let open Range in
  let printer = show in
  assert_equal ~printer (mk 0) (must_merge (mk 0) (mk 0))
  ; assert_equal ~printer (mk 0) (must_merge (mk 0) (mk 0))
  ; assert_equal ~printer (mk ~start:0 10) (must_merge (mk ~start:0 5) (mk ~start:5 10))
  ; assert_equal ~printer (mk ~start:0 10) (must_merge (mk ~start:0 6) (mk ~start:5 10))
  ; assert_equal ~printer (mk ~start:0 10) (must_merge (mk ~start:5 10) (mk ~start:0 6))

let test_interval_set ctxt =
  let module R = Antlr.Range in
  let open Antlr.IntervalSet in
  let printer x = Fmt.(str "%a" dump x) in
  assert_equal ~printer
    (ofList [R.mk ~start:9 11; R.mk ~start:13 14])
    (() |> mk |> add (R.mk ~start:9 11) |> add (R.mk ~start:13 14))
  ; assert_equal ~printer
    (ofList [R.mk ~start:9 11; R.mk ~start:13 14])
    (() |> mk |> add (R.mk ~start:13 14) |> add (R.mk ~start:9 11))
  ; ()

let test_entry_exit ctxt =
  let entry_exit_string ~ooe names = Util.entry_exit ~only_outermost_enter:ooe names (fun x -> Some x) in
  let eelist  ?(ooe=false) names l = l |> Stream.of_list |> entry_exit_string ~ooe names |> Std.list_of_stream in
  let printer l = Fmt.(str "[%a]" (list ~sep:(const string "; ") Dump.string) l) in
  ()
  ; assert_equal ~printer [] (eelist ["x"] ["y"])
  ; assert_equal ~printer ["ENTER x"; "y"; "EXIT x"] (eelist ["x"] ["x"; "ENTER x"; "y"; "EXIT x"])
  ; assert_equal ~printer ["ENTER x"; "y"; "EXIT x"] (eelist ["x"] ["x"; "ENTER x"; "y"; "EXIT x"; "z"])
  ; assert_equal ~printer ["ENTER x"; "a"; "ENTER y"; "b"; "EXIT y"; "c"; "EXIT x"]
      (eelist ["x"; "y"] ["x"; "ENTER x"; "a"; "ENTER y"; "b"; "EXIT y"; "c"; "EXIT x"; "z"])
  ; assert_equal ~printer ["ENTER x"; "ENTER x"]
      (eelist ~ooe:true ["x"; "y"] ["x"; "ENTER x"; "a"; "ENTER y"; "b"; "EXIT y"; "c"; "EXIT x"; "z"; "ENTER x"; "a"; "EXIT x"])

let suite = "Test library" >::: [
      "range"   >:: test_range
    ; "interval set"   >:: test_interval_set
    ; "entry/exit"   >:: test_entry_exit
    ]

let _ = 
if not !Sys.interactive then
  run_test_tt_main suite
else ()

