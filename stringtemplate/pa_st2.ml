(**pp -syntax camlp5r -package camlp5.extend *)

open Pa_ppx_utils ;
open Pa_ppx_located_yojson ;
open Antlr ;
open Sttypes2 ;

value stream_npeek n s = (Stream.npeek n s : list (string * string)) ;

value lexer = {Plexing.tok_func = Camlp5_adapter.ST.lexer;
 Plexing.tok_using _ = (); Plexing.tok_removing _ = ();
 Plexing.tok_match = Plexing.default_match;
 Plexing.tok_text = Plexing.lexer_text;
 Plexing.tok_comm = None ; Plexing.kwds = Hashtbl.create 23 } ;

value g = Grammar.gcreate lexer;
value template = Grammar.Entry.create g "template";
value template_eoi = Grammar.Entry.create g "template_eoi";

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

value mexpr = Grammar.Entry.create g "mexpr";
value mexpr_basic = Grammar.Entry.create g "mexpr_basic";
value mexpr_template_ref = Grammar.Entry.create g "mexpr_template_ref";

value top_mexpr_template_ref = Grammar.Entry.create g "top_mexpr_template_ref";
value top_mexpr_basic = Grammar.Entry.create g "top_mexpr_basic";

EXTEND
  GLOBAL: template template_eoi

          top_mexpr_template_ref
          top_mexpr_basic

          check_qid_lparen check_not_lt_if_elseif_else_endif check_id_comma_or_bar
          check_id_equals check_comma_id_equals

          mexpr mexpr_basic mexpr_template_ref

  ;

top_mexpr_template_ref: [ [ "#inside" ; x = mexpr_template_ref ; EOI -> x ] ] ;
top_mexpr_basic: [ [ "#inside" ; x = mexpr_basic ; EOI -> x ] ] ;

template_eoi: [ [ x = template ; EOI -> x ] ] ;

template: [ [
      l = LIST0 [ l = limited_template -> l | x = "}" -> [TEXT x] ] -> List.concat l
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
    | x = TEXT -> TEXT x
    | x = ESCAPE -> TEXT (St_util.unescape x)
    | x = HORZ_WS -> HORZ_WS x
    | x = VERT_WS -> VERT_WS x
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

expr_option: [ [ id = ID ; "=" ; e = mexpr -> (id,e) ] ] ;

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
    [ mt = mexpr_template_ref -> ME_TEMPLATE mt
    | p = mexpr_primary -> ME_PRIMARY p
    ]
  ]
  ;

mexpr_primary: [
    [ id = ID -> ME_ID id
    | s = STRING -> ME_STRING s
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
  | "ATOM" [ e = mexpr LEVEL "dot" -> COND_ATOM e ] 
  ]
  ;
mexpr_template_ref: [ [
      check_qid_lparen ;
      qid = qualified_id ; "(" ; a = args ; ")" -> ME_INCLUDE qid a
    | st = subtemplate -> ME_SUB st
    | "(" ; me = mexpr ; ")" ; "(" ; l = LIST0 mexpr_no_comma SEP "," ; ")" -> ME_INCLUDE_IND me l
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

END ;

value start_location = Camlp5_adapter.ST.start_location ;
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


value lexfunc_of_string ?{startloc} s =
  St_util.with_location start_location ?{startloc} (fun s ->
      s |> Stream.of_string |> lexer.Plexing.tok_func) s
;

value tokens_of_string ?{startloc} s =
  let x = lexfunc_of_string ?{startloc} s in
  fst x
;

value tokens_of_here_string (pos, s) =
  let startloc = Util.ploc_of_position pos in
  tokens_of_string ~{startloc=startloc} s
;
