(**pp -syntax camlp5r -package camlp5.extend *)

open Pa_ppx_utils ;
open Pa_ppx_located_yojson ;
open Antlr ;
open Sttypes2 ;
open Stg_types.Raw ;
open Camlp5_adapter ;
open Lexers ;

module Pa(Lex : Exec.FULL_LEXER)(C5Lex : CAMLP5LEXER) = struct

value stream_npeek n s = (Stream.npeek n s : list (string * string)) ;

value lexer = {Plexing.tok_func = C5Lex.lexer;
 Plexing.tok_using _ = (); Plexing.tok_removing _ = ();
 Plexing.tok_match = Plexing.default_match;
 Plexing.tok_text = Plexing.lexer_text;
 Plexing.tok_comm = None ; Plexing.kwds = Hashtbl.create 23 } ;

value g = Grammar.gcreate lexer;
value template = Grammar.Entry.create g "template";
value template_eoi = Grammar.Entry.create g "template_eoi";
value group = Grammar.Entry.create g "group";
value group_eoi = Grammar.Entry.create g "group_eoi";

value pa_ID = parser [: `("ID",id) :] -> id ;
value pa_SLASH = parser [: `("","/") :] -> () ;

value qid = parser [
    [: _=pa_SLASH ; _=Util.plist_with_sep pa_ID pa_SLASH :] -> ()
  | [: _=Util.plist_with_sep pa_ID pa_SLASH :] -> ()
  ]
;

value qid_lparen = parser [
    [: _=qid ; `("","(") :] -> ()
  ]
;

value peek_until pred strm =
  let rec prec n =
    let l = Stream.npeek n strm in
    if List.length l < n then l
    else if pred (Std.last l) then l
    else prec (n+1)
  in
  prec 1
;

value peek_until_EOI_lparen strm =
  let _EOI_or_lparen = fun [
      (("EOI",_)|("","(")) -> True
    | _ -> False
      ]
  in peek_until _EOI_or_lparen strm
;

value check_qid_lparen_f strm =
  let l = peek_until_EOI_lparen strm in
  try do { qid_lparen (Std.stream_of_list l) ; () }
  with _ -> raise Stream.Failure
;

value check_qid_lparen =
  Grammar.Entry.of_parser g "check_qid_lparen"
    check_qid_lparen_f
;

value check_id_comma_or_bar_f strm =
  match stream_npeek 2 strm with [
    [(("ID"), _); ("", (","|"|"))] -> ()
  | _ -> raise Stream.Failure
  ]
;

value check_id_comma_or_bar =
  Grammar.Entry.of_parser g "check_id_comma_or_bar"
    check_id_comma_or_bar_f
;

value check_id_equals_f strm =
  match stream_npeek 2 strm with [
    [(("ID"), _); ("", "=")] -> ()
  | _ -> raise Stream.Failure
  ]
;

value check_id_equals =
  Grammar.Entry.of_parser g "check_id_equals"
    check_id_equals_f
;


value check_not_lt_if_elseif_else_endif_f strm =
  match stream_npeek 2 strm with [
    [("", "<"); ("", ("if"|"elseif"|"else"|"endif"))] -> raise Stream.Failure
  | _ -> ()
  ]
;

value check_not_lt_if_elseif_else_endif =
  Grammar.Entry.of_parser g "check_not_lt_if_elseif_else_endif"
    check_not_lt_if_elseif_else_endif_f
;

value check_comma_id_equals_f strm =
  match stream_npeek 3 strm with [
    [("", ","); ("ID",_); ("", "=")] -> ()
  | _ -> raise Stream.Failure
  ]
;

value check_comma_id_equals =
  Grammar.Entry.of_parser g "check_comma_id_equals"
    check_comma_id_equals_f
;

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

value leftover_f (strm : Stream.t (string * string)) = ();

value leftover =
  Grammar.Entry.of_parser g "leftover"
    leftover_f
;

value mexpr = Grammar.Entry.create g "mexpr";
value mexpr_basic = Grammar.Entry.create g "mexpr_basic";
value mexpr_template_ref = Grammar.Entry.create g "mexpr_template_ref";

value top_mexpr_template_ref = Grammar.Entry.create g "top_mexpr_template_ref";
value top_mexpr_basic = Grammar.Entry.create g "top_mexpr_basic";
value top_me_cond = Grammar.Entry.create g "top_me_cond";
value top_mexpr = Grammar.Entry.create g "top_mexpr";
value top_expr_options = Grammar.Entry.create g "top_expr_options";
value top_expr_option = Grammar.Entry.create g "top_expr_option";

EXTEND
  GLOBAL: template template_eoi
          group group_eoi

          top_mexpr_template_ref
          top_mexpr_basic
          top_me_cond
          top_mexpr
          top_expr_options
          top_expr_option
          leftover

          check_qid_lparen check_not_lt_if_elseif_else_endif check_id_comma_or_bar
          check_id_equals check_comma_id_equals
          check_id_lparen check_id_tmplassign check_comma_string

          mexpr mexpr_basic mexpr_template_ref
  ;

top_mexpr_template_ref: [ [ "#inside" ; x = mexpr_template_ref ; leftover -> x ] ] ;
top_mexpr_basic: [ [ "#inside" ; x = mexpr_basic ; leftover -> x ] ] ;
top_mexpr: [ [ "#inside" ; x = mexpr ; leftover -> x ] ] ;
top_me_cond: [ [ "#inside" ; x = me_cond ; leftover -> x ] ] ;
top_expr_options: [ [ "#inside" ; x = expr_options ; leftover -> x ] ] ;
top_expr_option: [ [ "#inside" ; x = expr_option ; leftover -> x ] ] ;

template_eoi: [ [ x = template ; EOI -> x ] ] ;

template: [ [
      l = LIST0 [ l = limited_template -> l | x = "}" -> [LIT(TEXT x)] ] -> List.concat l
  ] ]
  ;

limited_template: [ [ l = LIST1 element -> l ] ] ;

element: [ [
      check_not_lt_if_elseif_else_endif ;
      x = single_element -> x
    | x = compound_element -> x
  ] ]
  ;

single_element: [ [
      x = expr_tag -> EXPR_TAG x
    | x = TEXT -> LIT (TEXT x)
    | x = ESCAPE -> LIT(TEXT (St_util.unescape_escape_template x))
    | x = HORZ_WS -> LIT(HORZ_WS x)
    | x = VERT_WS -> LIT(VERT_WS x)
  ] ]
  ;

compound_element: [ [
      x = ifstat -> x
    | x = region -> x
  ] ]
  ;

expr_tag: [ [
      "<" ; me = mexpr ; eo_opt = OPT [ ";" ; eo = expr_options -> eo ] ; ">" ->
      let eo_list = match eo_opt with [ None -> [] | Some l -> l ] in
      (me,  eo_list)
  ] ]
  ;

expr_options: [ [
      l = LIST0 expr_option SEP "," ->  l
  ] ]
  ;

expr_option: [ [ id = ID ; eopt = OPT [ "=" ; e = mexpr_no_comma -> e ] -> (id,eopt) ] ] ;

mexpr:
  [ "top" LEFTA
    [ e1 = SELF ; ":" ; t = mexpr_template_ref -> ME_MAP e1 t ]
  | "comma" RIGHTA
    [ e1 = SELF ; "," ; e2 = SELF -> ME_CAT e1 e2 ]
  | "dot" LEFTA
    [ e1 = SELF ; "." ; id = ID -> ME_PROP e1 id
    | e1 = SELF ; "." ; "(" ; e2 = mexpr ; ")" -> ME_PROP_IND e1 e2 ]
  | "basic"
    [ me = mexpr_basic -> me ]
  ]
  ;

mexpr_basic: [
    [ mt = mexpr_basic_template_ref -> mt
    | "(" ; me = mexpr ; ")" ; "(" ; l = LIST0 mexpr_no_comma SEP "," ; ")" -> ME_TEMPLATE (MTR_INCLUDE_IND me l)
    | "(" ; me = mexpr ; ")" -> me
    | p = mexpr_primary -> ME_PRIMARY p
    ]
  ]
  ;

mexpr_primary: [
    [ id = ID -> ME_ID id
    | s = STRING -> ME_STRING (snd (St_util.unescape_stg_string (loc, s)))
    | "true" -> ME_BOOL True
    | "false" -> ME_BOOL False
    | "[" ; l = LIST0 (OPT mexpr_no_comma) SEP "," ; "]" -> ME_LIST l
    | "(" ; c = me_cond ; ")" -> ME_COND c
    ]
  ]
  ;

me_cond: [
    "OR" RIGHTA [ e1 = SELF ; "||" ; e2 = SELF -> COND_OR e1 e2 ]
  | "AND" RIGHTA [ e1 = SELF ; "&&" ; e2 = SELF -> COND_OR e1 e2 ]
  | "NOT" [ "!" ; e = SELF -> COND_NOT e ]
  | "parens" [ "(" ; e = SELF ; ")" -> e ]
  | "ATOM" [ e = mexpr LEVEL "dot" -> COND_ATOM e ] 
  ]
  ;
mexpr_basic_template_ref: [ [
      check_qid_lparen ;
      qid = qualified_id ; "(" ; a = args ; ")" -> ME_TEMPLATE (MTR_INCLUDE qid a)
    | st = subtemplate -> ME_TEMPLATE (MTR_SUB st)
  ] ]
  ;
mexpr_template_ref: [ [
      check_qid_lparen ;
      qid = qualified_id ; "(" ; a = args ; ")" -> MTR_INCLUDE qid a
    | st = subtemplate -> MTR_SUB st
    | "(" ; me = mexpr ; ")" ; "(" ; l = LIST0 mexpr_no_comma SEP "," ; ")" -> MTR_INCLUDE_IND me l
  ] ]
  ;

subtemplate: [ [
      "{" ; lopt = OPT [ ids = LIST1 ID SEP "," ; "|" -> ids ] ; t = [ -> [] | l = limited_template -> l ] ; "}" ->
      let l = match lopt with [ None -> [] | Some l -> l ] in
      (l, t)
  ] ]
  ;

qualified_id: [ [
      rooted = FLAG "/" ;
      ids = LIST1 ID SEP "/" ->
      { rooted = False ; ids = ids }
  ] ]
  ;

args: [ [
      check_id_equals ;
      a1 = named_arg ; al = LIST0 [ check_comma_id_equals ; "," ; a = named_arg -> a ] ; 
      ellipsis = [ "," ; "..." -> True | -> False] ->
      ARGS_NAMED [a1::al] ellipsis
    | "..." -> ARGS_NAMED [] True
    | l = LIST1 mexpr_no_comma SEP "," -> ARGS_LIST l
    | -> ARGS_EMPTY
  ] ]
  ;

mexpr_no_comma: [ [
        me = mexpr LEVEL "dot" ; ":" ; mtr = mexpr_template_ref -> ME_MAP me mtr
      | me = mexpr LEVEL "dot" -> me
    ] ]
;


named_arg: [ [ id = ID ; "=" ; e = mexpr_no_comma -> (id,e) ] ] ;  


ifstat: [ [
      "<" ; "if" ; "(" ; c1 = me_cond ; ")" ; ">" ; t1 = template ;
      l = LIST0 [ "<" ; "elseif" ; "(" ; c = me_cond ; ")" ; ">" ; t = template -> (c,t) ] ;
      elseopt = OPT [ "<" ; "else" ; ">" ; t = template -> t ] ;
      "<" ; "endif" ; ">" -> IFSTAT c1 t1 l elseopt
  ] ]
  ;

region: [ [ ] ] ;

group_eoi: [ [ x = group ; EOI -> x ] ] ;

group: [ [
      header = OPT [ h = header -> h ] ;
      dopt = OPT [ d = delimiters -> d ] ;
      iopt = OPT [ i = imports -> i ] ;
      defs = LIST0 [ t = template_ -> t | d = dict_ -> GROUPDEF_DICT loc d ] ->
      let imports = match iopt with [ None ->  [] | Some l -> l ] in
      { loc = loc ; filename = Ploc.file_name loc ; header = header ; imports = imports ; defs = defs }
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
      l = LIST1 [ "import" ; s = STRING -> snd (St_util.unescape_stg_string (loc, s)) ] -> l
  ] ]
  ;

template_: [ [
      "@" ; enclosing = ID ; "." ; name = ID ; "(" ; ")" ->
      failwith "template_: region reference unimplemented"
    | check_id_lparen ;
      name = ID ; "(" ; l = formal_args ; ")" ; "::=" ;
      d = template_def_rhs -> GROUPDEF_TEMPLATE_DEF loc name l d
    | name = ID ; "::=" ; rhs = ID -> GROUPDEF_TEMPLATE_ALIAS loc name rhs
  ] ]
  ;
template_def_rhs: [ [
      s = STRING -> TDEF_STRING (loc, s)
    | s = BIGSTRING -> TDEF_BIGSTRING (loc, s)
    | s = BIGSTRING_NO_NL -> TDEF_BIGSTRING_NO_NL (loc, s)
  ] ]
  ;

formal_args: [ [ l = LIST0 formal_arg SEP "," -> l ] ] ;

formal_arg: [ [
      name = ID ; "=" ; d = formal_arg_default -> (name, Some d)
    | name = ID  -> (name, None)
  ] ]
  ;

formal_arg_default: [ [
      s = STRING -> FORMAL_STRING (loc, s)
    | s = subtemplate -> FORMAL_SUBTEMPLATE s
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

key_value_pair: [ [ s = STRING ; ":" ; v = key_value -> ((loc, s),v) ] ] ;
default_value_pair: [ [ "default" ; ":" ; v = key_value -> v ] ] ;

key_value: [ [
      s = BIGSTRING -> KEYVAL_BIGSTRING (loc, s)
    | s = BIGSTRING_NO_NL -> KEYVAL_BIGSTRING_NO_NL (loc, s)
    | s = subtemplate -> KEYVAL_SUBTEMPLATE s
    | s = STRING -> KEYVAL_STRING (loc, s)
    | s = "true" -> KEYVAL_BOOL True
    | s = "false" -> KEYVAL_BOOL False
    | "[" ; "]" -> KEYVAL_MT_DICT
    | ID "key" -> KEYVAL_KEY
  ] ]
  ;

END ;

value start_location = C5Lex.start_location ;
module Template = St_util.PAHelper(struct
                     type t = template_t ;
                     value start_location = start_location ;
                     value entry = template_eoi ;
                   end) ;

module Mexpr_Template_Ref = St_util.PAHelper(struct
                     type t = mexpr_template_ref_t ;
                     value start_location = start_location ;
                     value entry = top_mexpr_template_ref ;
                   end) ;

module Mexpr_Basic = St_util.PAHelper(struct
                     type t = mexpr_t ;
                     value start_location = start_location ;
                     value entry = top_mexpr_basic ;
                   end) ;

module Mexpr = St_util.PAHelper(struct
                     type t = mexpr_t ;
                     value start_location = start_location ;
                     value entry = top_mexpr ;
                   end) ;

module Me_Cond = St_util.PAHelper(struct
                     type t = mexpr_cond_t ;
                     value start_location = start_location ;
                     value entry = top_me_cond ;
                   end) ;

module Expr_Options = St_util.PAHelper(struct
                     type t = list (string * option mexpr_t)  ;
                     value start_location = start_location ;
                     value entry = top_expr_options ;
                   end) ;

module Expr_Option = St_util.PAHelper(struct
                     type t = (string * option mexpr_t)  ;
                     value start_location = start_location ;
                     value entry = top_expr_option ;
                   end) ;

module Group = St_util.PAHelper(struct
                     type t = group_t ;
                     value start_location = start_location ;
                     value entry = group_eoi ;
                   end) ;

end
;

module STG2_STPa = Pa(STG2Lexer.Full)(STG2_ST) ;
module STG2_STGPa = Pa(STG2Lexer.Full)(STG2_STG) ;
