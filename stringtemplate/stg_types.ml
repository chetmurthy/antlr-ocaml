
type template_rhs_t =
  TDEF_STRING of string
| TDEF_BIGSTRING of string
| TDEF_BIGSTRING_NO_NL of string

type formal_arg_default_t =
  FORMAL_STRING of string
| FORMAL_ANON_TEMPLATE of string
| FORMAL_BOOL of bool
| FORMAL_MT_DICT

type formal_arg_t =
  string * formal_arg_default_t option

type template_t =
  TEMPLATE_DEF of string * formal_arg_t list * template_rhs_t
| TEMPLATE_ALIAS of string * string

type key_value_t =
  KEYVAL_BIGSTRING of string
| KEYVAL_BIGSTRING_NO_NL of string
| KEYVAL_ANON_TEMPLATE of string
| KEYVAL_STRING of string
| KEYVAL_BOOL of bool
| KEYVAL_MT_DICT
| KEYVAL_KEY

type dict_t =
  string * ((string * key_value_t) list * key_value_t option)

type group_def_t =
  GROUPDEF_TEMPLATE of template_t
| GROUPDEF_DICT of dict_t

type header_t = {
    name : string * string option
  ; implements : (string * string option) option
  }

type group_t = {
    header : header_t option
  ; imports : string list
  ; defs : group_def_t list
  }
