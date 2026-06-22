(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.utils,pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.yojson,pa_ppx.import *)

open Pa_ppx_base
open Ppxutil
open Pa_ppx_utils
open Std
open Stg

let clean_triple_quotes txt =
  [%subst {|"""(.*?)""".*|} / {|$1|} / pcre2 s] txt

let clean_stanza s =
  let s = [%subst {|^\n|} / "" / s] s in
  [%subst {|\n\n$|} / "" / s] s

let split_stanzas txt = [%split {|^\[(notes|type|grammar|slaveGrammar|start|input|output|errors|flags|skip)\]$|} / pcre2 m strings !1] txt

let parse txt =
  let l = split_stanzas txt in
  let rec parec acc = function
      (`Text s)::tl when is_ws s ->
      parec acc tl
    | (`Text s)::_ ->
       Fmt.(failwithf "Descriptor.parse: text encountered before stanza: %a" Dump.string s)
    | (`Delim name)::(`Text body)::tl ->
       parec ((name,clean_stanza body)::acc) tl
    | (`Delim n)::[] -> 
       Fmt.(failwithf "Descriptor.parse: trailing stanza name: %s" n)
    | [] -> List.rev acc in
  parec [] l

type flags_t = {
    showDFA : bool
  ; showDiagnosticErrors : bool
  ; traceATN : bool
  ; predictionMode : string
  ; buildParseTree : bool
  }

let pa_flags txt =
  { showDFA = [%match {|showDFA|} / pcre2 pred] txt
  ; showDiagnosticErrors = [%match {|showDiagnosticErrors|} / pcre2 pred] txt
  ; traceATN = [%match {|traceATN|} / pcre2 pred] txt
  ; predictionMode =
      (match [%match {|predictionMode=(\S+)|} / pcre2 strings !1] txt with
         None -> "LL"
       | Some s -> s)
  ; buildParseTree = not ([%match {|notBuildParseTree|} / pcre2 pred] txt)
  }

type t = {
    is_lexer : bool
  ; is_composite : bool
  ; grammar_name : string
  ; grammar : string
  ; slaveGrammars : string list
  ; stanzas : (string * string) list
  ; filename : string
  ; flags : flags_t
  ; startRule : string option
  }

let stanza_opt d name =
  match List.assoc name d.stanzas with
    x -> Some x
  | exception Not_found ->
     None

let stanza d name =
  match List.assoc name d.stanzas with
    x -> x
  | exception Not_found ->
       Fmt.(failwithf "%s: Descriptor.stanza: no descriptor-%s stanza" d.filename name)

let grammar_name ~file txt =
  match [%match {|.*grammar\s+([a-z][a-z0-9_]*)\s*;|} / pcre2 i s strings !1] txt with
    Some n -> n
  | None -> Fmt.(failwithf "%s: no grammar-name found in grammar" file)

let _mk ~file stanzas =
  let (is_lexer, is_composite) = match List.assoc "type" stanzas with
      "Lexer" -> (true, false)
    | "CompositeLexer" -> (true, true)
    | "Parser" -> (false, false)
    | "CompositeParser" -> (false, true)
    | t -> Fmt.(failwithf "%s: Descriptor.mk: descriptor-type was %a (not {,Composite}{Lexer,Parser})"
                  file Dump.string t)
    | exception Not_found ->
       Fmt.(failwithf "%s: Descriptor.mk: no descriptor-type stanza" file) in
  let grammar = match List.assoc "grammar" stanzas with
      x -> clean_triple_quotes x
    | exception Not_found ->
       Fmt.(failwithf "%s: Descriptor.mk: no grammar stanza" file) in

  let slaveGrammars =
    stanzas
    |> List.filter_map (function
             ("slaveGrammar",txt) -> Some(clean_triple_quotes txt)
           | _ -> None) in

  let flags_txt =
    match List.assoc "flags" stanzas with
      x -> x
    | exception Not_found -> "" in
  let flags = pa_flags flags_txt in

  let startRule =
    match List.assoc "start" stanzas with
      x -> Some x
    | exception Not_found -> None in

  let grammar_name = grammar_name ~file grammar in
  {
    is_lexer
  ; is_composite
  ; grammar_name
  ; grammar
  ; slaveGrammars
  ; stanzas
  ; filename = file
  ; flags
  ; startRule
  }

let load file =
  let txt = file |> Fpath.v |>  Bos.OS.File.read |> Result.get_ok in
  let stanzas = parse txt in
  _mk ~file stanzas

let to_env d =
  let attributes = [("grammarName",d.grammar_name);("python3","")] in
  let attributes =
    if d.is_lexer then
      let lexerName = d.grammar_name in
      ("lexerName",lexerName)::attributes
  else
    let lexerName = Fmt.(str "%sLexer" d.grammar_name) in
    let parserName = Fmt.(str "%sParser" d.grammar_name) in
    ("lexerName",lexerName)::("parserName",parserName):: attributes in

  let attributes = ("predictionMode", d.flags.predictionMode)::attributes in

  let attributes =
    if d.flags.showDFA then
      ("showDFA","")::attributes
    else attributes in

  let attributes =
    if d.flags.showDiagnosticErrors then
      ("showDiagnosticErrors","")::attributes
    else attributes in

  let attributes =
    if d.flags.traceATN then
      ("traceATN","")::attributes
    else attributes in

  let attributes =
    if d.flags.buildParseTree then
      ("buildParseTree","")::attributes
    else attributes in

  let attributes =
    match d.startRule with
      None -> attributes
    | Some r -> ("parserStartRuleName", r)::attributes in

  Stg.Env.{ attributes ; includes = [] }
