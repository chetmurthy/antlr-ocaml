(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.utils,pa_ppx.deriving_plugins.std,pa_ppx.import *)

open Stg_types
open Pa_ppx_base
open Ppxutil
open Pa_ppx_utils
open Std

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
| [< >] -> List.rev acc

let unread_input = parser
  [< 'x >] ->
    let s = match x with `Text s -> s | `Delim s -> s in
    Fmt.(failwithf "pa_stg: unread input %a" Dump.string s)
| [< >] -> ()

let pa_stg txt =
  let l = tokenize txt in
  (parser [< l = parec [] ; _=unread_input >] -> l) (Stream.of_list l)

