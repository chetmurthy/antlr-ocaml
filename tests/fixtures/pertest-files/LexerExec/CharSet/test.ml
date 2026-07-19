

open Antlr
open Cmdliner
open Cmdliner.Term.Syntax


let test ~json_log_file file =
  Tracelog._enabled := true ;
  json_log_file |> Option.iter Tracelog.set_log_file ;
  let input : Exec.IS.t = Exec.IS.init (file |> Fpath.v |> Bos.OS.File.read |> Result.get_ok) () in
  let l = L.init ~input ~output:stdout in
  let strm : Exec.T.t Stream.t = Util.stream_of_function_until (fun () -> Exec.L.nextToken l) Exec.T.is_eof in
  strm 


module Test = struct

let file = Arg.(value & pos 0 file "" & info [] ~docv:"input-file")

let json_log_file =
  let doc = "json-log-file: file destination for JSON log, instead of stdout." in
  Arg.(value & opt (some string) None & info ["json-log-file"] ~doc)

let cmd =
  let doc = "test" in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "test" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ file and+ json_log_file in
  test ~json_log_file file ;
  Cmdliner.Cmd.Exit.ok
end

let cmd =
  let doc = "The tool synopsis is TODO" in
  Cmd.group (Cmd.info "TODO" ~version:"%%VERSION%%" ~doc) @@
  [Test.cmd
  ]

let main () = Cmd.eval' cmd
let () = if !Sys.interactive then () else exit (main ())
