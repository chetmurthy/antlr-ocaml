


(*
"/home/chet/Hack/Antlr/src/calc/gen-java/CalcLexer.interp" |> Fpath.v |>  Bos.OS.File.read |> Result.get_ok |> Antlr.Interp_syntax.read_raw |> Antlr.Atn.deser ;;
 *)

let roundtrip ~json ~debug ~disable_verify file =
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

let file =
  let docv = "The file to read-and-dump." in
  let absent = "absent." in
  Arg.(required & pos 0 (some string) None & info [] ~absent ~docv)

let debug =
  let doc = "enable debugging." in
  Arg.(value & flag & info ["debug"] ~doc)

let json =
  let doc = "JSON output." in
  Arg.(value & flag & info ["json"] ~doc)

let disable_verify =
  let doc = "disable verify." in
  Arg.(value & flag & info ["disable-verify"] ~doc)

let roundtrip_cmd =
  let doc = "Roundtrip a file" in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "roundtrip_atn" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ file and+ debug and+ json and+ disable_verify in
  roundtrip ~json ~debug ~disable_verify file

let main () = Cmd.eval roundtrip_cmd
let () = if !Sys.interactive then () else exit (main ())
