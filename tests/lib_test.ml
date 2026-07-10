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
  let entry_exit_string ?start_nth ?stop_nth ~ooe names =
    Util.entry_exit ?start_nth ?stop_nth ~only_outermost_enter:ooe names (fun x -> Some x) in
  let eelist ?start_nth ?stop_nth ?(ooe=false) names l =
    l
    |> Stream.of_list
    |> entry_exit_string ?start_nth ?stop_nth ~ooe names
    |> Std.list_of_stream in
  let printer l = Fmt.(str "[%a]" (list ~sep:(const string "; ") Dump.string) l) in
  ()
  ; assert_equal ~printer [] (eelist ["x"] ["y"])
  ; assert_equal ~printer ["ENTER x"; "y"; "EXIT x"] (eelist ["x"] ["x"; "ENTER x"; "y"; "EXIT x"])
  ; assert_equal ~printer ["ENTER x"; "y"; "EXIT x"] (eelist ["x"] ["x"; "ENTER x"; "y"; "EXIT x"; "z"])
  ; assert_equal ~printer ["ENTER x"; "a"; "ENTER y"; "b"; "EXIT y"; "c"; "EXIT x"]
      (eelist ["x"; "y"]
         ["x"
         ; "ENTER x"; "a"; "ENTER y"; "b"; "EXIT y"; "c"; "EXIT x"
         ; "z"])
  ; assert_equal ~printer
      ["ENTER x"; "a"; "ENTER y"; "b"; "EXIT y"; "c"; "EXIT x"
       ; "ENTER x"; "a"; "EXIT x"]
      (eelist ["x"; "y"]
         ["x"
         ; "ENTER x"; "a"; "ENTER y"; "b"; "EXIT y"; "c"; "EXIT x"
         ; "z"
         ; "ENTER x"; "a"; "EXIT x"])
  ; assert_equal ~printer ["ENTER x"; "ENTER x"]
      (eelist ~ooe:true ["x"; "y"]
         ["x"
         ; "ENTER x"; "a"; "ENTER y"; "b"; "EXIT y"; "c"; "EXIT x"
         ; "z"
         ; "ENTER x"; "a"; "EXIT x"])
  ; assert_equal ~printer ["ENTER x"; "ENTER x"]
      (eelist ~ooe:true ["x"; "y"]
         ["x"
         ; "ENTER x"; "a"; "ENTER y"; "b"; "EXIT y"; "c"; "EXIT x"
         ; "z"
         ; "ENTER x"; "a"])
  ; assert_equal ~printer
      ["ENTER x"; "a"; "ENTER y"; "b"; "EXIT y"; "c"; "EXIT x"
       ; "ENTER x"; "a"]
      (eelist ["x"; "y"]
         ["x"
         ; "ENTER x"; "a"; "ENTER y"; "b"; "EXIT y"; "c"; "EXIT x"
         ; "z"
         ; "ENTER x"; "a"])
  ; assert_equal ~printer
      ["ENTER x"; "a"; "ENTER y"; "b"; "EXIT y"; "c"; "EXIT x"]
      (eelist ~start_nth:0 ["x"; "y"]
         ["x"
         ; "ENTER x"; "a"; "ENTER y"; "b"; "EXIT y"; "c"; "EXIT x"
         ; "z"
         ; "ENTER x"; "a"; "EXIT x"])
  ; assert_equal ~printer
      ["ENTER x"; "a"; "EXIT x"]
      (eelist ~start_nth:1 ["x"; "y"]
         ["x"
         ; "ENTER x"; "a"; "ENTER y"; "b"; "EXIT y"; "c"; "EXIT x"
         ; "z"
         ; "ENTER x"; "a"; "EXIT x"])
  ; assert_equal ~printer
      ["ENTER y"; "a"; "EXIT y"]
      (eelist ~start_nth:1 ["x"; "y"]
         ["x"
         ; "ENTER x"; "a"; "ENTER z"; "b"; "EXIT z"; "c"; "EXIT x"
         ; "z"
         ; "ENTER y"; "a"; "EXIT y"])
  ; assert_equal ~printer
      ["ENTER y"]
      (eelist ~ooe:true ~start_nth:1 ["x"; "y"]
         ["x"
         ; "ENTER x"; "a"; "ENTER z"; "b"; "EXIT z"; "c"; "EXIT x"
         ; "z"
         ; "ENTER y"; "a"; "EXIT y"])
  ; assert_equal ~printer
      []
      (eelist ~start_nth:2 ["x"; "y"]
         ["x"
         ; "ENTER x"; "a"; "ENTER y"; "b"; "EXIT y"; "c"; "EXIT x"
         ; "z"
         ; "ENTER x"; "a"; "EXIT x"])
  ; assert_equal ~printer
      []
      (eelist ~start_nth:(-1) ["x"; "y"]
         ["x"
         ; "ENTER x"; "a"; "ENTER y"; "b"; "EXIT y"; "c"; "EXIT x"
         ; "z"
         ; "ENTER x"; "a"; "EXIT x"])
  ; assert_equal ~printer
      ["ENTER x"; "a2"; "EXIT x"; "ENTER x"; "a3"; "EXIT x"]
      (eelist ~start_nth:2 ~stop_nth:4 ["x"; "y"]
         ["x"
         ; "ENTER x"; "a0"; "EXIT x"
         ; "z"
         ; "ENTER x"; "a1"; "EXIT x"
         ; "z"
         ; "ENTER x"; "a2"; "EXIT x"
         ; "z"
         ; "ENTER x"; "a3"; "EXIT x"
         ; "z"
         ; "ENTER x"; "a4"; "EXIT x"
         ; "z"
         ; "ENTER x"; "a5"; "EXIT x"
      ])
  ; assert_equal ~printer
      ["ENTER x"; "a0"; "EXIT x"; "ENTER x"; "a1"; "EXIT x"]
      (eelist ~stop_nth:2 ["x"; "y"]
         ["x"
         ; "ENTER x"; "a0"; "EXIT x"
         ; "z"
         ; "ENTER x"; "a1"; "EXIT x"
         ; "z"
         ; "ENTER x"; "a2"; "EXIT x"
         ; "z"
         ; "ENTER x"; "a3"; "EXIT x"
         ; "z"
         ; "ENTER x"; "a4"; "EXIT x"
         ; "z"
         ; "ENTER x"; "a5"; "EXIT x"
      ])


let suite = "Test library" >::: [
      "range"   >:: test_range
    ; "interval set"   >:: test_interval_set
    ; "entry/exit"   >:: test_entry_exit
    ]

let _ = 
if not !Sys.interactive then
  run_test_tt_main suite
else ()

