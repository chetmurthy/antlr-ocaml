(**pp -syntax camlp5o -package pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.yojson,pa_ppx.deriving_plugins.located_yojson,pa_ppx.deriving_plugins.located_sexp,pa_ppx.utils *)

open Pa_ppx_utils
open St_types

module Value = struct
type t =
  STRING of string
| BOOL of bool
| INT of int
| DICT of (string * t) list
| LIST of t list
| NULL
[@@deriving show,yojson,located_yojson {exn = true},located_sexp {exn=true}]

let isSTRING = function STRING _ -> true | _ -> false
let isINT = function INT _ -> true | _ -> false

end

module Environ = struct
type attr_val_t = MV of Value.t list | SV of Value.t
[@@deriving show,yojson,located_yojson {exn = true},located_sexp {exn=true}]
type binding_t = string * attr_val_t
[@@deriving show,yojson,located_yojson {exn = true},located_sexp {exn=true}]
type frame_t = binding_t list
[@@deriving show,yojson,located_yojson {exn = true},located_sexp {exn=true}]
type t = frame_t list
[@@deriving show,yojson,located_yojson {exn = true},located_sexp {exn=true}]
end

