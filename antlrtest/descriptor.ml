(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.utils,pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.yojson,pa_ppx.import *)

open Pa_ppx_base
open Ppxutil
open Pa_ppx_utils
open Std

let is_ws = [%match {|^\s+$|} / pcre2 s pred] ;;

let clean_body s =
  let s = [%subst {|^\n|} / "" / s] s in
  [%subst {|\n\n$|} / "" / s] s

let parse txt =
  let l = [%split {|^\[(:notes|type|grammar|slaveGrammar|start|input|output|errors|flags|skip)\]$|} / pcre2 m strings !1] txt in
  let rec parec acc = function
      (`Text s)::tl when is_ws s ->
      parec acc tl
    | (`Text s)::_ ->
       Fmt.(failwithf "Descriptor.parse: text encountered before stanza: %a" Dump.string s)
    | (`Delim name)::(`Text body)::tl ->
       parec ((name,clean_body body)::acc) tl
    | (`Delim n)::[] -> 
       Fmt.(failwithf "Descriptor.parse: trailing stanza name: %s" n)
    | [] -> List.rev acc in
  parec [] l

type t = {
    is_lexer : bool
  ; grammar_name : string
  ; stanzas : (string * string) list
  ; filename : string
  }

let stanza d name =
  match List.assoc name d.stanzas with
    x -> x
  | exception Not_found ->
       Fmt.(failwithf "%s: Descriptor.stanza: no descriptor-type stanza" d.filename)

let _mk ~file stanzas =
  let is_lexer = match List.assoc "type" stanzas with
      "Lexer" -> true
    | "Parser" -> false
    | t -> Fmt.(failwithf "%s: Descriptor.mk: descriptor-type was %a (not Lexer or Parser)"
                  file Dump.string t)
    | exception Not_found ->
       Fmt.(failwithf "%s: Descriptor.mk: no descriptor-type stanza" file) in
  let grammar = match List.assoc "grammar" stanzas with
      x -> x
    | exception Not_found ->
       Fmt.(failwithf "%s: Descriptor.mk: no grammar stanza" file) in

  let grammar_name = match [%match {|.*grammar\s+([a-z][a-z0-9_]*)\s*;|} / pcre2 i s strings !1] grammar with
      Some n -> n
    | None -> Fmt.(failwithf "%s: no grammar-name found in grammar" file) in
  {
    is_lexer
  ; grammar_name
  ; stanzas
  ; filename = file
  }

let load file =
  let txt = file |> Fpath.v |>  Bos.OS.File.read |> Result.get_ok in
  let stanzas = parse txt in
  _mk ~file stanzas

let to_env d =
  let attributes = [("grammarName",d.grammar_name);("python3","")] in
  let attributes =
    let lexerName = Fmt.(str "%sLexer" d.grammar_name) in
    let parserName = Fmt.(str "%sParser" d.grammar_name) in
    if d.is_lexer then
      ("lexerName",lexerName)::attributes
  else
    ("lexerName",lexerName)::("parserName",parserName):: attributes in
  Stg.Env.{ attributes ; includes = [] }
