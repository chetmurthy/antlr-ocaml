(**pp -syntax camlp5o -package pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.yojson,pa_ppx.deriving_plugins.located_yojson,pa_ppx.deriving_plugins.located_sexp,pa_ppx.utils,pa_ppx_regexp *)

open Format

open Pa_ppx_base
open Ppxutil
open Pa_ppx_located_sexp.Sexp
open Pa_ppx_utils
open Coll

open Antlr

module Printing = struct

let matcher_cache = MHM.mk 23

let string_matcher s =
  match MHM.map matcher_cache s with
    v -> v
  | exception Not_found ->
     let matcher = Util.string_contains ~pat:s in
     MHM.add matcher_cache (s,matcher) ;
     matcher

  (* Default indentation level for human-readable conversions *)

  let default_indent = ref 1
  let max_dq_string_len = ref 10
  let default_rawdelims = ref ["foo"; "bar"; "baz"]

  (* Escaping of strings used as atoms in S-expressions *)

  let rawstring ~rawdelims ppf s =
    let rawdelims = if rawdelims = [] then !default_rawdelims else rawdelims in
    if not([%match {foo|\|}|foo} / pred s] s) then
      Fmt.(pf ppf "{|%s|}" s)
    else
      let raw1 delim =
        if (string_matcher delim) s then None
        else Some Fmt.(pf ppf "{%s|%s|%s}" delim s delim) in
      match List.find_map raw1 rawdelims with
        Some s -> s
      | None ->
         Fmt.(pf stderr "Sexpio.pp_hum: no supplied delim (%a) works for formatting to rawstring; formatting to double-quoted string, %S@."
                (list Dump.string) rawdelims
                s) ;
         Fmt.(pf ppf "%S" s)

  let no_escape s =
    [%match {|^(?:[a-z][a-z0-9_]*|[0-9]+)$|} / pred s i] s

  let is_one_line str = not(String.contains str '\n')

  let pp_hum_maybe_esc_str ~rawdelims ppf s =
    if no_escape s then
      Fmt.(pf ppf "%s" s)
    else if is_one_line s || String.length s <= !max_dq_string_len then
      Fmt.(pf ppf "%S" s)
    else rawstring ~rawdelims ppf s

  (* Output of S-expressions to formatters *)

  let wrap (l,r) pp1 pps x =
    Fmt.(pf pps "%s%a%s" l pp1 x r)

  let list_then_cut ~sep pp1 pps = function
      [x] -> Fmt.(pf pps "%a" pp1 x)
    | [] -> ()
    | l -> Fmt.(pf pps "%a@," (list ~sep pp1) l)

  let pp_hum_indent ~indent ~rawdelims ppf x =
    let rec pp1 ppf = function
    | Atom (_, str) -> pp_hum_maybe_esc_str ~rawdelims ppf str
    | List (_, []) ->
       Fmt.(pf ppf "()")
    | List (_, l) ->
       Fmt.(pf ppf "%a" (hvbox ~indent (wrap ("(",")") (list_then_cut ~sep:sp pp1))) l)
    in pp1 ppf x

  let pp_hum_ext ?(rawdelims=[]) ppf sexp = pp_hum_indent ~indent:!default_indent ~rawdelims ppf sexp

  let pp_hum ppf sexp = pp_hum_ext ppf sexp

  let to_string sexp = Fmt.(str "%a" pp_hum sexp)

end
