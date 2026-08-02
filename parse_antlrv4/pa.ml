(**pp -syntax camlp5r -package camlp5.extend *)

open Pa_ppx_utils ;
open Pa_ppx_located_yojson ;
open Grammar_types ;

value stream_npeek n s = (Stream.npeek n s : list (string * string)) ;

value lexer = {Plexing.tok_func = Camlp5_adapter.lexer;
 Plexing.tok_using _ = (); Plexing.tok_removing _ = ();
 Plexing.tok_match = Plexing.default_match;
 Plexing.tok_text = Plexing.lexer_text;
 Plexing.tok_comm = None ; Plexing.kwds = Hashtbl.create 23 } ;

value g = Grammar.gcreate lexer;
value grammar_spec = Grammar.Entry.create g "grammar_spec";
value grammar_decl = Grammar.Entry.create g "grammar_decl";
value prequel_construct = Grammar.Entry.create g "prequel_construct";
value options_spec = Grammar.Entry.create g "options_spec";
value delegate_grammars = Grammar.Entry.create g "delegate_grammars";
value tokens_spec = Grammar.Entry.create g "tokens_spec";
value channels_spec = Grammar.Entry.create g "channels_spec";
value action_ = Grammar.Entry.create g "action_";
value rules = Grammar.Entry.create g "rules";
value (element : Grammar.Entry.e element_t) = Grammar.Entry.create g "element";
value (element_options : Grammar.Entry.e element_options_t) = Grammar.Entry.create g "element_options";
value (element_option : Grammar.Entry.e element_option_t) = Grammar.Entry.create g "element_option";
value (alternative : Grammar.Entry.e alternative_t) = Grammar.Entry.create g "alternative";
value (alternative_eoi : Grammar.Entry.e alternative_t) = Grammar.Entry.create g "alternative_eoi";

value check_identifier_dot_f strm =
  match stream_npeek 2 strm with [
    [(("RULE_REF"|"TOKEN_REF"), _); ("", ".")] -> ()
  | _ -> raise Stream.Failure
  ]
;

value check_identifier_dot =
  Grammar.Entry.of_parser g "check_identifier_dot"
    check_identifier_dot_f
;

value check_identifier_asgop_f strm =
  match stream_npeek 2 strm with [
    [(("RULE_REF"|"TOKEN_REF"), _); ("", ("="|"+="))] -> ()
  | _ -> raise Stream.Failure
  ]
;

value check_identifier_asgop =
  Grammar.Entry.of_parser g "check_identifier_asgop"
    check_identifier_asgop_f
;

value check_identifier_not_assign_f strm =
  match stream_npeek 2 strm with [
    [(("RULE_REF"|"TOKEN_REF"), _); ("", "=")] -> raise Stream.Failure
  | _ -> ()
  ]
;

value check_identifier_not_assign =
  Grammar.Entry.of_parser g "check_identifier_not_assign"
    check_identifier_not_assign_f
;

value check_rule_modifiers_uid_f strm =
  let rec checkrec n =
    let l = stream_npeek n strm in
    if List.length l < n then raise Stream.Failure else
    let last = Std.last l in
    match last with [
        ("TOKEN_REF", _) -> ()
      | ("",("fragment"|"public"|"private"|"protected")) -> checkrec (n+1)
      | _ -> raise Stream.Failure
      ]
  in checkrec 1
;

value check_rule_modifiers_uid =
  Grammar.Entry.of_parser g "check_rule_modifiers_uid"
    check_rule_modifiers_uid_f
;

value check_rule_modifiers_lid_f strm =
  let rec checkrec n =
    let l = stream_npeek n strm in
    if List.length l < n then raise Stream.Failure else
    let last = Std.last l in
    match last with [
        ("RULE_REF", _) -> ()
      | ("",("fragment"|"public"|"private"|"protected")) -> checkrec (n+1)
      | _ -> raise Stream.Failure
      ]
  in checkrec 1
;

value check_rule_modifiers_lid =
  Grammar.Entry.of_parser g "check_rule_modifiers_lid"
    check_rule_modifiers_lid_f
;

value check_asn_coloncolon_f strm =
  match stream_npeek 2 strm with [
    [((("RULE_REF"|"TOKEN_REF"), _)|(_,("lexer"|"parser"))); ("", "::")] -> ()
  | _ -> raise Stream.Failure
  ]
;

value check_asn_coloncolon =
  Grammar.Entry.of_parser g "check_asn_coloncolon"
    check_asn_coloncolon_f
;

value check_string_not_dotdot_f strm =
  match stream_npeek 2 strm with [
    [("STRING_LITERAL", _); ("", "..")] -> raise Stream.Failure
  | _ -> ()
  ]
;

value check_string_not_dotdot =
  Grammar.Entry.of_parser g "check_string_not_dotdot"
    check_string_not_dotdot_f
;

EXTEND
  GLOBAL: grammar_spec grammar_decl
          prequel_construct options_spec delegate_grammars tokens_spec channels_spec action_
          rules
          check_identifier_dot
          check_identifier_not_assign
          check_rule_modifiers_uid
          check_rule_modifiers_lid
          check_identifier_asgop
          check_asn_coloncolon
          check_string_not_dotdot
          element
          element_options
          element_option
          alternative alternative_eoi
;
  alternative_eoi: [ [ x = alternative ; EOI -> x ] ] ;

  grammar_spec: [ [
      (name, d) = grammar_decl ;
      l = LIST0 prequel_construct ;
      rl = rules ;
      ml = LIST0 mode_spec ;
      EOI ->
      let filename = Ploc.file_name loc in
      {name = name; type_= d; prequels=l; rules=rl; modes=ml; filename = filename}
    ] ]
  ;
  grammar_decl: [ [
      ty = grammar_type ;
      "grammar" ;
      name = identifier ;
      ";" -> (name, ty)
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
  option: [ [ id = identifier ; "=" ; v = option_value -> (id, v) ] ] ;
  option_value: [ [
      l = qualified_identifier -> OPTION_ID l
    | s = STRING_LITERAL -> OPTION_STRING s
    | a = ACTION -> OPTION_ACTION a
    | n = INT -> OPTION_INT n
  ] ] ;

  delegate_grammars: [ [ "import" ; l = LIST1 delegate_grammar SEP "," ; ";" -> l ] ];
  delegate_grammar: [ [ id = identifier -> (id, None)
                      | id = identifier ; "=" ; id2 = identifier -> (id, Some id2) ] ];

tokens_spec: [ [ TOKENS ; l = OPT id_list ; "}" ->
     (match l with [ None -> [] | Some l -> l ]) ] ] ;

channels_spec: [ [ CHANNELS ; l = OPT id_list ; "}" ->
     (match l with [ None -> [] | Some l -> l ]) ] ] ;

id_list: [ [ l = LIST1 identifier SEP "," ; OPT "," -> l ] ] ;

action_: [ [ "@" ; sname_opt = OPT [ check_asn_coloncolon ; sname = action_scope_name ; "::" -> sname ] ;
             id = identifier ; a = ACTION -> (sname_opt, id, ACTION a) ] ] ;

action_scope_name: [ [ id = identifier -> ASN_ID id | gt = grammar_type -> ASN_GRAMMAR gt ] ];

action_block: [ [ a = ACTION -> ACTION a ] ] ;

arg_action_block: [ [
    "[" ; l = LIST0 ARGUMENT_CONTENT ; END_ARGUMENT  -> ARG_ACTION l
(*
    x = LEXER_CHAR_SET  -> ARG_ACTION x
 *)
  ] ]
;

mode_spec: [ [
      "mode" ;  id = identifier ; ";" ;  l = LIST0 lexer_rule_spec -> (id, l)
  ] ]
;

rules: [ [ l = LIST0 rule_spec -> l ] ] ;


rule_spec: [ [
      pr = parser_rule_spec -> pr
    | lr = lexer_rule_spec -> lr
  ] ]
;

parser_rule_spec: [ [
      check_rule_modifiers_lid ;
      rml = OPT rule_modifiers ; id = RULE_REF ; action_opt = OPT arg_action_block ;
      returns_opt = OPT rule_returns ;
      throws_opt = OPT throws_spec ;
      locals_opt = OPT locals_spec ;
      rpl = LIST0 rule_prequel ;
      ":" ; b = rule_block ; ";" ; eg = exception_group
      -> RULESPEC_PARSER {
             modifiers=rml
           ; name=id
           ; action=action_opt
           ; returns=returns_opt
           ; throws=throws_opt
           ; locals=locals_opt
           ; rule_prequels=rpl
           ; rules=b
           ; exception_group=eg
           }
  ] ]
;

exception_group: [ [
      l = LIST0 exception_handler ; fc = OPT finally_clause -> (l, fc)
  ] ]
;

exception_handler: [ [
      "catch" ;  aab = arg_action_block ;  a = action_block -> (aab, a)
  ] ]
;

finally_clause: [ [ "finally" ; a = action_block -> a ] ] ;

rule_prequel: [ [
    l = options_spec -> RPQ_OPTIONS l
  | (id, a) = rule_action -> RPQ_RULEACTION id a
  ] ]
;

rule_returns: [ [ "returns" ; a = arg_action_block -> a ] ] ;

throws_spec: [ [
    "throws" ; l = LIST1 qualified_identifier SEP "," -> l
  ] ]
;

locals_spec: [ [ "locals" ; a = arg_action_block -> a ] ] ;

rule_action: [ [ "@" ; id = identifier ; a = action_block -> (id, a) ] ] ;

rule_modifiers: [ [ l = LIST1 rule_modifier -> l ] ] ;

rule_modifier: [ [
    "public" -> RULE_PUBLIC
  | "private" -> RULE_PRIVATE
  | "protected" -> RULE_PROTECTED
  | "fragment" -> RULE_FRAGMENT
  ] ]
;

rule_block: [ [ l = rule_alt_list -> l ] ] ;

rule_alt_list: [ [ l = LIST1 labeled_alt SEP "|" -> l ] ] ;

labeled_alt: [ [
    a = alternative ; id_opt = OPT [ "#" ; id = identifier -> id ] -> (a,id_opt)
  ] ]
;

lexer_rule_spec: [ [
      check_rule_modifiers_uid ;
      frag = FLAG "fragment" ;
      uid = TOKEN_REF ;
      opts = OPT options_spec ; ":" ;
      rb = lexer_rule_block ; ";"
      -> RULESPEC_LEXER {
             fragment=frag
           ; name=uid
           ; options=opts
           ; rules=rb
           }
  ] ]
;

lexer_rule_block: [ [ l = lexer_alt_list -> l ] ]  ;

lexer_alt_list: [ [ l = LIST1 lexer_alt SEP "|" -> l ] ] ;

lexer_alt: [ [
      l_opt = lexer_elements ; cmds_opt = OPT lexer_commands -> (l_opt, cmds_opt)
  ] ]
;

lexer_elements: [ [ l = LIST1 lexer_element -> Some l | -> None ] ] ;

lexer_element: [ [
      e = lexer_atom ; suff = OPT ebnf_suffix ->
      (match suff with [ None -> (LEXELEM_ATOM e) | Some suff -> LEXELEM_SUFFIX (LEXELEM_ATOM e) suff ])
    | e = lexer_block; suff = OPT ebnf_suffix ->
      (match suff with [ None -> e | Some suff -> LEXELEM_SUFFIX e suff ])
    | a = action_block ; ispred = FLAG "?" ; popt = OPT predicate_options ->
       (if ispred then
         LEXELEM_SEMPRED (action2sempred a) popt
       else do {
          assert (Std.isNone popt) ;
          LEXELEM_ACTION a
       })
  ] ]
;

lexer_block: [ [ "(" ; l = lexer_alt_list ; ")" -> LEXELEM_BLOCK l ] ] ;

lexer_commands: [ [
      "->" ; l = LIST1 lexer_command SEP "," -> l
  ] ]
;

lexer_command: [ [
      n = lexer_command_name ; "(" ; e = lexer_command_expr ; ")" -> (n, Some e)
    | n = lexer_command_name -> (n, None)
  ] ]
;

lexer_command_name: [ [
      id = identifier -> id
    | "mode" -> "mode"
  ] ]
;

lexer_command_expr: [ [
      id = identifier -> LEXCMD_ID id
    | n = INT -> LEXCMD_INT n
  ] ]
;

alt_list: [ [ l = LIST1 alternative SEP "|" -> l ] ] ;

alternative: [ [
      e = element_options ; l = LIST1 element -> (Some e, l)
    | l = LIST1 element -> (None, l)
    | -> (None, [])
  ] ]
;

element: [ [
        check_identifier_asgop ;
        e = labeled_element ; suff = ebnf_suffix_question ->
            (match suff with [ None -> e | Some suff -> ELEM_SUFFIX e suff ])
      | e = atom ; suff = ebnf_suffix_question ->
            (match suff with [ None -> (ELEM_ATOM e) | Some suff -> ELEM_SUFFIX (ELEM_ATOM e) suff ])
      | (e, suff) = ebnf ->
            (match suff with [ None -> e | Some suff -> ELEM_SUFFIX e suff ])
      | a = action_block ; qflag = FLAG "?" ; popt = OPT predicate_options ->
         (if qflag then
           ELEM_SEMPRED (action2sempred a) popt
         else ELEM_ACTION a popt)
    ] ]
  ;

predicate_options: [ [ "<" ;  l = LIST1 predicate_option SEP "," ; ">" -> l ] ] ;

predicate_option: [ [
      check_identifier_not_assign ;
      eov = element_option_value -> PREDOPT_EOPT eov
    | id = identifier; "="; a = action_block -> PREDOPT_ACTION id a
    | id = identifier; "="; n = INT -> PREDOPT_INT id n
    | id = identifier; "="; s = STRING_LITERAL -> PREDOPT_STRING id s
  ] ]
;

labeled_element: [ [
      id = identifier ; asg = [ "=" -> False | "+=" -> True ] ; a = atom -> ELEM_LABELED id asg (ELEM_ATOM a)
    | id = identifier ; asg = [ "=" -> False | "+=" -> True ] ; b = block -> ELEM_LABELED id asg b
  ] ]
;

ebnf: [ [ b = block ; sopt = OPT block_suffix -> (b,sopt) ] ] ;

block_suffix: [ [ s = ebnf_suffix -> s ] ] ;

ebnf_suffix_question: [ [
      suff = ebnf_suffix -> Some suff
    | -> None
    ] ]
;

ebnf_suffix: [ [
      "?" ; f = FLAG "?" -> {q=True; star=False;plus=False; nongreedy=f}
    | "*" ; f = FLAG "?" -> {q=False; star=True;plus=False; nongreedy=f}
    | "+" ; f = FLAG "?" -> {q=False; star=False;plus=True; nongreedy=f}
    ] ]
  ;

lexer_atom: [ [
      (s1, s2) = character_range -> LATOM_RANGE s1 s2
    | td = terminal_def -> LATOM_TERMINAL td
    | b = not_set -> LATOM_NOTSET b
    | cs = LEXER_CHAR_SET -> LATOM_CHARSET cs
    | w = wildcard -> LATOM_WILDCARD w
    ] ]
;

atom: [ [
      t = terminal_def -> ATOM_TERMINAL t
    | (id, aopt, eopt) = rule_ref -> ATOM_RULEREF id aopt eopt
    | b = not_set  -> ATOM_NOTSET b
    | w = wildcard ->  ATOM_WILDCARD w
    ] ]
;

wildcard: [ [ "." ; eopt = OPT element_options -> eopt ] ] ;

not_set: [ [
      "~" ; t = set_element -> CSET_NOT t
    | "~" ; t = block_set -> CSET_NOT t
    ] ]
;

block_set: [ [
      "(" ; l = LIST1 set_element SEP "|"; ")" -> CSET_BLOCK l
    ] ]
;

set_element: [ [
      id = TOKEN_REF ; e_opt = OPT element_options -> CSET_ID id e_opt
    | check_string_not_dotdot ;
      s = STRING_LITERAL ; e_opt = OPT element_options -> CSET_LITERAL s e_opt
    | (s1,s2) = character_range -> CSET_RANGE s1 s2
    | t = LEXER_CHAR_SET -> CSET_CHARSET t
  ] ]
  ;

block: [ [
        "(" ; x = OPT [ opts = OPT options_spec ; l = LIST0 rule_action ; ":" -> (opts, l) ] ;
        l = alt_list ; ")" -> ELEM_BLOCK x l
    ] ]
  ;

rule_ref: [ [
      id = RULE_REF ;  action_opt = OPT arg_action_block ; e_opt = OPT element_options
      -> (id, action_opt, e_opt)
  ] ]
  ;

character_range: [ [
        s1 = STRING_LITERAL ; ".." ; s2 = STRING_LITERAL -> (s1, s2)
    ] ]
  ;

terminal_def: [ [
      id = TOKEN_REF ; eopt = OPT element_options -> (TD_ID id eopt)
    | s = STRING_LITERAL ; eopt = OPT element_options -> (TD_LITERAL s eopt)
  ] ]
;


element_options: [ [
        "<" ; l = LIST1 element_option SEP "," ; ">" -> l
    ] ]
  ;

element_option: [ [
      check_identifier_not_assign ; qid = qualified_identifier -> EOPT_QID qid
    | id = identifier ; "=" ; v = element_option_value -> EOPT_ASSIGN id v
  ] ]
;

element_option_value: [ [
      qid = qualified_identifier -> EOPTVAL_QID qid
    | s = STRING_LITERAL -> EOPTVAL_STRING s
    | n = INT -> EOPTVAL_INT n
  ] ]
;

identifier: [ [ id = RULE_REF -> id | id = TOKEN_REF -> id ] ] ;

qualified_identifier: [ [ l = LIST1 identifier SEP "." -> l ] ] ;

END ;

module Grammar = Pa_json.PAHelper(struct
                     type t = grammar_t ;
                     value entry = grammar_spec ;
                   end) ;


module Alternative = Pa_json.PAHelper(struct
                     type t = alternative_t ;
                     value entry = alternative_eoi ;
                   end) ;

