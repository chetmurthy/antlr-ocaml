(**pp -syntax camlp5o -package pa_ppx_regexp *)

type qualified_id_t =
  QID_ROOTED of string list
| QID of string list

type include_expr_arg_t =
  IEARG_ID of string
| IEARG_EXPR of map_expr_t

and include_expr_t =
  EXEC_FUNC of string * expr_t option
| INCLUDE_SUPER of string * args_t
| INCLUDE of qualified_id_t * args_t
| INCLUDE_SUPER_REGION of string
| INCLUDE_REGION of string
| INCLUDE_PRIMARY of primary_t

and args_t =
  ARGS_LIST of arg_expr_list_t
| ARGS_NAMED of named_arg_t list * bool
| ARGS_EMPTY

and arg_expr_list_t = expr_t list

and named_arg_t = string * expr_t

and expr_t = map_expr_t

and map_template_ref_t =
  MT_INCLUDE of qualified_id_t * args_t
| MT_SUB of subtemplate_t
| MT_INCLUDE_IND of map_expr_t * expr_t list

and subtemplate_t =
  string list * elements_t

and primary_t =
  PRIMARY_ID of string
| PRIMARY_STRING of string
| PRIMARY_BOOL of bool
| PRIMARY_SUBTEMPLATE of subtemplate_t
| PRIMARY_LIST of arg_expr_list_t option
| PRIMARY_CONDITIONAL of conditional_t
| PRIMARY_INCLUDE_IND of expr_t * arg_expr_list_t option

and conditional_t =
  OR of conditional_t list
| AND of conditional_t list
| NOT of conditional_t
| ATOM of member_expr_t

and member_expr_t =
  include_expr_t * include_expr_arg_t list

and map_expr_t =
  member_expr_t
  * (member_expr_t list * map_template_ref_t) option
  * map_template_ref_t list list

and expr_tag_t =
  map_expr_t * expr_option_t list

and expr_options_t = expr_option_t list

and expr_option_t = string * expr_t

and element_t =
  TEXT of string
| HORZ_WS of string
| VERT_WS of string
| EXPR_TAG of expr_tag_t
| IFSTAT of conditional_t * elements_t * (conditional_t * elements_t) list * elements_t option
| REGION of string * elements_t

and elements_t = element_t list

and template_t = elements_t

let coalesce1 (l : template_t) : template_t =
  let finish_stracc tacc stracc =
    match stracc with
      [] -> tacc
    | strl ->
       let s = String.concat "" (List.rev strl) in
        (TEXT s)::tacc in

  let rec corec tacc stracc = function
      [] ->
       let tacc = finish_stracc tacc stracc in
       List.rev tacc
    | (TEXT s)::l -> corec tacc (s::stracc) l
    | h::l ->
       let tacc = finish_stracc tacc stracc in
       corec (h::tacc) [] l
  in
  corec [] [] l

