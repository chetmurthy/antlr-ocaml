(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.utils,pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.yojson,pa_ppx.deriving_plugins.located_yojson,pa_ppx.import *)

open OUnit2
open Pa_ppx_utils

open Antlr
open Mimick
open Pa_ppx_located_yojson

let test_deserialize deserializer txt =
  txt
  |> Pa_json.JsonEOI.of_string
  |> deserializer
  |> Json.raise_failwith_error_msg

let test_dfa ctxt =
  test_deserialize dfa_t_of_located_yojson
{|
    {
        "_states": {},
        "atnStartState": 0,
        "decision": 0,
        "grammarType": [
            "LEXER"
        ],
        "id": 0,
        "precedenceDfa": false,
        "s0": null
    }
|}
; ()

let suite = "Test Mimick" >::: [
      "dfa"   >:: test_dfa
    ]

let _ = 
if not !Sys.interactive then
  run_test_tt_main suite
else ()

