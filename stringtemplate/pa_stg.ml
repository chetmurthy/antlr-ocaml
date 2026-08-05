(**pp -syntax camlp5r -package camlp5.extend *)

open Pa_ppx_utils ;
open Pa_ppx_located_yojson ;
open Stg_types ;

value stream_npeek n s = (Stream.npeek n s : list (string * string)) ;

value lexer = {Plexing.tok_func = Camlp5_adapter.STG.lexer;
 Plexing.tok_using _ = (); Plexing.tok_removing _ = ();
 Plexing.tok_match = Plexing.default_match;
 Plexing.tok_text = Plexing.lexer_text;
 Plexing.tok_comm = None ; Plexing.kwds = Hashtbl.create 23 } ;

value g = Grammar.gcreate lexer;
value group = Grammar.Entry.create g "group";
value group_eoi = Grammar.Entry.create g "group_eoi";

EXTEND
  GLOBAL: group group_eoi
  ;

group_eoi: [ [ x = group ; EOI -> x ] ] ;

group: [ [
      dopt = OPT [ d = delimiters -> d ] ;
      iopt = OPT [ i = imports -> i ] ->
      let imports = match iopt with [ None ->  [] | Some l -> l ] in
      { imports = imports }
  ] ]
  ;

delimiters: [ [
      "delimiters" ; x1 = STRING ; "," ; x2 = STRING ->
      failwith "Pa_stg: delimiters unsupported (for now)"
  ] ]
  ;

imports: [ [
      l = LIST1 [ "import" ; s = STRING -> s ] -> l
  ] ]
  ;

END ;

module Group = Pa_json.PAHelper(struct
                     type t = group_t ;
                     value entry = group_eoi ;
                   end) ;
