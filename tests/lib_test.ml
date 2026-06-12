(**pp -syntax camlp5o *)

open OUnit2


let test_range ctxt =
  let open Antlr.Range in
  assert_equal (mk 0) (must_merge (mk 0) (mk 0))
  ; assert_equal (mk 0) (must_merge (mk 0) (mk 0))
  ; assert_equal (mk ~start:0 10) (must_merge (mk ~start:0 5) (mk ~start:5 10))
  ; assert_equal (mk ~start:0 10) (must_merge (mk ~start:0 6) (mk ~start:5 10))
  ; assert_equal (mk ~start:0 10) (must_merge (mk ~start:5 10) (mk ~start:0 6))


let test_interval_set ctxt = ()

let suite = "Test library" >::: [
      "range"   >:: test_range
    ; "interval set"   >:: test_interval_set
    ]

let _ = 
if not !Sys.interactive then
  run_test_tt_main suite
else ()

