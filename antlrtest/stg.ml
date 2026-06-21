(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.utils,pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.yojson,pa_ppx.import *)

type expr_t =
  VAR of string
| NOT of expr_t

type stg_t =
  TEXT of string
| IFTHEN of expr_t * stg_t list * stg_t list
| ATTRIBUTE of string
| INCLUDE of string * string list

open Pa_ppx_base
open Ppxutil
open Pa_ppx_utils
open Std

module Template = struct

let tokenize s = [%split {|<[^<>]+>|} / pcre2 strings] s

let pa_opt pa1 = parser
  [< x=pa1 >] -> Some x
| [< >] -> None

let is_if txt = starts_with ~pat:"<if" txt
let is_keyword txt =
  is_if txt
  || txt = "<else>" || txt = "<endif>"

let is_attribute txt =
  not (is_keyword txt) &&
    [%match {|^<[a-z][a-z0-9_]*>$|} / pcre2 i pred] txt

let is_include txt =
  [%match {|^<[a-z][a-z0-9_]*\([^()]*\)>$|} / pcre2 i pred] txt

let rec parec acc = parser
  [< ' `Text txt ; s >] -> parec (TEXT txt :: acc) s
| [< ' `Delim preds when is_if preds ; thenl = parec [] ;
       else_opt = pa_opt (parser [< ' `Delim"<else>" ; elsel = parec [] >] -> elsel) ;
       ' `Delim"<endif>" ;
       s >] ->
   let pred = match ([%match {|^<if\(([a-z][a-z0-9_]*)\)>$|}/ pcre2 i strings !1] preds,
                     [%match {|^<if\(!([a-z][a-z0-9_]*)\)>$|}/ pcre2 i strings !1] preds) with
       (Some v, None) -> VAR v
     | (None, Some v) -> NOT(VAR v)
     | __ -> Fmt.(failwithf "failed to parse predicate %a" Dump.string preds) in
   let e = IFTHEN (pred, thenl, match else_opt with None -> [] | Some l -> l) in
   parec (e::acc) s

| [< ' `Delim txt when is_attribute txt ; s >] ->
   let e = match [%match {|^<([a-z][a-z0-9_]*)>$|} / pcre2 i strings !1] txt with
       Some v -> ATTRIBUTE v
     | None -> Fmt.(failwithf "failed to parse attribute %a" Dump.string txt) in
   parec (e::acc) s

| [< ' `Delim txt when is_include txt ; s >] ->
   let e = match [%match {|^<([a-z][a-z0-9_]*)\(([^()]*)\)>$|} / pcre2 i strings (!1,!2)] txt with
       Some (n,argtxt) ->
        let args = [%split {|,|} / pcre2] argtxt in
        INCLUDE(n,args)
     | None -> Fmt.(failwithf "failed to parse attribute %a" Dump.string txt) in
   parec (e::acc) s

| [< >] -> List.rev acc

let unread_input = parser
  [< 'x >] ->
    let s = match x with `Text s -> s | `Delim s -> s in
    Fmt.(failwithf "pa_stg: unread input %a" Dump.string s)
| [< >] -> ()

let pa_stg txt =
  let l = tokenize txt in
  (parser [< l = parec [] ; _=unread_input >] -> l) (Stream.of_list l)

end

module Env = struct
  type 'b _strmap = (string * 'b) list [@@deriving yojson]

  type 'b strmap = 'b _strmap
  let strmap_to_yojson vconv l =
    let j : Yojson.Safe.t = _strmap_to_yojson vconv l in
    match j with
      `List l ->
      `Assoc (List.map (function `List[`String k; v] -> (k,v) | _ -> assert false) l)
    | _ -> assert false

  let strmap_of_yojson vconv j =
    match j with
      `Assoc l ->
      _strmap_of_yojson vconv (`List (List.map (fun (k,v) -> `List [`String k; v]) l))
    | _ -> Result.Error "Stg.Env.strmap_of_yojson"

  type t = {
      attributes : string strmap
    } [@@deriving yojson]
end

module Subst = struct

  let rec prlist f = function
      [] -> [< >]
    | (h::t) -> [< f h ; prlist f t >]

  let rec eval env = function
      VAR k ->
      List.mem_assoc k env.Env.attributes
    | NOT e ->
       not(eval env e)

  let subst0 env =
    let rec srec = function
        TEXT s -> [< 's >]
      | ATTRIBUTE s ->
         (match List.assoc s env.Env.attributes with
            v -> [< 'v >]
          | exception Not_found ->
             Fmt.(failwithf "Stg.Subst.subst: attribute %a not found in subst env" Dump.string s))
      | IFTHEN(e, thenl,elsel) ->
         if eval env e then
           prlist srec thenl
         else
           prlist srec elsel
      | INCLUDE (n,_) -> Fmt.(failwithf "Stg.Subst.subst: INCLUDE %a unimplemented" Dump.string n)
    in srec

  let subst env stg =
    let strm = prlist (subst0 env) stg in
    let buf = Buffer.create 23 in
    let rec srec = parser
      [< 'txt ; s >] -> Buffer.add_string buf txt ; srec s
    | [< >] -> Buffer.contents buf in
    srec strm

end

let transform env txt =
  let stg = txt |> Template.pa_stg in
  Subst.subst env stg

let transform_file env f =
    f |> Bos.OS.File.read |> Result.get_ok |> transform env
