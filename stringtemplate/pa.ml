(**pp -syntax camlp5r -package camlp5.extend *)

open Pa_ppx_utils ;
open Pa_ppx_located_yojson ;
open St_types ;

value stream_npeek n s = (Stream.npeek n s : list (string * string)) ;

value lexer = {Plexing.tok_func = Camlp5_adapter.lexer;
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

value check_id_lparen_f strm =
  match stream_npeek 2 strm with [
    [(("ID"), _); ("LPAREN", "(")] -> ()
  | _ -> raise Stream.Failure
  ]
;

value check_id_lparen =
  Grammar.Entry.of_parser g "check_id_lparen"
    check_id_lparen_f
;



EXTEND
  GLOBAL: template template_eoi
          top_map_expr top_map_template_ref top_member_expr top_include_expr
          check_id_lparen
  ;

template_eoi: [ [ x = template ; EOI -> x ] ] ;

top_map_expr: [ [ "#inside" ; x = map_expr ; EOI -> x ] ] ;
top_map_template_ref: [ [ "#inside" ; x = map_template_ref ; EOI -> x ] ] ;
top_member_expr: [ [ "#inside" ; x = member_expr ; EOI -> x ] ] ;
top_include_expr: [ [ "#inside" ; x = include_expr ; EOI -> x ] ] ;

template: [ [ l = LIST0 element -> l ] ] ;

element: [ [
      x = single_element -> x
    | x = compound_element -> x
  ] ]
  ;

single_element: [ [
      x = expr_tag -> EXPR_TAG x
    | x = [ x = TEXT -> x | x = RBRACE -> x ] -> TEXT x
  ] ]
  ;

compound_element: [ [
      x = ifstat -> x
    | x = region -> x
  ] ]
  ;

expr_tag: [ [
      LDELIM ; me = map_expr ; eo_opt = OPT [ SEMI ; eo = expr_options -> eo ] ; RDELIM ->
      let eo_list = match eo_opt with [ None -> [] | Some l -> l ] in
      (me,  eo_list)
  ] ]
  ;

map_expr: [ [
      me = member_expr ;
      melopt = OPT [ mel = LIST1 [ COMMA ; me = member_expr -> me ] ; COLON ; mtr = map_template_ref -> (mel, mtr) ] ;
      mtrll = LIST0 [ COLON ; mtrl = LIST1 map_template_ref SEP COMMA -> mtrl ] ->
      (me, melopt, mtrll)
  ] ]
  ;

member_expr: [ [
      iexp = include_expr ;
      l = LIST0 [ DOT ; id = ID -> IEARG_ID id
                | DOT ; LPAREN ; me = map_expr ; RPAREN -> IEARG_EXPR me ] ->
      (iexp, l)
  ] ]
  ;

map_template_ref: [ [
      qid = qualified_id ; LPAREN ; a = args ; RPAREN -> MT_INCLUDE qid a
    | st = subtemplate -> MT_SUB st
    | LPAREN ; me = map_expr ; RPAREN ; LPAREN ; mel = arg_expr_list ; RPAREN -> MT_INCLUDE_IND me mel
  ] ]
  ;

args: [ [
      l = arg_expr_list -> ARGS_LIST l
    | l = LIST1 named_arg SEP COMMA ; ellipsis = [ COMMA ; ELLIPSIS -> True | -> False] ->
      ARGS_NAMED l ellipsis
    | -> ARGS_EMPTY
  ] ]
  ;

named_arg: [ [ id = ID ; EQUALS ; e = expr -> (id,e) ] ] ;  

expr: [ [ me = map_expr -> me ] ] ;

include_expr: [ [
      check_id_lparen ;
      id = ID ; LPAREN ; eopt = OPT expr ; RPAREN -> EXEC_FUNC id eopt
    | SUPER ; DOT ; id = ID ; LPAREN ; l = args ; RPAREN -> INCLUDE_SUPER id l
(*
    | qid = qualified_id ; LPAREN ; l = args ; RPAREN -> INCLUDE qid l
 *)
    | AT ; SUPER ; DOT ; id = ID ; LPAREN ; RPAREN -> INCLUDE_SUPER_REGION id
    | AT ; id = ID ; LPAREN ; RPAREN -> INCLUDE_REGION id
    | p = primary -> INCLUDE_PRIMARY p
  ] ]
  ;

primary: [ [
      id = ID -> PRIMARY_ID id
    | s = STRING -> PRIMARY_STRING s
    | TRUE -> PRIMARY_BOOL True
    | FALSE -> PRIMARY_BOOL False
    | st = subtemplate -> PRIMARY_SUBTEMPLATE st
    | l = list_ -> PRIMARY_LIST l
    | LPAREN ; c = conditional ; RPAREN -> PRIMARY_CONDITIONAL c
    | LPAREN ; e = expr ; RPAREN ; aeopt = OPT [ LPAREN ; ae = arg_expr_list ; RPAREN -> ae ] ->
      PRIMARY_INCLUDE_IND e aeopt
  ] ]
  ;

list_: [ [ LBRACK ; lopt = OPT arg_expr_list ; RBRACK -> lopt ] ] ;

conditional: [ [ l = LIST1 and_conditional SEP OR -> OR l ] ] ;
and_conditional: [ [ l = LIST1 not_conditional SEP AND -> AND l ] ] ;
not_conditional: [ [
      BANG ; c = not_conditional -> NOT c
    | me = member_expr -> ATOM me
    ] ]
  ;


subtemplate: [ [
      LBRACE ; lopt = OPT [ ids = LIST1 ID SEP COMMA ; PIPE -> ids ] ; t = template ; RBRACE ->
      let l = match lopt with [ None -> [] | Some l -> l ] in
      (l, t)
  ] ]
  ;

arg_expr_list: [ [ l = LIST1 arg SEP COMMA -> l ] ];

arg: [ [ e = expr_no_comma -> e  ] ] ;

expr_no_comma: [ [
        me = member_expr ;
        mtropt = OPT [ COLON ; mtr = map_template_ref -> mtr ] ->
        let l = match mtropt with [ None -> [] | Some mtr -> [[mtr]] ] in
        (me, None, l)
    ] ]
;

expr_options: [ [
      l = LIST0 [ COMMA ; eo = expr_option -> eo ] ->  (l : list expr_option_t)
  ] ]
  ;

expr_option: [ [ id = ID ; EQUALS ; e = expr -> (id,e) ] ] ;

qualified_id: [ [
      rooted = FLAG SLASH ; id = ID ; l = LIST0 [ SLASH ; id = ID -> id] ->
      if rooted then QID_ROOTED [id::l] else QID [id::l]
  ] ]
  ;

ifstat: [ [
      
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
