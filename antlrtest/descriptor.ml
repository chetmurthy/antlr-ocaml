(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.utils,pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.yojson,pa_ppx.import *)

open Pa_ppx_base
open Ppxutil
open Pa_ppx_utils
open Std

let is_ws = [%match {|^\s+$|} / pcre2 s pred]

module Pos = struct
  type t = {
      filename  : string
    ; line : int
    ; bol_pos : int
    ; first_pos : int
    }

  type pos_string = t * string

  let mk ~file = {
      filename = file
    ; line = 1
    ; bol_pos = 0
    ; first_pos = 0
    }

  let mt = mk ~file:""

  let of_loc loc = {
      filename = Ploc.file_name loc
    ; line = Ploc.line_nb loc
    ; bol_pos = Ploc.bol_pos loc
    ; first_pos = Ploc.first_pos loc
    }

  let to_loc pos =
    Ploc.make_loc pos.filename pos.line pos.bol_pos (pos.first_pos, pos.first_pos) ""

  let to_loc_string (pos, s) = (to_loc pos, s)

  let update_char pos c =
    if c = '\n' then
      { (pos) with line = pos.line + 1 ; bol_pos = pos.first_pos+1 ; first_pos = pos.first_pos + 1 }
    else { (pos) with first_pos = pos.first_pos + 1 }

  let update pos txt =
    String.fold_left update_char pos txt

end



let clean_triple_quotes (pos, txt) =
  match [%match {|^(\s*""")(.*?)""".*|} / pcre2 strings (!1,!2) s] txt with
    None -> (pos, txt)
  | Some (quotes, txt) ->
     (Pos.update pos quotes, txt)

let clean_stanza (pos, s) =
  let (pos, s) = 
    match [%match {|^(\n*)(.*)$|} / pcre2 strings (!1,!2) s] s with
    None -> (pos, s)
  | Some (nls, s) -> (Pos.update pos nls, s) in
  (pos, [%subst {|\n\n$|} / "" / s] s)

type split_elem_t = [ `Text of string | `Delim of string * string * string ]
type split_t = (Pos.t * split_elem_t) list

let split_stanzas txt : split_elem_t list = [%split {|^\[(notes|type|grammar|slaveGrammar|start|input|output|errors|flags|skip)([^\]]*)\]$|} / pcre2 m strings (!0, !1, !2)] txt

let position_stanzas pos l : split_t =
  l
  |> List.fold_left (fun (pos,acc) x ->
         match x with
           `Text s ->
            let pos' = Pos.update pos s in
            (pos', (pos,x)::acc)
         | `Delim (full, _, _) ->
            let pos' = Pos.update pos full in
            (pos', (pos,x)::acc)
       ) (pos, [])
  |> snd
  |> List.rev

let parse_stanza_params txt =
  txt
  |> [%split {|\s+|} / pcre2]
  |> List.filter_map [%match {|^([^=]+)=([^=]+)$|} / pcre2 strings (!1,!2)]


let parse pos txt : (string * ((string * string) list * Pos.pos_string)) list =
  let l = split_stanzas txt in
  let l = position_stanzas pos l in

  let rec parec acc = function
      (_, `Text s)::tl when is_ws s ->
      parec acc tl
    | (pos, `Text s)::_ ->
       let loc = Pos.to_loc pos in
       Fmt.(raise_failwithf loc "Descriptor.parse: text encountered before stanza: %a" Dump.string s)
    | (_, `Delim (full_delim, name,params))::(pos, `Text body)::tl ->
       let params = parse_stanza_params params in
       let (pos, body) = clean_stanza (pos, body) in
       parec ((name,(params,(pos, body)))::acc) tl
    | (pos, `Delim (_, n,_))::[] -> 
       let loc = Pos.to_loc pos in
       Fmt.(raise_failwithf loc "Descriptor.parse: trailing stanza name: %s" n)
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

type params_t = (string * string) list

type grammar_t = {
    name : string
  ; loc : Ploc.t
  ; txt : string
  }

type t = {
    is_lexer : bool
  ; is_composite : bool
  ; grammar : grammar_t
  ; slaveGrammars : (params_t * grammar_t) list
  ; stanzas : (string * (params_t * (Ploc.t * string))) list
  ; filename : string
  ; testname : string
  ; flags : flags_t
  ; startRule : string option
  }

let stanza_opt d name =
  match List.assoc name d.stanzas with
    x -> Some x
  | exception Not_found ->
     None

let stanza_all d name =
  List.filter_map (fun (n,v) -> if n = name then Some v else None) d.stanzas

let stanza d name =
  match List.assoc name d.stanzas with
    x -> x
  | exception Not_found ->
       Fmt.(failwithf "%s: Descriptor.stanza: no descriptor-%s stanza" d.filename name)

let grammar_name (pos, txt) =
  match [%match {|.*grammar\s+([a-z][a-z0-9_]*)\s*;|} / pcre2 i s strings !1] txt with
    Some n -> n
  | None ->
     let loc = Pos.to_loc pos in
     Fmt.(raise_failwith loc "no grammar-name found in grammar")

let mk_grammar (pos, txt) =
  let name = grammar_name (pos, txt) in
  {
    name = name
  ; loc = Pos.to_loc pos
  ; txt
  }

let _mk ~testname ~file stanzas =
  let (is_lexer, is_composite) = match List.assoc "type" stanzas with
      (_,(_, "Lexer")) -> (true, false)
    | (_,(_, "CompositeLexer")) -> (true, true)
    | (_,(_, "Parser")) -> (false, false)
    | (_,(_, "CompositeParser")) -> (false, true)
    | (_,(pos, t)) ->
       let loc = Pos.to_loc pos in
       Fmt.(raise_failwithf loc "%s: Descriptor.mk: descriptor-type was %a (not {,Composite}{Lexer,Parser})"
                  file Dump.string t)
    | exception Not_found ->
       Fmt.(failwithf "%s: Descriptor.mk: no descriptor-type stanza" file) in
  let stanzas =
    List.map (fun ((n,(pl,(pos,txt))) as x) ->
        if List.mem n ["input";"output";"errors";"grammar";"slaveGrammar"] then
          (n,(pl,clean_triple_quotes (pos,txt)))
        else x) stanzas in
                           
  let grammar = match List.assoc "grammar" stanzas with
      (_,x) -> mk_grammar x
    | exception Not_found ->
       Fmt.(failwithf "%s: Descriptor.mk: no grammar stanza" file) in

  let slaveGrammars =
    stanzas
    |> List.filter_map (function
             ("slaveGrammar",(pl, x)) ->
               let x =
                 match List.assoc_opt "file" pl with
                   None -> x
                 | Some fname ->
                    let txt =
                      fname
                      |> Fpath.v
                      |> Bos.OS.File.read
                      |> Rresult.R.failwith_error_msg
                      |> [%subst {|\\|} / {|\\|} / g s]
                      |> [%split {|({.*?})|} / strings !1 pcre2 s]
                      |> List.map (function
                               `Delim s -> s
                             | `Text s ->
                                [%subst {|<|} / {|\<|} / g s] s)
                    |> String.concat ""
                    in

                    let pos = Pos.mk fname in
                    (pos, txt)
               in Some (pl, mk_grammar x)
           | _ -> None) in

  let flags_txt =
    match List.assoc "flags" stanzas with
      (_,(_, x)) -> x
    | exception Not_found -> "" in
  let flags = pa_flags flags_txt in

  let startRule =
    match List.assoc "start" stanzas with
      (_,(_, x)) -> Some x
    | exception Not_found -> None in

  {
    is_lexer
  ; is_composite
  ; grammar
  ; slaveGrammars
  ; stanzas = List.map (fun (n,(pl,ps)) -> (n,(pl,Pos.to_loc_string ps))) stanzas
  ; filename = file
  ; testname
  ; flags
  ; startRule
  }


let _of_string pos ~testname txt =
  let stanzas = parse pos txt in
  _mk ~testname ~file:pos.Pos.filename stanzas

let of_string ?startloc ~testname txt =
  let pos = match startloc with None -> Pos.mk ~file:"" | Some loc -> Pos.of_loc loc in
  _of_string pos ~testname txt

let load ~testname file =
  let txt = file |> Fpath.v |>  Bos.OS.File.read |> Result.get_ok in
  let pos = Pos.mk ~file in
  _of_string pos ~testname txt

let to_env d =
  let attributes = [
      ("testName",d.testname)
     ;("grammarName",d.grammar.name)
     ;("python3","")] in
  let attributes =
    if d.is_lexer then
      let lexerName = d.grammar.name in
      ("lexerName",lexerName)::attributes
  else
    let lexerName = Fmt.(str "%sLexer" d.grammar.name) in
    let parserName = Fmt.(str "%sParser" d.grammar.name) in
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

  attributes
