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
  [hey_cmd; ho_cmd; dump_cmd]

let main () = Cmd.eval' cmd
let () = if !Sys.interactive then () else exit (main ())
