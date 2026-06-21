(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.utils,pa_ppx.deriving_plugins.std,pa_ppx.import *)

type expr_t =
  VAR of string
| NOT of expr_t

type stg_t =
  TEXT of string
| IFTHEN of expr_t * stg_t list * stg_t list
| ATTRIBUTE of string
| INCLUDE of string * string list
