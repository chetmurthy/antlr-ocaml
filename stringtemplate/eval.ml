(**pp -syntax camlp5o -package pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.yojson,pa_ppx.deriving_plugins.located_yojson,pa_ppx.deriving_plugins.located_sexp,pa_ppx.utils *)

open Pa_ppx_utils
open St_types

module Value = struct
type t =
  STRING of string
| BOOL of bool
| DICT of (string * t) list
| LIST of t list
| NULL
[@@deriving show,yojson,located_yojson {exn = true},located_sexp {exn=true}]
end

module Environ = struct
type frame_t = (string * Value.t) list
[@@deriving show,yojson,located_yojson {exn = true},located_sexp {exn=true}]
type t = frame_t list
[@@deriving show,yojson,located_yojson {exn = true},located_sexp {exn=true}]
end

