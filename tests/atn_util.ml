(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.deriving_plugins.std *)

let hey () = Cmdliner.Cmd.Exit.ok
let ho () = Cmdliner.Cmd.Exit.ok

open Pa_ppx_utils
open Coll
open Cmdliner
open Cmdliner.Term.Syntax

open Antlr
open Atn

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
                         (Edge.serialization_type e))
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
  if json then
    Fmt.(pf stdout "Filename: %s@.%a@." file (Yojson.Safe.pretty_print ~std:true) (Yojson.Safe.sort (Antlr.Atn.to_yojson atn)))
  else
    Fmt.(pf stdout "Filename: %s@.%a@." file Antlr.Atn.dump atn) ;
  if check then
    check_rule_separation atn ;
  ()

let dump_cmd =
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

let graph ~xdot ~ruleIndex file =
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
    | t -> Edge.serialization_type t in
  let fmt_st states snum =
    let st = State.get_state states snum in
 Fmt.(str "%a(%a)" dump_state_id snum
        Node.pp_atn_state_type_t (Node.serialization_name st.State.node) ) in
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
    Visualization.to_dot stdout atn edges
  else
    List.iter (fun (s,e,t) ->
        Fmt.(pf stdout "%a -[%s]-> %a\n"
               dump_state_id s
               e
               dump_state_id t)) edges

let graph_cmd =
let file =
  let docv = "The file to convert to dot format." in
  let absent = "absent." in
  Arg.(required & pos 0 (some string) None & info [] ~absent ~docv) in

let xdot =
  let doc = "output graphviz (xdot) format." in
  Arg.(value & flag & info ["x"; "xdot"] ~doc) in

  let ruleIndex =
    let docv = "rule-index" in
    Arg.(value & opt int (-1) & info ["r"; "rule-index"] ~docv) in

  let doc = "convert an ATN to dot" in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "graph" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ file and+ ruleIndex and+ xdot in
  graph ~xdot ~ruleIndex file ;
  Cmdliner.Cmd.Exit.ok

let flag = Arg.(value & flag & info ["flag"] ~doc:"The flag")
let infile =
  let doc = "$(docv) is the input file. Use $(b,-) for $(b,stdin)." in
  Arg.(value & pos 0 filepath "-" & info [] ~doc ~docv:"FILE")

let hey_cmd =
  let doc = "The hey command synopsis is TODO" in
  Cmd.make (Cmd.info "hey" ~doc) @@
  let+ unit = Term.const () in
  ho ()

let ho_cmd =
  let doc = "The ho command synopsis is TODO" in
  Cmd.make (Cmd.info "ho" ~doc) @@
  let+ unit = Term.const () in
  ho unit

let cmd =
  let doc = "The tool synopsis is TODO" in
  Cmd.group (Cmd.info "TODO" ~version:"%%VERSION%%" ~doc) @@
  [hey_cmd; ho_cmd; dump_cmd; graph_cmd]

let main () = Cmd.eval' cmd
let () = if !Sys.interactive then () else exit (main ())
