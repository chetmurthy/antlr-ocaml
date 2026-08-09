(**pp -syntax camlp5r -package camlp5.extend *)

open Pa_ppx_utils ;
open Pa_ppx_located_yojson ;
open St_types ;

value stream_npeek n s = (Stream.npeek n s : list (string * string)) ;

value lexer = {Plexing.tok_func = Camlp5_adapter.ST.lexer;
 Plexing.tok_using _ = (); Plexing.tok_removing _ = ();
 Plexing.tok_match = Plexing.default_match;
 Plexing.tok_text = Plexing.lexer_text;
 Plexing.tok_comm = None ; Plexing.kwds = Hashtbl.create 23 } ;

value g = Grammar.gcreate lexer;
value template = Grammar.Entry.create g "template";
value template_eoi = Grammar.Entry.create g "template_eoi";

value top_map_expr = Grammar.Entry.create g "top_map_expr";
value top_map_template_ref = Grammar.Entry.create g "top_map_template_ref";
value top_member_expr = Grammar.Entry.create g "top_member_expr";
value top_include_expr = Grammar.Entry.create g "top_include_expr";
value top_subtemplate = Grammar.Entry.create g "top_subtemplate";

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

EXTEND
  GLOBAL: template template_eoi
          top_map_expr top_map_template_ref top_member_expr top_include_expr
          top_subtemplate
          check_id_lparen check_not_lt_if_elseif_else_endif check_id_comma_or_bar
          check_id_equals
  ;

template_eoi: [ [ x = template ; EOI -> x ] ] ;

top_map_expr: [ [ "#inside" ; x = map_expr ; EOI -> x ] ] ;
top_map_template_ref: [ [ "#inside" ; x = map_template_ref ; EOI -> x ] ] ;
top_member_expr: [ [ "#inside" ; x = member_expr ; EOI -> x ] ] ;
top_include_expr: [ [ "#inside" ; x = include_expr ; EOI -> x ] ] ;
top_subtemplate: [ [ "#inside" ; x = subtemplate ; EOI -> x ] ] ;

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
      "<" ; me = map_expr ; eo_opt = OPT [ ";" ; eo = expr_options -> eo ] ; ">" ->
      let eo_list = match eo_opt with [ None -> [] | Some l -> l ] in
      (me,  eo_list)
  ] ]
  ;

map_expr: [ [
      me = member_expr ;
      melopt = OPT [ mel = LIST1 [ "," ; me = member_expr -> me ] ; ":" ; mtr = map_template_ref -> (mel, mtr) ] ;
      mtrll = LIST0 [ ":" ; mtrl = LIST1 map_template_ref SEP "," -> mtrl ] ->
      (me, melopt, mtrll)
  ] ]
  ;

member_expr: [ [
      iexp = include_expr ;
      l = LIST0 [ "." ; id = ID -> IEARG_ID id
                | "." ; "(" ; me = map_expr ; ")" -> IEARG_EXPR me ] ->
      (iexp, l)
  ] ]
  ;

map_template_ref: [ [
      qid = qualified_id ; "(" ; a = args ; ")" -> MT_INCLUDE qid a
    | st = subtemplate -> MT_SUB st
    | "(" ; me = map_expr ; ")" ; "(" ; mel = arg_expr_list ; ")" -> MT_INCLUDE_IND me mel
  ] ]
  ;

args: [ [
      check_id_equals ;
      l = LIST1 named_arg SEP "," ; ellipsis = [ "," ; "..." -> True | -> False] ->
      ARGS_NAMED l ellipsis
    | l = arg_expr_list -> ARGS_LIST l
    | -> ARGS_EMPTY
  ] ]
  ;

named_arg: [ [ id = ID ; "=" ; e = expr -> (id,e) ] ] ;  

expr: [ [ me = map_expr -> me ] ] ;

include_expr: [ [
(*
      check_id_lparen ;
      id = ID ; "(" ; eopt = OPT expr ; ")" -> EXEC_FUNC id eopt
    | *)

      SUPER ; "." ; id = ID ; "(" ; l = args ; ")" -> INCLUDE_SUPER id l
    | check_id_lparen ;
      qid = qualified_id ; "(" ; l = args ; ")" -> INCLUDE qid l
    | "@" ; SUPER ; "." ; id = ID ; "(" ; ")" -> INCLUDE_SUPER_REGION id
    | "@" ; id = ID ; "(" ; ")" -> INCLUDE_REGION id
    | p = primary -> INCLUDE_PRIMARY p
  ] ]
  ;

primary: [ [
      id = ID -> PRIMARY_ID id
    | s = STRING -> PRIMARY_STRING s
    | "true" -> PRIMARY_BOOL True
    | "false" -> PRIMARY_BOOL False
    | st = subtemplate -> PRIMARY_SUBTEMPLATE st
    | l = list_ -> PRIMARY_LIST l
    | "(" ; c = conditional ; ")" -> PRIMARY_CONDITIONAL c
    | "(" ; e = expr ; ")" ; aeopt = OPT [ "(" ; ae = arg_expr_list ; ")" -> ae ] ->
      PRIMARY_INCLUDE_IND e aeopt
  ] ]
  ;

list_: [ [ "[" ; lopt = OPT arg_expr_list ; "]" -> lopt ] ] ;

conditional: [ [ l = LIST1 and_conditional SEP "||" -> OR l ] ] ;
and_conditional: [ [ l = LIST1 not_conditional SEP "&&" -> AND l ] ] ;
not_conditional: [ [
      "!" ; c = not_conditional -> NOT c
    | me = member_expr -> ATOM me
    ] ]
  ;

subtemplate: [ [
      "{" ; lopt = OPT [ ids = LIST1 ID SEP "," ; "|" -> ids ] ; t = [ -> [] | l = limited_template -> l ] ; "}" ->
      let l = match lopt with [ None -> [] | Some l -> l ] in
      (l, t)
  ] ]
  ;

arg_expr_list: [ [ l = LIST1 arg SEP "," -> l ] ];

arg: [ [ e = expr_no_comma -> e  ] ] ;

expr_no_comma: [ [
        me = member_expr ;
        mtropt = OPT [ ":" ; mtr = map_template_ref -> mtr ] ->
        let l = match mtropt with [ None -> [] | Some mtr -> [[mtr]] ] in
        (me, None, l)
    ] ]
;

expr_options: [ [
      l = LIST0 [ "," ; eo = expr_option -> eo ] ->  (l : list expr_option_t)
  ] ]
  ;

expr_option: [ [ id = ID ; "=" ; e = expr -> (id,e) ] ] ;

qualified_id: [ [
      rooted = FLAG SLASH ; id = ID ; l = LIST0 [ SLASH ; id = ID -> id] ->
      if rooted then QID_ROOTED [id::l] else QID [id::l]
  ] ]
  ;

ifstat: [ [
      "<" ; "if" ; "(" ; c1 = conditional ; ")" ; ">" ; t1 = template ;
      l = LIST0 [ "<" ; "elseif" ; "(" ; c = conditional ; ")" ; ">" ; t = template -> (c,t) ] ;
      elseopt = OPT [ "<" ; "else" ; ">" ; t = template -> t ] ;
      "<" ; "endif" ; ">" -> IFSTAT c1 t1 l elseopt
  ] ]
  ;

region: [ [ ] ] ;

END ;

module Template = Pa_json.PAHelper(struct
                     type t = template_t ;
                     value entry = template_eoi ;
                   end) ;

module Map_Expr = Pa_json.PAHelper(struct
                     type t = map_expr_t ;
                     value entry = top_map_expr ;
                   end) ;

module Map_Template_Ref = Pa_json.PAHelper(struct
                     type t = map_template_ref_t ;
                     value entry = top_map_template_ref ;
                   end) ;

module Member_Expr = Pa_json.PAHelper(struct
                     type t = member_expr_t ;
                     value entry = top_member_expr ;
                   end) ;

module Include_Expr = Pa_json.PAHelper(struct
                     type t = include_expr_t ;
                     value entry = top_include_expr ;
                   end) ;

module Subtemplate = Pa_json.PAHelper(struct
                     type t = subtemplate_t ;
                     value entry = top_subtemplate ;
                   end) ;
