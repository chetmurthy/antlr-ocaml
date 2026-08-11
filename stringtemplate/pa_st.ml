(**pp -syntax camlp5r -package camlp5.extend *)

open Pa_ppx_utils ;
open Pa_ppx_located_yojson ;
open Antlr ;
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

value top_args = Grammar.Entry.create g "top_args";
value top_map_expr = Grammar.Entry.create g "top_map_expr" ;
value top_map_template_ref = Grammar.Entry.create g "top_map_template_ref";
value top_member_expr = Grammar.Entry.create g "top_member_expr";
value top_include_expr = Grammar.Entry.create g "top_include_expr";
value top_subtemplate = Grammar.Entry.create g "top_subtemplate";
value top_expr_options = Grammar.Entry.create g "top_expr_options";


value real_include_expr = Grammar.Entry.create g "real_include_expr";
value include_expr_f strm = Grammar.Entry.parse_token_stream real_include_expr strm ;
value include_expr = Grammar.Entry.of_parser g "include_expr" include_expr_f ;

value real_args = Grammar.Entry.create g "real_args";
value args_f strm = Grammar.Entry.parse_token_stream real_args strm ;
value args = Grammar.Entry.of_parser g "args" args_f ;

value real_named_arg = Grammar.Entry.create g "real_named_arg";
value named_arg_f strm = Grammar.Entry.parse_token_stream real_named_arg strm ;
value named_arg = Grammar.Entry.of_parser g "named_arg" named_arg_f ;

value real_map_expr = Grammar.Entry.create g "real_map_expr" ;
value map_expr_f strm = Grammar.Entry.parse_token_stream real_map_expr strm ;
value map_expr = Grammar.Entry.of_parser g "map_expr" map_expr_f ;

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

value check_not_comma_id_equals_f strm =
  match stream_npeek 3 strm with [
    [("", ","); ("ID",_); ("", "=")] -> raise Stream.Failure
  | _ -> ()
  ]
;

value check_not_comma_id_equals =
  Grammar.Entry.of_parser g "check_not_comma_id_equals"
    check_not_comma_id_equals_f
;

EXTEND
  GLOBAL: template template_eoi
          map_expr real_map_expr top_map_expr
          args real_args top_args
          include_expr real_include_expr top_include_expr
          named_arg real_named_arg

          top_map_template_ref top_member_expr top_include_expr top_subtemplate
          top_expr_options

          check_qid_lparen check_not_lt_if_elseif_else_endif check_id_comma_or_bar
          check_id_equals check_not_comma_id_equals
  ;

template_eoi: [ [ x = template ; EOI -> x ] ] ;

top_map_expr: [ [ "#inside" ; x = map_expr ; EOI -> x ] ] ;
top_map_template_ref: [ [ "#inside" ; x = map_template_ref ; EOI -> x ] ] ;
top_member_expr: [ [ "#inside" ; x = member_expr ; EOI -> x ] ] ;
top_include_expr: [ [ "#inside" ; x = include_expr ; EOI -> x ] ] ;
top_subtemplate: [ [ "#inside" ; x = subtemplate ; EOI -> x ] ] ;
top_args: [ [ "#inside" ; x = args ; EOI -> x ] ] ;
top_expr_options: [ [ "#inside" ; x = expr_options ; EOI -> x ] ] ;

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

real_map_expr: [ [
      me = member_expr ;
      melopt = OPT [ mel = LIST1 [ check_not_comma_id_equals ; "," ; me = member_expr -> me ] ; ":" ; mtr = map_template_ref -> (mel, mtr) ] ;
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

real_args: [ [
      l = LIST1 named_arg SEP "," ; ellipsis = [ "," ; "..." -> True | -> False] ->
      ARGS_NAMED l ellipsis
    | l = arg_expr_list -> ARGS_LIST l
    | -> ARGS_EMPTY
  ] ]
  ;

real_named_arg: [ [ id = ID ; "=" ; e = arg -> (id,e) ] ] ;  

expr: [ [ me = map_expr -> me ] ] ;

real_include_expr: [ [
(*
      check_id_lparen ;
      id = ID ; "(" ; eopt = OPT expr ; ")" -> EXEC_FUNC id eopt
    | *)

      SUPER ; "." ; id = ID ; "(" ; l = args ; ")" -> INCLUDE_SUPER id l
    | check_qid_lparen ;
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

list_: [ [ "[" ; l = LIST0 (OPT list_element) SEP "," ; "]" -> l ] ] ;

list_element: [ [ e = expr_no_comma -> e ] ] ;

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
      l = LIST0 expr_option SEP "," ->  (l : list expr_option_t)
  ] ]
  ;

expr_option: [ [ id = ID ; "=" ; e = expr -> (id,e) ] ] ;

qualified_id: [ [
      rooted = FLAG "/" ; id = ID ; l = LIST0 [ "/" ; id = ID -> id] ->
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

value start_location = Camlp5_adapter.ST.start_location ;
module Template = St_util.PAHelper(struct
                     type t = template_t ;
                     value start_location = start_location ;
                     value entry = template_eoi ;
                   end) ;

module Map_Expr = St_util.PAHelper(struct
                     type t = map_expr_t ;
                     value start_location = start_location ;
                     value entry = top_map_expr ;
                   end) ;

module Map_Template_Ref = St_util.PAHelper(struct
                     type t = map_template_ref_t ;
                     value start_location = start_location ;
                     value entry = top_map_template_ref ;
                   end) ;

module Member_Expr = St_util.PAHelper(struct
                     type t = member_expr_t ;
                     value start_location = start_location ;
                     value entry = top_member_expr ;
                   end) ;

module Include_Expr = St_util.PAHelper(struct
                     type t = include_expr_t ;
                     value start_location = start_location ;
                     value entry = top_include_expr ;
                   end) ;

module Subtemplate = St_util.PAHelper(struct
                     type t = subtemplate_t ;
                     value start_location = start_location ;
                     value entry = top_subtemplate ;
                   end) ;

module Args = St_util.PAHelper(struct
                     type t = args_t ;
                     value start_location = start_location ;
                     value entry = top_args ;
                   end) ;

module Expr_Options = St_util.PAHelper(struct
                     type t = expr_options_t ;
                     value start_location = start_location ;
                     value entry = top_expr_options ;
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
