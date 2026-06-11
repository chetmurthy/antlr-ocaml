(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.utils *)

open Pa_ppx_base
open Ppxutil
open Pa_ppx_utils.Std
open Interp

let find_stanza n l : string =
  match List.assoc n l with
    exception Not_found ->
     Fmt.(failwithf "Cannot find stanza '%s'" n)
  | s -> s

let conv_null f s =
  match s with
    "null" -> None
  | s -> Some (f s)

let conv_squote s =
  match [%match {|^'([^']+)'$|} / pcre2 strings !1] s with
    None -> Fmt.(failwithf "unrecognized supposedly-quoted string << %s >>" s)
  | Some s -> s

let read_raw txt =
  let stanzas = [%split {|\n\n|}] txt in
  let stanzas =
    List.map [%match {|^([^:]+):\n(.*)$|}  / pcre2 exc s strings (!1, !2)]  stanzas in
  let token_literal_names =
    let lines = [%split {|\n|}] (find_stanza "token literal names" stanzas) in
    List.map (conv_null conv_squote) lines in
  let token_symbolic_names =
    let lines = [%split {|\n|}] (find_stanza "token symbolic names" stanzas) in
    List.map (conv_null (fun x -> x)) lines in
  let rule_names =
    [%split {|\n|}] (find_stanza "rule names" stanzas) in
  let channel_names =
    [%split {|\n|}] (find_stanza "channel names" stanzas) in
  let mode_names =
    [%split {|\n|}] (find_stanza "mode names" stanzas) in
  let atn =
    let txt = find_stanza "atn" stanzas in
    match [%match {|\[(.*)\]|} / pcre2 strings !1] txt with
      None -> Fmt.(failwithf "unrecognized atn: << %s >>" txt)
    | Some s ->
       List.map int_of_string ([%split {|\s*,\s*|}] s) in
  Raw.{
      token_literal_names
    ; token_symbolic_names
    ; rule_names
    ; channel_names
    ; mode_names
    ; atn
  }
