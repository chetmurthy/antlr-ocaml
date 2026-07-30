(**pp -syntax camlp5r -package camlp5.extend *)

type action_t = [ ACTION of string ] ;
type sempred_t = [ SEMPRED of string ] ;
type arg_action_t = [ ARG_ACTION of string ] ;

value action2sempred = fun [ (ACTION a) -> SEMPRED a ] ;

type qualified_identifier_t = list string ;

type grammar_type = [ LEXER | PARSER ] ;
type option_value_t = [
    OPTION_ID of qualified_identifier_t
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
  | PQ_ACTION_ of (option action_scope_name * string * action_t)
  ]
;

type rule_prequel_t = [
    RPQ_OPTIONS of list option_t 
  | RPQ_RULEACTION of string and action_t
  ]
;

type rule_modifier_t = [
      RULE_PUBLIC
    | RULE_PRIVATE
    | RULE_PROTECTED
    | RULE_FRAGMENT
  ]
;

type element_option_value_t = [
    EOPTVAL_QID of qualified_identifier_t
  | EOPTVAL_STRING of string
  | EOPTVAL_INT of string
  ]
;
type element_option_t = [
    EOPT_QID of qualified_identifier_t
  | EOPT_ASSIGN of string and element_option_value_t
  ]
;
type element_options_t = list element_option_t ;

type predicate_option_value_t = [
    PREDOPT_EOPT of element_option_value_t
  | PREDOPT_ACTION of string and action_t
  | PREDOPT_INT of string and string
  | PREDOPT_STRING of string and string
  ]
;

type predicate_options_t = list predicate_option_value_t ;

type char_set_t = [
    CSET_LITERAL of string and option element_options_t
  | CSET_RANGE of string and string
  | CSET_ID of string and option element_options_t
  | CSET_CHARSET of string
  | CSET_NOT of char_set_t
  | CSET_BLOCK of list char_set_t
  ]
;
type terminal_def_t = [
    TD_ID of string and option element_options_t
  | TD_LITERAL of string and option element_options_t
  ]
;
type lexer_atom_t = [
    LATOM_RANGE of string and string
  | LATOM_TERMINAL of terminal_def_t
  | LATOM_NOTSET of char_set_t
  | LATOM_CHARSET of string
  | LATOM_WILDCARD of option element_options_t
  ]
;

type atom_t = [
    ATOM_TERMINAL of terminal_def_t
  | ATOM_RULEREF of string and option arg_action_t and option element_options_t
  | ATOM_NOTSET of char_set_t
  | ATOM_WILDCARD of option element_options_t
  ]
;

type ebnf_suffix_t = {
    plus : bool
  ; star : bool
  ; q : bool
  ; nongreedy : bool
  }
;

type element_t = [
    ELEM_LABELED of string and bool and element_t
  | ELEM_SUFFIX of element_t and ebnf_suffix_t
  | ELEM_SEMPRED of sempred_t and option predicate_options_t
  | ELEM_ACTION of action_t and option predicate_options_t
  | ELEM_BLOCK of option (option (list option_t) * list (string * action_t)) and list alternative_t
  | ELEM_ATOM of atom_t
  ]
and alternative_t = (option element_options_t * list element_t)
;

type lexer_command_arg_t = [
    LEXCMD_ID of string
  | LEXCMD_INT of string
  ]
;
 
type lexer_command_t = (string * option lexer_command_arg_t) ;
type labeled_alternative_t = (alternative_t * option string) ;

type lexer_element_t = [
    LEXELEM_ATOM of lexer_atom_t
  | LEXELEM_SUFFIX of lexer_element_t and ebnf_suffix_t
  | LEXELEM_ACTION of action_t
  | LEXELEM_SEMPRED of sempred_t and option predicate_options_t
  | LEXELEM_BLOCK of list lexer_alt_t
  ]
and lexer_alt_t = (option (list lexer_element_t) * option (list lexer_command_t))
;

type rule_spec_t = [
    RULESPEC_PARSER of {
      modifiers : option (list rule_modifier_t)
    ; name : string
    ; action : option arg_action_t
    ; returns : option arg_action_t
    ; throws : option (list qualified_identifier_t)
    ; locals : option arg_action_t
    ; rule_prequels : list rule_prequel_t
    ; rules : (list labeled_alternative_t)
    ; exception_group : (list (arg_action_t * action_t) * (option action_t))
    }
  | RULESPEC_LEXER of {
      fragment: bool
    ; name : string
    ; options :  option (list option_t)
    ; rules : list lexer_alt_t
    }
  ]
;

type grammar_t = {
    name : string
  ; type_ : grammar_type
  ; prequels : list prequel_t
  ; rules : list rule_spec_t
  ; modes : list (string * list rule_spec_t)
  ; filename : string
  } ;
