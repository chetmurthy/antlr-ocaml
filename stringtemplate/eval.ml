(**pp -syntax camlp5o -package pa_ppx.deriving_plugins.std,pa_ppx.utils *)

open Pa_ppx_utils
open St_types

module Value = struct
type t =
  STRING of string
| BOOL of bool
| DICT of (string * t) list
| LIST of t list
[@@deriving show]
end

module Environ = struct
type frame_t = (string * Value.t) list
[@@deriving show]
type t = frame_t list
[@@deriving show]

end

