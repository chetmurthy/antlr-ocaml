(**pp -syntax camlp5o -package pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.yojson,pa_ppx.deriving_plugins.located_yojson,pa_ppx.deriving_plugins.located_sexp,pa_ppx.utils *)

open Pa_ppx_utils
open Sttypes2

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
let isSTRINGorNULL = function (STRING _|NULL) -> true | _ -> false
let isINT = function INT _ -> true | _ -> false
let isBOOL = function BOOL _ -> true | _ -> false

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

module type INDENT = sig
  type t
  val mt : t
  val add_string : t -> string -> t
  val emit : Buffer.t -> t -> unit
end

module Indent : INDENT = struct
  type t = string list

  let mt = []
  let add_string t s = s::t

  let emit b t =
    let l = List.rev t in
    List.iter (Buffer.add_string b) l

end

module IW = struct
  type t = {
      mutable cur_indent : Indent.t
    ; mutable emitted_text : bool
    ; buf : Buffer.t
    }

  let mk() = {
      cur_indent = Indent.mt
    ; emitted_text = false
    ; buf = Buffer.create 23
    }

  let emit ~indent t x =
    match x with
      TEXT s when t.emitted_text ->
       Buffer.add_string t.buf s

    | TEXT s ->
       Indent.emit t.buf t.cur_indent ;
       ; t.cur_indent <- Indent.mt
       ; t.emitted_text <- true
       ; Buffer.add_string t.buf s

    | HORZ_WS s when t.emitted_text ->
       Buffer.add_string t.buf s

    | HORZ_WS s ->
       t.cur_indent <- Indent.add_string t.cur_indent s

    | VERT_WS s ->
       Buffer.add_string t.buf s
      ; t.cur_indent <- indent
      ; t.emitted_text <- false

  let cur_indent ~indent t =
    if t.emitted_text then indent
    else t.cur_indent

end
module IndentWriter = IW
