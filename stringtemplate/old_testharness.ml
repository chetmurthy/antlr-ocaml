(**pp -syntax camlp5o -package pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.yojson,pa_ppx.deriving_plugins.located_yojson,pa_ppx.deriving_plugins.located_sexp,pa_ppx.utils *)

open Pa_ppx_base
open Ppxutil

open Eval

type t =
  {
    classname : string
  ; template_s : string
  ; attributes : Environ.frame_t
  ; groupfile : (string * string) option[@yojson.default None][@located_yojson.default None][@located_sexp.default None]
  ; groupfiles : (string * string) list[@yojson.default []][@located_yojson.default []][@located_sexp.default []]
  ; output : string
  ; errors : string[@yojson.default ""][@located_yojson.default ""][@located_sexp.default ""]
  ; errorsContains : string[@yojson.default ""][@located_yojson.default ""][@located_sexp.default ""]
  ; indent : bool[@yojson.default true][@located_yojson.default true][@located_sexp.default true]
  }
[@@deriving show,yojson,located_yojson {exn = true},located_sexp {exn=true}]

let of_json_string s =
  let open Pa_ppx_located_yojson.Json in
  let j = JsonEOI.of_string s in
  of_located_yojson_exn j

let of_sexp_string s =
  let open Pa_ppx_located_sexp.Altsexp in
  let j = of_string s in
  t_of_located_sexp j

let load_json ~file =
  let open Pa_ppx_located_yojson.Json in
  let j = JsonEOI.load ~file in
  of_located_yojson_exn j

let load_sexp ~file =
  let open Pa_ppx_located_sexp.Altsexp in
  let j = load_sexp file in
  t_of_located_sexp j

let load ~file =
  if Fpath.(file |> v |> has_ext "json") then
    load_json ~file
  else if Fpath.(file |> v |> has_ext "sexp") then
    load_sexp ~file
  else Fmt.(failwithf "TH.load: file %s is neither .json nor .sexp" file)

let upgrade th =
  {
    Testharness.classname = th.classname
  ; groupfile = th.groupfile
  ; groupfiles = th.groupfiles
  ; indent = th.indent
  ; errors = th.errors
  ; errorsContains = th.errorsContains
  ; runs = [{
               Testharness.input = th.template_s
             ; output = th.output
             ; attributes = th.attributes
           }]
  }

module Multi = struct
type _t = (string * t) list
[@@deriving show,yojson,located_yojson {exn = true},located_sexp {exn=true}]
type t = _t
[@@deriving show,yojson,located_yojson {exn = true},located_sexp {exn=true}]

let of_json_string s =
  let open Pa_ppx_located_yojson.Json in
  let j = JsonEOI.of_string s in
  of_located_yojson_exn j

let of_sexp_string s =
  let open Pa_ppx_located_sexp.Altsexp in
  let j = of_string s in
  t_of_located_sexp j

let load_json ~file =
  let open Pa_ppx_located_yojson.Json in
  let j = JsonEOI.load ~file in
  of_located_yojson_exn j

let load_sexp ~file =
  let open Pa_ppx_located_sexp.Altsexp in
  let j = load_sexp file in
  t_of_located_sexp j

let load ~file =
  if Fpath.(file |> v |> has_ext "json") then
    load_json ~file
  else if Fpath.(file |> v |> has_ext "sexp") then
    load_sexp ~file
  else Fmt.(failwithf "TH.Multi.load: file %s is neither .json nor .sexp" file)

let upgrade l =
  l |> List.map (fun (k,th) -> (k,upgrade th))

end
