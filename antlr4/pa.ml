(**pp -syntax camlp5r -package camlp5.extend *)

value lexer = {Plexing.tok_func = Camlp5_adapter.lexer;
 Plexing.tok_using _ = (); Plexing.tok_removing _ = ();
 Plexing.tok_match = Plexing.default_match;
 Plexing.tok_text = Plexing.lexer_text;
 Plexing.tok_comm = None ; Plexing.kwds = Hashtbl.create 23 } ;

type grammar_type = [ LEXER | PARSER ] ;
type option_value_t = [
    OPTION_ID of string and list string
  | OPTION_STRING of string
  | OPTION_ACTION of string
  | OPTION_INT of string
  ]
;
type option_t = (string * option_value_t) ;

type delegate_grammar_t = (string * option string) ;

type action_scope_name = [ ASN_ID of string | ASN_GRAMMAR of grammar_type ];

type prequel_t = [
    PQ_OPTIONS of list option_t 
  | PQ_DELEGATE_GRAMMARS of list delegate_grammar_t
  | PQ_TOKENS_SPEC of list string
  | PQ_CHANNELS_SPEC of list string
  | PQ_ACTION_ of (option action_scope_name * string * string)
  ]
;

value g = Grammar.gcreate lexer;
value grammar_spec = Grammar.Entry.create g "grammar_spec";
value grammar_decl = Grammar.Entry.create g "grammar_decl";
value prequel_construct = Grammar.Entry.create g "prequel_construct";
value options_spec = Grammar.Entry.create g "options_spec";
value delegate_grammars = Grammar.Entry.create g "delegate_grammars";
value tokens_spec = Grammar.Entry.create g "tokens_spec";
value channels_spec = Grammar.Entry.create g "channels_spec";
value action_ = Grammar.Entry.create g "action_";
value rule = Grammar.Entry.create g "rule_";

EXTEND
  GLOBAL: grammar_spec grammar_decl
          prequel_construct options_spec delegate_grammars tokens_spec channels_spec action_
          rule
  ;
  grammar_spec: [ [
      d = grammar_decl ;
      l = LIST0 prequel_construct -> (d,l)
    ] ]
  ;
  grammar_decl: [ [
      ty = grammar_type ;
      "grammar" ;
      name = ID ;
      ";" -> ty
  ] ] ;
  grammar_type: [ [ "lexer" -> LEXER | "parser" -> PARSER | -> PARSER ] ] ;

  prequel_construct: [ [
      l = options_spec -> PQ_OPTIONS l
    | l = delegate_grammars -> PQ_DELEGATE_GRAMMARS l
    | l = tokens_spec -> PQ_TOKENS_SPEC l
    | l = channels_spec -> PQ_CHANNELS_SPEC l
    | a = action_ -> PQ_ACTION_ a
    ] ]
  ;
  options_spec: [ [ OPTIONS ; l = LIST0 [ x = option ; ";" -> x ] ; "}" -> l ] ] ;
  option: [ [ id = ID ; "=" ; v = option_value -> (id, v) ] ] ;
  option_value: [ [
      id = ID ; l = LIST0 [ "." ; id=ID -> id ] -> OPTION_ID id l
    | s = STRING_LITERAL -> OPTION_STRING s
    | a = ACTION -> OPTION_ACTION a
    | n = INT -> OPTION_INT n
  ] ] ;

  delegate_grammars: [ [ "import" ; l = LIST1 delegate_grammar SEP "," ; ";" -> l ] ];
  delegate_grammar: [ [ id = ID -> (id, None) | id = ID ; "=" ; id2 = ID -> (id, Some id2) ] ];

  tokens_spec: [ [ TOKENS ; l = OPT id_list ; "}" -> (match l with [ None -> [] | Some l -> l ]) ] ] ;
  id_list: [ [ l = LIST1 ID SEP "," ; OPT "," -> l ] ] ;

  channels_spec: [ [ CHANNELS ; l = OPT id_list ; "}" -> (match l with [ None -> [] | Some l -> l ]) ] ] ;

  action_: [ [ "@" ; sname_opt = OPT [ sname = action_scope_name ; "::" -> sname ] ;
               id = ID ; a = ACTION -> (sname_opt, id, a) ] ] ;

  action_scope_name: [ [ id = ID -> ASN_ID id | gt = grammar_type -> ASN_GRAMMAR gt ] ];


  rule: [ [
      fragment_p = FLAG "fragment" -> fragment_p
    ] ]
  ;

END ;

