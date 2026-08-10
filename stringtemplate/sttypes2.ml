(**pp -syntax camlp5o -package pa_ppx_regexp *)

type qualified_id_t =
  { rooted : bool ; ids : string list }

type mexp_t =
  ME_MAP of mexp_t * mexp_template_ref_t (* : *)
| ME_CAT of mexp_t * mexp_t (* , *)
| ME_TEMPLATE of mexp_template_ref_t
| ME_PRIMARY of mexp_primary_t
| ME_PROP of mexp_t * string
| ME_PROP_IND of mexp_t * mexp_t

and mexp_template_ref_t =
  ME_INCLUDE of qualified_id_t * args_t
| ME_SUB of subtemplate_t
| ME_INCLUDE_IND of mexp_t * mexp_t list

and mexp_primary_t =
  ME_ID of string
| ME_STRING of string
| ME_BOOL of bool
| ME_LIST of mexp_t option list
| ME_COND of mexp_cond_t

and mexp_cond_t =
  COND_ATOM of mexp_t
| COND_NOT of mexp_cond_t
| COND_AND of mexp_cond_t * mexp_cond_t
| COND_OR of mexp_cond_t * mexp_cond_t

and args_t =
  ARGS_LIST of mexp_t list
| ARGS_NAMED of (string * mexp_t) list * bool
| ARGS_EMPTY

and subtemplate_t =
  string list * elements_t

and element_t =
  TEXT of string
| HORZ_WS of string
| VERT_WS of string
| EXPR_TAG of expr_tag_t
| IFSTAT of mexp_cond_t * elements_t * (mexp_cond_t * elements_t) list * elements_t option
| REGION of string * elements_t

and elements_t = element_t list

and template_t = elements_t

and expr_tag_t =
  mexp_t * (string * mexp_t) list
