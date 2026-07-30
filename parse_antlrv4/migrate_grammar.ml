(**pp -syntax camlp5o -package pa_ppx.import,pa_ppx_migrate,camlp5.extfun,camlp5.parser_quotations,pa_ppx_q_ast.lreval *)


exception Migration_error of string

let migration_error feature =
  raise (Migration_error feature)

let mapLR f l =
  let rec mrec = function
      [] -> []
    | h::t ->
       let fh = f h in
       let ft = mrec t in
       fh::ft
  in mrec l

let _migrate_list subrw0 __dt__ l =
  mapLR (subrw0 __dt__) l

[%%typedecls
  [%%import: Grammar_types.action_scope_name]
  [%%import: Grammar_types.action_t]
  [%%import: Grammar_types.alternative_t]
  [%%import: Grammar_types.arg_action_t]
  [%%import: Grammar_types.atom_t]
  [%%import: Grammar_types.char_set_t]
  [%%import: Grammar_types.delegate_grammar_t]
  [%%import: Grammar_types.ebnf_suffix_t]
  [%%import: Grammar_types.element_options_t]
  [%%import: Grammar_types.element_option_t]
  [%%import: Grammar_types.element_option_value_t]
  [%%import: Grammar_types.grammar_t]
  [%%import: Grammar_types.grammar_type]
  [%%import: Grammar_types.labeled_alternative_t]
  [%%import: Grammar_types.lexer_alt_t]
  [%%import: Grammar_types.lexer_atom_t]
  [%%import: Grammar_types.lexer_command_arg_t]
  [%%import: Grammar_types.lexer_command_t]
  [%%import: Grammar_types.option_t]
  [%%import: Grammar_types.option_value_t]
  [%%import: Grammar_types.predicate_options_t]
  [%%import: Grammar_types.predicate_option_value_t]
  [%%import: Grammar_types.prequel_t]
  [%%import: Grammar_types.qualified_identifier_t]
  [%%import: Grammar_types.rule_modifier_t]
  [%%import: Grammar_types.rule_prequel_t]
  [%%import: Grammar_types.rule_spec_t]
  [%%import: Grammar_types.sempred_t]
  [%%import: Grammar_types.terminal_def_t]
]
[@@deriving migrate
    { dispatch_type = dispatch_table_t
    ; dispatch_table_constructor = make_dt
    ; default_dispatchers = [
        {
          srcmod = Grammar_types
        ; dstmod = Grammar_types
        ; types = [
            action_scope_name
          ; action_t
          ; alternative_t
          ; arg_action_t
          ; atom_t
          ; char_set_t
          ; delegate_grammar_t
          ; ebnf_suffix_t
          ; element_options_t
          ; element_option_t
          ; element_option_value_t
          ; element_t
          ; grammar_t
          ; grammar_type
          ; labeled_alternative_t
          ; lexer_alt_t
          ; lexer_atom_t
          ; lexer_command_arg_t
          ; lexer_command_t
          ; lexer_element_t
          ; option_t
          ; option_value_t
          ; predicate_options_t
          ; predicate_option_value_t
          ; prequel_t
          ; qualified_identifier_t
          ; rule_modifier_t
          ; rule_prequel_t
          ; rule_spec_t
          ; sempred_t
          ; terminal_def_t
          ]
        }
      ]
    ; dispatchers = {
        migrate_list = {
          srctype = [%typ: 'a list]
        ; dsttype = [%typ: 'b list]
        ; code = _migrate_list
        ; subs = [ ([%typ: 'a], [%typ: 'b]) ]
        }
      ; migrate_option = {
          srctype = [%typ: 'a option]
        ; dsttype = [%typ: 'b option]
        ; subs = [ ([%typ: 'a], [%typ: 'b]) ]
        ; code = (fun subrw __dt__ x -> Option.map (subrw __dt__) x)
        }
      }
    }
]

