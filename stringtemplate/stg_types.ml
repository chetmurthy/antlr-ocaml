(**pp -syntax camlp5o -package pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.yojson,pa_ppx.deriving_plugins.located_yojson,pa_ppx.deriving_plugins.located_sexp,pa_ppx.utils *)

open Pa_ppx_utils

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

type stg_template_t =
  TEMPLATE_DEF of string * formal_arg_t list * template_rhs_t
| TEMPLATE_ALIAS of string * string

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
  GROUPDEF_TEMPLATE of stg_template_t
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
end

module Cooked = struct

open Coll

type value_t =
  VALUE_TEMPLATE of Sttypes2.template_t
| VALUE_SUBTEMPLATE of Sttypes2.subtemplate_t
| VALUE_BOOL of bool
| VALUE_MT_DICT

type template_def_t =
  {
    name : string
  ; formals : (string * value_t option) list
  ; body : Sttypes2.template_t
  }

type dict_val_t =
  DVAL_VALUE of value_t
| DVAL_KEY


type dict_t =
  {
    kv : (string, dict_val_t) MHM.t
  ; default : dict_val_t option
  }

type group_t = {
    header : Raw.header_t option
  ; imports : string list
  ; templates : (string, template_def_t) MHM.t
  ; dicts : (string, dict_t) MHM.t
  }

type groupdir_t = {
    groups : (string, group_t) MHM.t
  }
end
