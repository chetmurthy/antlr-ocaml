(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.deriving_plugins.std *)

let hey () = Cmdliner.Cmd.Exit.ok
let ho () = Cmdliner.Cmd.Exit.ok

open Pa_ppx_base
open Ppxutil
open Pa_ppx_utils
open Coll
open Cmdliner
open Cmdliner.Term.Syntax

open Antlr
open Atn

let caches = Simulate.Caches.mk () ;;
Exec.file_init ~dfast_cache:caches.dfast ~acs_cache:caches.acs ~ac_cache:caches.ac () ;;

module EmitATN = struct

let pp_option ppf pps = function
    None -> Fmt.(pf pps "None")
  | Some x -> Fmt.(pf pps "Some %a" ppf x)

let emit ~debug file =
  Atn.debug := debug ;
  let raw_atn =
    file
    |>  Bos.OS.File.read
    |> Result.get_ok
    |> Interp_syntax.read_raw in

    Fmt.(pf stdout
{|
let raw_atn = Antlr.Interp.Raw.{
  token_literal_names = [|%a|]
; token_symbolic_names = [|%a|]
; rule_names = [|%a|]
; channel_names = [%a]
; mode_names = [%a]
; atn = [%a]@ 
 }
 |}
(array ~sep:semi (pp_option Dump.string)) raw_atn.Interp.Raw.token_literal_names
(array ~sep:semi (pp_option Dump.string)) raw_atn.Interp.Raw.token_symbolic_names
(array ~sep:semi Dump.string) raw_atn.Interp.Raw.rule_names
(list ~sep:semi (pp_option Dump.string)) raw_atn.Interp.Raw.channel_names
(list ~sep:semi Dump.string) raw_atn.Interp.Raw.mode_names
(list ~sep:semi int) raw_atn.Interp.Raw.atn) ;
         ()

let cmd =
let file =
  let docv = "The file to read-and-convert to OCaml." in
  let absent = "absent." in
  Arg.(required & pos 0 (some string) None & info [] ~absent ~docv) in

let debug =
  let doc = "enable debugging." in
  Arg.(value & flag & info ["debug"] ~doc) in

  let doc = "Convert an ATN to OCaml" in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "emit-ocaml-atn" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ file and+ debug in
  emit ~debug (Fpath.v file) ;
  Cmdliner.Cmd.Exit.ok

end

module EmitLexer = struct
open Parse_antlrv4

let emit ~debug ~grammar_lib ~translation_file file =
  let interp_file = file |> Fpath.set_ext "interp" in
  if not (interp_file |> Bos.OS.File.exists |> Rresult.R.get_ok) then
    Fmt.(failwithf "interp file %a (for grammar %a) does not exist@."
           Fpath.pp interp_file Fpath.pp file) ;
  EmitATN.emit ~debug interp_file ;
  Grammar_tools.generate_lexer ~path:[Fpath.v grammar_lib] ~translation_file file

let cmd =
let file =
  let docv = "The file to read-and-convert to OCaml." in
  let absent = "absent." in
  Arg.(value & pos 1 file "" & info [] ~absent ~docv) in

let translation_file =
  let docv = "translation-file: JSON file containing translations for actions/sempreds." in
  Arg.(value & pos 0 file "" & info [] ~docv) in

let grammar_lib =
  let docv = "grammar-lib: directory for looking up grammar files." in
  Arg.(value & opt dir "" & info ["grammar-lib"] ~docv) in

let debug =
  let doc = "enable debugging." in
  Arg.(value & flag & info ["debug"] ~doc) in

  let doc = "Convert an ATN to OCaml" in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "emit-ocaml-lexer" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ file and+ debug and+ translation_file and+ grammar_lib in
  emit ~debug ~grammar_lib ~translation_file:(Fpath.v translation_file) (Fpath.v file) ;
  Cmdliner.Cmd.Exit.ok

end

module Dump = struct

let check_rule_separation atn =
  let state2rule = MHM.mk 23 in
  atn.states
  |> State.iter
       (fun st ->
         MHM.add state2rule (st.stateNumber, st.ruleIndex)
       ) ;
  atn.states
  |> State.iter
       (fun st ->
         st.State.transitions
         |> List.iter
              (fun e ->
                let t = Edge.target e in
                if MHM.map state2rule st.stateNumber <> MHM.map state2rule t then
                  Fmt.(pf stderr "transition %a (rule %d) -> %a (rule %d) (type %s)@."
                         dump_state_id st.stateNumber
                         (MHM.map state2rule st.stateNumber)
                         dump_state_id t
                         (MHM.map state2rule t)
                         (Edge.serialization_type_string e))
       ))

let dump ~json ~debug ~disable_verify ~check_rule_separation:check file =
  Antlr.Atn.debug := debug ;
  let atn =
    file
    |> Fpath.v
    |>  Bos.OS.File.read
    |> Result.get_ok
    |> Antlr.Interp_syntax.read_raw
    |> Antlr.Atn.deser ~verify:(not disable_verify) in
    Fmt.(pf stderr "Filename: %s@." file) ;
  if json then
    Fmt.(pf stdout "%a@." (Yojson.Safe.pretty_print ~std:true) (Yojson.Safe.sort (Antlr.Atn.to_yojson atn)))
  else
    Fmt.(pf stdout "%a@." Antlr.Atn.dump atn) ;
  if check then
    check_rule_separation atn ;
  ()

let cmd =
let file =
  let docv = "The file to read-and-dump." in
  let absent = "absent." in
  Arg.(required & pos 0 (some string) None & info [] ~absent ~docv) in

let debug =
  let doc = "enable debugging." in
  Arg.(value & flag & info ["debug"] ~doc) in

let check_rule_separation =
  let doc = "check that rules don't share states." in
  Arg.(value & flag & info ["check-rule-separation"] ~doc) in

let json =
  let doc = "JSON output." in
  Arg.(value & flag & info ["json"] ~doc) in

let disable_verify =
  let doc = "disable verify." in
  Arg.(value & flag & info ["disable-verify"] ~doc) in

  let doc = "dump an ATN" in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "dump" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ file and+ debug and+ json and+ disable_verify and+ check_rule_separation in
  dump ~check_rule_separation ~json ~debug ~disable_verify file ;
  Cmdliner.Cmd.Exit.ok

end

module Graph = struct
let graph ~xdot ~with_rule_index ~ruleIndex file =
  let ruleIndex = if ruleIndex = -1 then None else Some ruleIndex in
  let atn =
    file
    |> Fpath.v
    |>  Bos.OS.File.read
    |> Result.get_ok
    |> Interp_syntax.read_raw
    |> Atn.deser ~verify:false in

  let states =
    atn.states
    |> State.states_to_list
    |> List.filter_map
         (fun st -> match ruleIndex with
                      None -> Some st
                    | Some n when st.State.ruleIndex = n -> Some st
                    | _ -> None) in

  let edge_label = function
      Edge.RuleTransition {ruleIndex} -> Fmt.(str "<rule %d>" ruleIndex)
    | SetTransition {set} -> Fmt.(str "<set %a>" IntervalSet.dump set)
    | RangeTransition {label} -> Fmt.(str "<range %a>" IntervalSet.dump label)
    | AtomTransition {label} -> Fmt.(str "<atom %a>" IntervalSet.dump label)
    | t -> Edge.serialization_type_string t in
  let edges =
  states
  |> List.concat_map
       (fun st ->
         st.State.transitions
         |> List.map (fun e ->
                (st.State.stateNumber,
                 edge_label e,
                 Edge.target e))
       ) in

  if xdot then
    Visualization.to_dot ~with_rule_index stdout atn edges
  else
    List.iter (fun (s,e,t) ->
        Fmt.(pf stdout "%a -[%s]-> %a\n"
               dump_state_id s
               e
               dump_state_id t)) edges

let cmd =
let file =
  let docv = "The file to convert to dot format." in
  let absent = "absent." in
  Arg.(required & pos 0 (some string) None & info [] ~absent ~docv) in

let xdot =
  let doc = "output graphviz (xdot) format." in
  Arg.(value & flag & info ["x"; "xdot"] ~doc) in

let with_rule_index =
  let doc = "include ruleIndex in state-label." in
  Arg.(value & flag & info ["with-rule-index"] ~doc) in

  let ruleIndex =
    let docv = "rule-index" in
    Arg.(value & opt int (-1) & info ["r"; "rule-index"] ~docv) in

  let doc = "convert an ATN to dot" in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "graph" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ file and+ ruleIndex and+ xdot and+ with_rule_index in
  graph ~with_rule_index ~xdot ~ruleIndex file ;
  Cmdliner.Cmd.Exit.ok
end

let cmd =
  let doc = "The tool synopsis is TODO" in
  Cmd.group (Cmd.info "TODO" ~version:"%%VERSION%%" ~doc) @@
  [EmitATN.cmd; EmitLexer.cmd; Dump.cmd; Graph.cmd]

let main () = Cmd.eval' cmd
let () = if !Sys.interactive then () else exit (main ())
