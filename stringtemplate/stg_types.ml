(**pp -syntax camlp5o -package pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.yojson,pa_ppx.deriving_plugins.located_yojson,pa_ppx.deriving_plugins.located_sexp,pa_ppx.utils *)

open Pa_ppx_utils
open Coll

open St_util

module Raw = struct
type template_rhs_t =
  TDEF_STRING of string located
| TDEF_BIGSTRING of string located
| TDEF_BIGSTRING_NO_NL of string located

type formal_arg_default_t =
  FORMAL_STRING of string located
| FORMAL_SUBTEMPLATE of Sttypes2.subtemplate_t
| FORMAL_BOOL of bool
| FORMAL_MT_DICT

type formal_arg_t =
  string * formal_arg_default_t option

type key_value_t =
  KEYVAL_BIGSTRING of string located
| KEYVAL_BIGSTRING_NO_NL of string located
| KEYVAL_SUBTEMPLATE of Sttypes2.subtemplate_t
| KEYVAL_STRING of string located
| KEYVAL_BOOL of bool
| KEYVAL_MT_DICT
| KEYVAL_KEY

type dict_t =
  string * ((string located * key_value_t) list * key_value_t option)

type group_def_t =
  GROUPDEF_TEMPLATE_DEF of Ploc.t * string * formal_arg_t list * template_rhs_t
| GROUPDEF_TEMPLATE_ALIAS of Ploc.t * string * string
| GROUPDEF_DICT of Ploc.t * dict_t

type header_t = {
    name : string * string option
  ; implements : (string * string option) option
  }

type group_t = {
    loc : Ploc.t
  ; filename : Fpath.t
  ; header : header_t option
  ; imports : string list
  ; defs : group_def_t list
  }
end

module Cooked = struct

type value_t =
  VALUE_TEMPLATE of Sttypes2.template_t
| VALUE_SUBTEMPLATE of Sttypes2.subtemplate_t
| VALUE_BOOL of bool
| VALUE_MT_DICT

type template_def_t =
  {
    loc : Ploc.t
  ; name : string
  ; formals : (string * value_t option) list
  ; body : Sttypes2.template_t
  }

type dict_val_t =
  DVAL_VALUE of value_t
| DVAL_KEY


type dict_t =
  {
    loc : Ploc.t
  ; kv : (string, dict_val_t) LM.t
  ; default : dict_val_t option
  }

end
