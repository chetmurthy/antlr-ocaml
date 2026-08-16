(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.deriving_plugins.std,pa_ppx.here,pa_ppx_fmtformat *)

open OUnit2

open Pa_ppx_base
open Ppxutil
open Pa_ppx_utils

open Antlr
open Antlrtest
open Stringtemplate
open Camlp5_adapter

Pa_ppx_runtime.Exceptions.Ploc.pp_loc_verbose := true ;;

module ST = ST2
module STG = STG0

let caches = Simulate.Caches.mk () ;;
Exec.file_init ~dfast_cache:caches.dfast ~acs_cache:caches.acs ~ac_cache:caches.ac () ;;

let assert_equal_field name pp v1 v2 msg =
  let msg = Fmt.(str "field %s; %a <> %a\n%s" name pp v1 pp v2 msg) in
  assert_equal ~msg v1 v2

let assert_equal_locations ?(except=[]) ~msg exp loc =
  let exp = Ploc.Internal.of_t exp in
  let loc = Ploc.Internal.of_t loc in
  ()
  ; if not(List.mem  "fname" except) then
      assert_equal_field "fname" Fmt.Dump.string exp.fname loc.fname msg
  ; if not(List.mem  "line_nb" except) then
      assert_equal_field "line_nb" Fmt.int exp.line_nb loc.line_nb msg
  ; if not(List.mem  "bol_pos" except) then
      assert_equal_field "bol_pos" Fmt.int exp.bol_pos loc.bol_pos msg
  ; if not(List.mem  "line_nb_last" except) then
      assert_equal_field "line_nb_last" Fmt.int exp.line_nb_last loc.line_nb_last msg
  ; if not(List.mem  "bol_pos_last" except) then
      assert_equal_field "bol_pos_last" Fmt.int exp.bol_pos_last loc.bol_pos_last msg
  ; if not(List.mem  "bp" except) then
      assert_equal_field "bp" Fmt.int exp.bp loc.bp msg
  ; if not(List.mem  "ep" except) then
      assert_equal_field "ep" Fmt.int exp.ep loc.ep msg
  ; if not(List.mem  "comm" except) then
      assert_equal_field "comm" Fmt.string exp.comm loc.comm msg
  ; if not(List.mem  "ecomm" except) then
      assert_equal_field "ecomm" Fmt.string exp.ecomm loc.ecomm msg

let test_position_to_ploc ctxt =
  let open Lexing in
  let pos = {pos_fname = "location_handling_test.ml"; pos_lnum = 205;
             pos_bol = 6173; pos_cnum = 6252} in
  let wanted_ploc = Ploc.make_loc pos.pos_fname pos.pos_lnum pos.pos_bol (pos.pos_cnum, pos.pos_cnum) "" in
  let ploc = Util.ploc_of_position pos in
  let msg =
    Fmt.(str {|hand-constructed location not as expected
expected:%a
built]: %a
@.|}
         Util.PlocInternal.pp (Ploc.Internal.of_t wanted_ploc)
         Util.PlocInternal.pp (Ploc.Internal.of_t ploc)) in

  assert_equal_locations ~msg wanted_ploc ploc

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

    ASSUMPTION: text will always be presented as raw-strings.

    -- checking zeroth raw token --

    (1) check raw[0].start = 0
    (2) check raw[0].line = 1

    -- checking zeroth location --

    (1) check loc[0] = startloc [except for "ep" field]

    -- checking individual raw tokens --

    (1) check that the start, column, and line number are consistent:

       line number allows to compute bol_pos: bol_pos + column = start

    -- checking individual locations --

    (1) loc.bp = raw.start + start_loc.bp
    (2) loc.ep = raw.stop + 1 + loc.bp
    (3) loc.line = startloc.line + raw.line - 1
    (4) loc.bol_pos = startloc.bol_pos + raw.line->bol_pos

    -- checking raw token pairs --

    (1) check that end of each token is the same as the start of the next

 *)

let check_zeroth_raw startloc t =
  let open Exec.T in
  let open St_util in
  let raw = triple2raw t in
  assert_equal ~msg:"zeroth raw.start <> 0" 0 (Std.outSome raw.start)
; assert_equal ~msg:"zeroth raw.line <> 1" 1 (Std.outSome raw.line)

let check_zeroth_location startloc t =
  let open Exec.T in
  let open St_util in
  let raw = triple2raw t in
  let ploc = triple2ploc t in
  let msg =
    Fmt.(str {|zeroth location not equal to startloc
startloc:%a
triple[0]: %a
@.|}
         Util.PlocInternal.pp (Ploc.Internal.of_t startloc)
         pp_triple t) in
  assert_equal_locations ~except:["ep"] ~msg startloc ploc

let check_raw_pair startloc i a b =
  let open Exec.T in
  let open St_util in
  let raw_a = triple2raw a in
  let raw_b = triple2raw b in
  let msg = Fmt.(str "check_raw_pair: mismatched raw start/end.@.a: %a@. b: %a@."
                   pp_triple a
                   pp_triple b
                ) in
  assert_equal ~msg ((Std.outSome raw_a.stop) + 1) (Std.outSome raw_b.start)

let check_raw startloc bpmap i t =
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

let check_location startloc bpmap i t =
  let open Exec.T in
  let open St_util in
  let startloc = Ploc.Internal.of_t startloc in
  let raw = triple2raw t in
  let raw_start = Std.outSome raw.start in
  let raw_stop = Std.outSome raw.stop in
  let raw_line = Std.outSome raw.line in
  let ploc = triple2ploc t in
  let ploc = Ploc.Internal.of_t ploc in
  let printer = string_of_int in
  let msg = {%fmt_str|startloc: $(startloc|Util.PlocInternal.pp)@.
t: $(t|pp_triple)|} in
  assert_equal ~msg:{%fmt_str|loc[$(i|%d)].bp
$(msg|%s)|} ~printer (raw_start + startloc.bp) ploc.bp ;
  assert_equal ~msg:{%fmt_str|loc[$(i|%d)].ep
$(msg|%s)|} ~printer (raw_stop + 1 + startloc.bp) ploc.ep ;
  assert_equal ~msg:{%fmt_str|loc[$(i|%d)].line
$(msg|%s)|} ~printer (raw_line + startloc.line_nb - 1) ploc.line_nb ;
let raw_bol_pos = Bol_pos.linenum2bol_pos bpmap raw_line in
  assert_equal ~msg:{%fmt_str|loc[$(i|%d)].bol_pos
linenum2bol_pos[raw_line=$(raw_line|%d)]: $(raw_bol_pos|%d)@.
$(msg|%s)|} ~printer
    (if raw_line = 1 then startloc.bol_pos else startloc.bp + raw_bol_pos) ploc.bol_pos ;
  ()


let check_pairs_i f l =
  let rec checkrec i l =
    match l with
      [] | [_] -> ()
      | h::t::l ->
         f i h t ;
         checkrec (i+1) (t::l)
  in checkrec 0 l

let check_locations tokenizer (pos, txt) =
  let startloc = Util.ploc_of_position pos in
  let triples =
    (pos, txt)
    |> tokenizer 
    |>  Std.list_of_stream in

  if triples = [] then failwith "check_locations: no tokens" ;
  let bpmap = Bol_pos.init txt in
  check_zeroth_raw startloc (List.hd triples) ;
  check_zeroth_location startloc (List.hd triples) ;
  List.iteri (check_raw startloc bpmap) triples ;
  List.iteri (check_location startloc bpmap) triples ;
  check_pairs_i (check_raw_pair startloc) triples

let test_raw_tokens ctxt =
  check_locations (ST.triple_of_here_string ~all_channels:true) [%here_string "< writeln()>"] ;
  check_locations (STG.triple_of_here_string ~all_channels:true) [%here_string {| 
import "foo" |}] ;
  ()

let test_pa_st2 ctxt =
  ()
  ; assert_equal () (ignore([%here_string {|abc def|}] |> ST.located_patterns_of_here_string |> Std.list_of_stream))

let test_pa_stg ctxt =
  ()
  ; assert_equal () (ignore([%here_string {| import "foo" |}] |> STG.located_patterns_of_here_string |> Std.list_of_stream))

let suite = "Test location handling" >::: [
      "position->ploc"   >:: test_position_to_ploc
    ; "raw tokens"   >:: test_raw_tokens
    ; "parse st2"   >:: test_pa_st2
    ]

let _ = 
if not !Sys.interactive then
  run_test_tt_main suite
else ()

