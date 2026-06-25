(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.deriving_plugins.std *)

let hey () = Cmdliner.Cmd.Exit.ok
let ho () = Cmdliner.Cmd.Exit.ok

let dump ~json ~debug ~disable_verify file =
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
    Fmt.(pf stdout "Filename: %s@.%a@." file Antlr.Atn.dump atn)

let graph ~xdot ~ruleIndex file =
  let ruleIndex = if ruleIndex = -1 then None else Some ruleIndex in
  let open Antlr in
  let open Atn in
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
    | AtomTransition {label} -> Fmt.(str "<atom %a>" IntervalSet.dump label)
    | t when Edge.isEpsilon t -> "<eps>"
    | t -> "" in
  let fmt_st s = Fmt.(str "%a" dump_state_id s) in
  let edges =
  states
  |> List.concat_map
       (fun st ->
         st.State.transitions
         |> List.map (fun e ->
                (fmt_st st.State.stateNumber,
                 edge_label e,
                 fmt_st (Edge.target e)))
       ) in

  if xdot then
    Visualization.PackageGraph.to_dot stdout edges
  else
    List.iter (fun (s,e,t) ->
        Fmt.(pf stdout "%s -[%s]-> %s\n" s e t)) edges

open Cmdliner
open Cmdliner.Term.Syntax

let dump_cmd =
let file =
  let docv = "The file to read-and-dump." in
  let absent = "absent." in
  Arg.(required & pos 0 (some string) None & info [] ~absent ~docv) in

let debug =
  let doc = "enable debugging." in
  Arg.(value & flag & info ["debug"] ~doc) in

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
  let+ file and+ debug and+ json and+ disable_verify in
  dump ~json ~debug ~disable_verify file ;
  Cmdliner.Cmd.Exit.ok

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
