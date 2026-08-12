(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.deriving_plugins.std,pa_ppx.here *)

open OUnit2

open Pa_ppx_base
open Ppxutil
open Pa_ppx_utils

open Antlr
open Antlrtest
open Stringtemplate
open Camlp5_adapter

Pa_ppx_runtime.Exceptions.Ploc.pp_loc_verbose := true ;;

let caches = Simulate.Caches.mk () ;;
Exec.file_init ~dfast_cache:caches.dfast ~acs_cache:caches.acs ~ac_cache:caches.ac () ;;

module Bol_pos = struct

type maps = {
    txt : string
  ; txtlen : int
  ; linenum2bol_pos : (int * int) array
  ; bol_pos2linenum : (int * int) array
  }

let init txt =
  let lines = [%split "\n" / strings s] txt in
  let linenls =
    let rec nlrec acc = function
        [] -> List.rev acc
      | (`Text h)::(`Delim h2)::tl -> nlrec ((h^h2)::acc) tl
      | (`Delim h)::tl -> nlrec (h::acc) tl
      | [`Text h] -> List.rev (h::acc)
      | _ -> Fmt.(failwithf "compute_bol_pos: Internal error: split failed %a" Dump.string txt) in
    nlrec [] lines in
  let (bol_pos_lines,_) =
    Util.foldmap_left (fun bol_pos line ->
        let new_bol_pos = bol_pos + String.length line in
        ((bol_pos, line), new_bol_pos)) 0 linenls in
  let linenum2bol_pos =
    List.mapi (fun i (bol_pos,_) -> (i+1, bol_pos)) bol_pos_lines in
  let bol_pos2linenum = List.map (fun (a,b) -> (b,a)) linenum2bol_pos in
  {
    txt
  ; txtlen = String.length txt
  ; linenum2bol_pos = Array.of_list linenum2bol_pos
  ;  bol_pos2linenum = Array.of_list bol_pos2linenum
  }

let pos_in_range map pos =
  0 <= pos && pos < map.txtlen

let bol_pos2linenum map pos =
  assert (pos_in_range map pos) ;
  let idx = Util.bsearch map.bol_pos2linenum pos in
  assert (fst map.bol_pos2linenum.(idx) <= pos) ;
  snd map.bol_pos2linenum.(idx)

let linenum2bol_pos map n =
  let idx = Util.bsearch map.linenum2bol_pos n in
  assert (fst map.linenum2bol_pos.(idx) = n) ;
  snd map.linenum2bol_pos.(idx)

end

(** checking location integrity

    -- checking individual raw tokens --

    (1) check that the start, column, and line number are consistent:

       line number allows to compute bol_pos: bol_pos + column = start

    -- checking raw token pairs --

    (1) check that end of each token is the same as the start of the next

 *)

let check_raw_pair i a b =
  let open Exec.T in
  let open St_util in
  let raw_a = triple2raw a in
  let raw_b = triple2raw b in
  let msg = Fmt.(str "check_raw_pair: mismatched raw start/end.@.a: %a@. b: %a@."
                   pp_triple a
                   pp_triple b
                ) in
  assert_equal ~msg ((Std.outSome raw_a.stop) + 1) (Std.outSome raw_b.start)

let check_raw bpmap i t =
  let open Exec.T in
  let open St_util in
  let raw = triple2raw t in
  let line = Std.outSome raw.line in
  let column = Std.outSome raw.column in
  let start = Std.outSome raw.start in
  let bol_pos = Bol_pos.linenum2bol_pos bpmap line in
  let msg = Fmt.(str
{|check_raw: token %d
%a
start: %d
line: %d
column: %d
bol_pos: %d
bol_pos+column: %d
@.|}
                 i pp_triple t
                 start line column bol_pos (bol_pos+column)) in
  assert_equal ~msg (bol_pos + column) start

let check_pairs_i f l =
  let rec checkrec i l =
    match l with
      [] | [_] -> ()
      | h::t::l ->
         f i h t ;
         checkrec (i+1) (t::l)
  in checkrec 0 l

let check_locations tokenizer txt pred =
  let triples =
    txt
    |> tokenizer 
    |>  Std.list_of_stream in

  if triples = [] then failwith "check_locations: no tokens" ;
  let bpmap = Bol_pos.init txt in
  List.iteri (check_raw bpmap) triples ;
  check_pairs_i check_raw_pair triples

let test_raw_tokens ctxt =
  check_locations (ST.triple_of_string ~all_channels:true) "< writeln()>" ;
  check_locations (STG.triple_of_string ~all_channels:true) {| 
import "foo" |} ;
  ()

let test_pa_st2 ctxt =
  ()
  ; assert_equal () (ignore([%here_string {|abc def|}] |> ST.located_patterns_of_here_string |> Std.list_of_stream))

let test_pa_stg ctxt =
  ()
  ; assert_equal () (ignore([%here_string {| import "foo" |}] |> STG.located_patterns_of_here_string |> Std.list_of_stream))

let suite = "Test location handling" >::: [
      "raw tokens"   >:: test_raw_tokens
    ; "parse st2"   >:: test_pa_st2
    ]

let _ = 
if not !Sys.interactive then
  run_test_tt_main suite
else ()

