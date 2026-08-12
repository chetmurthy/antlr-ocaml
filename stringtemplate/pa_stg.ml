(**pp -syntax camlp5r -package camlp5.extend *)

open Pa_ppx_utils ;
open Pa_ppx_located_yojson ;
open Antlr ;
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

value check_id_lparen_f strm =
  match stream_npeek 2 strm with [
    [(("ID"), _); ("", "(")] -> ()
  | _ -> raise Stream.Failure
  ]
;

value check_id_lparen =
  Grammar.Entry.of_parser g "check_id_lparen"
    check_id_lparen_f
;

value check_id_tmplassign_f strm =
  match stream_npeek 2 strm with [
    [(("ID"), _); ("", "::=")] -> ()
  | _ -> raise Stream.Failure
  ]
;

value check_id_tmplassign =
  Grammar.Entry.of_parser g "check_id_tmplassign"
    check_id_tmplassign_f
;

value check_comma_string_f strm =
  match stream_npeek 2 strm with [
    [("", ","); (("STRING"), _)] -> ()
  | _ -> raise Stream.Failure
  ]
;

value check_comma_string =
  Grammar.Entry.of_parser g "check_comma_string"
    check_comma_string_f
;

EXTEND
  GLOBAL: group group_eoi
          check_id_lparen check_id_tmplassign check_comma_string
  ;

group_eoi: [ [ x = group ; EOI -> x ] ] ;

group: [ [
      header = OPT [ h = header -> h ] ;
      dopt = OPT [ d = delimiters -> d ] ;
      iopt = OPT [ i = imports -> i ] ;
      defs = LIST0 [ t = template_ -> GROUPDEF_TEMPLATE t | d = dict_ -> GROUPDEF_DICT d ] ->
      let imports = match iopt with [ None ->  [] | Some l -> l ] in
      { header = header ; imports = imports ; defs = defs }
  ] ]
  ;

header: [ [
      "group" ; name = [ s1 = ID ; s2opt = OPT [ ":" ; s = ID -> s ] -> (s1, s2opt) ] ;
      implements = OPT [ "implements" ; name = [ s1 = ID ; s2opt = OPT [ ":" ; s = ID -> s ] -> (s1, s2opt) ] -> name ] ; ";" ->
       { name = name ; implements = implements }
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

template_: [ [
      "@" ; enclosing = ID ; "." ; name = ID ; "(" ; ")" ->
      failwith "template_: region reference unimplemented"
    | check_id_lparen ;
      name = ID ; "(" ; l = formal_args ; ")" ; "::=" ;
      d = template_def_rhs -> TEMPLATE_DEF name l d
    | name = ID ; "::=" ; rhs = ID -> TEMPLATE_ALIAS name rhs
  ] ]
  ;
template_def_rhs: [ [
      s = STRING -> TDEF_STRING s
    | s = BIGSTRING -> TDEF_BIGSTRING s
    | s = BIGSTRING_NO_NL -> TDEF_BIGSTRING_NO_NL s
  ] ]
  ;

formal_args: [ [ l = LIST0 formal_arg SEP "," -> l ] ] ;

formal_arg: [ [
      name = ID ; "=" ; d = formal_arg_default -> (name, Some d)
    | name = ID  -> (name, None)
  ] ]
  ;

formal_arg_default: [ [
      s = STRING -> FORMAL_STRING s
    | s = ANON_TEMPLATE -> FORMAL_ANON_TEMPLATE s
    | s = "true" -> FORMAL_BOOL True
    | s = "false" -> FORMAL_BOOL False
    | "[" ; "]" -> FORMAL_MT_DICT
  ] ]
  ;

dict_: [ [
      check_id_tmplassign ;
      name = ID ; "::=" ; "[" ; l = dict_pairs ; "]" ->
      (name, l)
  ] ]
  ;

dict_pairs: [ [
      p = key_value_pair ; l = LIST0 [ check_comma_string ; "," ; p = key_value_pair -> p ] ;
      defopt = OPT [ "," ;  p = default_value_pair -> p ] -> ([p::l], defopt)
    | p = default_value_pair -> ([], Some p)
  ] ]
  ;

key_value_pair: [ [ s = STRING ; ":" ; v = key_value -> (s,v) ] ] ;
default_value_pair: [ [ "default" ; ":" ; v = key_value -> v ] ] ;

key_value: [ [
      s = BIGSTRING -> KEYVAL_BIGSTRING s
    | s = BIGSTRING_NO_NL -> KEYVAL_BIGSTRING_NO_NL s
    | s = ANON_TEMPLATE -> KEYVAL_ANON_TEMPLATE s
    | s = STRING -> KEYVAL_STRING s
    | s = "true" -> KEYVAL_BOOL True
    | s = "false" -> KEYVAL_BOOL False
    | "[" ; "]" -> KEYVAL_MT_DICT
    | ID "key" -> KEYVAL_KEY
  ] ]
  ;

END ;

value start_location = Camlp5_adapter.STG.start_location ;
module Group = St_util.PAHelper(struct
                     type t = group_t ;
                     value start_location = start_location ;
                     value entry = group_eoi ;
                   end) ;
