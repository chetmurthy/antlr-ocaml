(**pp -syntax camlp5o -package pa_ppx_regexp *)

type qualified_id_t =
  { rooted : bool ; ids : string list }

type mexpr_t =
  ME_MAP of mexpr_t * mexpr_template_ref_t (* : *)
| ME_CAT of mexpr_t * mexpr_t (* , *)
| ME_TEMPLATE of mexpr_template_ref_t
| ME_PRIMARY of mexpr_primary_t
| ME_PROP of mexpr_t * string
| ME_PROP_IND of mexpr_t * mexpr_t

and mexpr_template_ref_t =
  ME_INCLUDE of qualified_id_t * args_t
| ME_SUB of subtemplate_t
| ME_INCLUDE_IND of mexpr_t * mexpr_t list

and mexpr_primary_t =
  ME_ID of string
| ME_STRING of string
| ME_BOOL of bool
| ME_LIST of mexpr_t option list
| ME_COND of mexpr_cond_t

and mexpr_cond_t =
  COND_ATOM of mexpr_t
| COND_NOT of mexpr_cond_t
| COND_AND of mexpr_cond_t * mexpr_cond_t
| COND_OR of mexpr_cond_t * mexpr_cond_t

and args_t =
  ARGS_LIST of mexpr_t list
| ARGS_NAMED of (string * mexpr_t) list * bool
| ARGS_EMPTY

and subtemplate_t =
  string list * elements_t

and element_t =
  TEXT of string
| HORZ_WS of string
| VERT_WS of string
| EXPR_TAG of expr_tag_t
| IFSTAT of mexpr_cond_t * elements_t * (mexpr_cond_t * elements_t) list * elements_t option
| REGION of string * elements_t

and elements_t = element_t list

and template_t = elements_t

and expr_tag_t =
  mexpr_t * (string * mexpr_t) list
