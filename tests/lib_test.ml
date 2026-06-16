(**pp -syntax camlp5o *)

open OUnit2
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

let suite = "Test library" >::: [
      "range"   >:: test_range
    ; "interval set"   >:: test_interval_set
    ]

let _ = 
if not !Sys.interactive then
  run_test_tt_main suite
else ()

