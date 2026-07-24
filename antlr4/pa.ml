(**pp -syntax camlp5r -package camlp5.extend *)

value lexer = {Plexing.tok_func = Camlp5_adapter.lexer;
 Plexing.tok_using _ = (); Plexing.tok_removing _ = ();
 Plexing.tok_match = Plexing.default_match;
 Plexing.tok_text = Plexing.lexer_text;
 Plexing.tok_comm = None ; Plexing.kwds = Hashtbl.create 23 } ;

type grammar_type = [ LEXER | PARSER ] ;
type option_value = [
    OPTION_ID of string and list string
  | OPTION_STRING of string
  | OPTION_ACTION of string
  | OPTION_INT of string
  ]
;

value g = Grammar.gcreate lexer;
value grammar = Grammar.Entry.create g "grammar";
value options_spec = Grammar.Entry.create g "options_spec";
value delegate_grammars = Grammar.Entry.create g "delegate_grammars";
value tokens_spec = Grammar.Entry.create g "tokens_spec";
value channels_spec = Grammar.Entry.create g "channels_spec";

EXTEND
  GLOBAL: grammar options_spec delegate_grammars tokens_spec channels_spec ;
  grammar: [ [
      ty = [ "lexer" -> LEXER | "parser" -> PARSER | -> PARSER ] ;
      "grammar" ;
      name = ID ;
      ";" -> ty
  ] ] ;

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


END ;

