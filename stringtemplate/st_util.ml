(**pp -syntax camlp5o -package pa_ppx_regexp *)

open Pa_ppx_base
open Ppxutil
open Pa_ppx_utils

let unescape s =
  let payload =
    match [%match {|^<(\S+)>$|} / strings !1] s with
      None ->
      Fmt.(failwithf "St_util.unescape: unrecognized escape %a" Dump.string s)
    | Some s -> s in
  match payload with
    {|\b|} -> "\b"
  | {|\t|} -> "\t"
  | {|\n|} -> "\n"
  | {|\f|} -> "\x0c"
  | {|\r|} -> "\r"
  | {|\"|} -> "\""
  | {|\'|} -> "'"
  | {|\\|} -> "\\"
  | s ->
     if [%match {|^\\u([0-9a-fA-F]{1,4})$|} / pred] s then
       s |> [%subst {|^\\u([0-9a-fA-F]{1,4})$|} / {|\u{$1}|} / pcre2 ] |> Std.unescape_string
     else Fmt.(failwithf "St_util.unescape: unrecognized escape -payload- %a" Dump.string s)

