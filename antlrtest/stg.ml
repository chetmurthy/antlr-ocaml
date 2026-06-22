(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.utils,pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.yojson,pa_ppx.import *)

type expr_t =
  VAR of string
| NOT of expr_t
[@@deriving show, yojson]

type stg_t =
  TEXT of string
| IFTHEN of expr_t * stg_t_list * stg_t_list
| ATTRIBUTE of string
| INCLUDE of string * string list
and stg_t_list = stg_t list
[@@deriving show, yojson]

open Pa_ppx_base
open Ppxutil
open Pa_ppx_utils
open Std

let is_ws = [%match {|^\s+$|} / pcre2 s pred] ;;

let clean_blank_lines s =
  let s = [%subst {|^\n|} / "" / s] s in
  [%subst {|\n\n+|} / "\n" / g s] s

module Template = struct

let tokenize s = [%split {|(?<!\\)<(?:(?:[^<>\s]|\\<)(?:[^<>]|\\<)*(?:[^<>\s]|\\<)|(?:[^<>\s]|\\<))>|} / pcre2 strings] s

let pa_opt pa1 = parser
  [< x=pa1 >] -> Some x
| [< >] -> None

let is_comment txt = starts_with ~pat:"<!" txt && ends_with ~pat:"!>" txt

let is_if txt = starts_with ~pat:"<if" txt
let is_keyword txt =
  is_if txt
  || txt = "<else>" || txt = "<endif>"

let is_attribute txt =
  not (is_keyword txt) &&
    [%match {|^<[a-z][a-z0-9_]*>$|} / pcre2 i pred] txt

let is_include txt =
  [%match {|^<[a-z][a-z0-9_]*\(.*?\)>$|} / pcre2 i pred] txt

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
   let e = match [%match {|^<([a-z][a-z0-9_]*)\((.*?)\)>$|} / pcre2 i strings (!1,!2)] txt with
       Some (n,argtxt) ->
        let args = [%split {|,|} / pcre2] argtxt in
        INCLUDE(n,args)
     | None -> Fmt.(failwithf "failed to parse attribute %a" Dump.string txt) in
   parec (e::acc) s

| [< ' `Delim txt when is_comment txt ; s >] -> parec acc s

| [< >] -> List.rev acc

let unread_input = parser
  [< 'x >] ->
    let s = match x with `Text s -> s | `Delim s -> s in
    Fmt.(failwithf "pa_stg: unread input %a" Dump.string s)
| [< >] -> ()

let pa txt =
  let l = tokenize txt in
  (parser [< l = parec [] ; _=unread_input >] -> l) (Stream.of_list l)

end

module Group = struct
type include_definition_rhs =
  { formals : string list
  ; rhs : stg_t list
  }
and include_definition =
  string * include_definition_rhs
[@@deriving show,yojson]

let pa0 (name, formals, rhs) =
  let formals = [%split {|\s*,\s*|} / pcre2] formals in
  let rhs = Template.pa rhs in
  (name, { formals ; rhs })


let pa_version1 txt =
  match [%match {|^\s*([a-z][a-z0-9_]*)\(([^()]*)\)\s*::=\s*<<(.*?)>>(.*)|} / pcre2 s i strings (!1,!2, !3, !4)] txt with
      Some (lhs, formals, rhs, txt) ->
      let g = pa0 (lhs, formals, rhs) in
      Some (g, txt)
    | None -> None

let pa_version2 txt =
  match [%match {|^\s*([a-z][a-z0-9_]*)\(([^()]*)\)\s*::=\s*<%(.*?)%>(.*)|} / pcre2 s i strings (!1,!2, !3, !4)] txt with
      Some (lhs, formals, rhs, txt) ->
      let g = pa0 (lhs, formals, rhs) in
      Some (g, txt)
    | None -> None

let pa_version3 txt =
  match [%match {|^\s*([a-z][a-z0-9_]*)\(([^()]*)\)\s*::=\s*"([^"]*?)"(.*)|} / pcre2 s i strings (!1,!2, !3, !4)] txt with
      Some (lhs, formals, rhs, txt) ->
      let g = pa0 (lhs, formals, rhs) in
      Some (g, txt)
    | None -> None

let pa1 txt =
  match List.find_map (fun f -> f txt) [pa_version1; pa_version2; pa_version3] with
    Some (g,txt) -> Some (g,txt)
  | None ->
     if [%match {|\S|} / pcre2 pred] txt then
       Fmt.(failwithf "Group.pa1: unrecognized text %a" Dump.string txt)
     else None

let pa txt =
  let rec parec acc txt =
    match pa1 txt with
      Some (g,txt) -> parec (g::acc) txt
    | None -> List.rev acc
in parec [] txt

let load file =
  file |> Bos.OS.File.read |> Result.get_ok |> pa

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
    ; includes : Group.include_definition_rhs strmap
    } [@@deriving yojson]
end

module Subst = struct

  let rec prlist f = function
      [] -> [< >]
    | (h::t) -> [< f h ; prlist f t >]

  let eval_actual txt =
    [%subst {|"((?:\\"|[^"])+)"|} / {| Scanf.unescaped $1$ |} / pcre2 g e] txt

  let rec eval env = function
      VAR k ->
      List.mem_assoc k env.Env.attributes
    | NOT e ->
       not(eval env e)

  let rec subst0 env =
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
      | INCLUDE (n,_) when not (List.mem_assoc n env.includes) ->
         Fmt.(failwithf "Stg.Subst.subst: INCLUDE %a unimplemented" Dump.string n)

      | INCLUDE (n,actuals) ->
         let open Group in
         let rhs = List.assoc n env.includes in
         if List.length rhs.formals <> List.length actuals then
           Fmt.(failwithf "Stg.Subst.subst: formal/actual mismatch for INCLUDE %a len(%a) <> len(%a)"
                  Dump.string n
                  (list Dump.string) rhs.formals
                  (list Dump.string) actuals
           ) ;
         let actuals = List.map eval_actual actuals in
         let l = Std.combine rhs.formals actuals in
         let env' = {(env) with attributes = l@env.attributes} in
         prlist (subst0 env') rhs.rhs
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
  let stg = txt |> Template.pa in
  Subst.subst env stg

let transform_file env f =
    f |> Bos.OS.File.read |> Result.get_ok |> transform env
