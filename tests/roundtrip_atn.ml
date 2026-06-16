


(*
"/home/chet/Hack/Antlr/src/calc/gen-java/CalcLexer.interp" |> Fpath.v |>  Bos.OS.File.read |> Result.get_ok |> Antlr.Interp_syntax.read_raw |> Antlr.Atn.deser ;;
 *)

let roundtrip file =
  let atn =
    file
    |> Fpath.v
    |>  Bos.OS.File.read
    |> Result.get_ok
    |> Antlr.Interp_syntax.read_raw
    |> Antlr.Atn.deser in
  Fmt.(pf stdout "%a@." Antlr.Atn.dump atn)

open Cmdliner
open Cmdliner.Term.Syntax

let file =
  let docv = "The file to read-and-dump." in
  let absent = "absent." in
  Arg.(required & pos 0 (some string) None & info [] ~absent ~docv)

let roundtrip_cmd =
  let doc = "Roundtrip a file" in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "roundtrip_atn" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ file in
  roundtrip file

let main () = Cmd.eval roundtrip_cmd
let () = if !Sys.interactive then () else exit (main ())
