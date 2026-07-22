

open Pa_ppx_utils
open Antlr
open Cmdliner
open Cmdliner.Term.Syntax


let test ~show_dfa ~disable_logging ~json_log_file file =
  json_log_file |> Option.iter Tracelog.set_log_file ;
  if disable_logging then
    Tracelog._enabled := false ;
  let caches = Simulate.Caches.mk () in
  Exec.file_init ~dfast_cache:caches.dfast ~acs_cache:caches.acs ~ac_cache:caches.ac () ;
  let input : Exec.IS.t =
    Tracelog.with_disabled (fun () ->
        Exec.IS.init (file |> Fpath.v |> Bos.OS.File.read |> Result.get_ok) ()
      ) ()
  in
  let lex = L.init ~input ~output:stdout in
  let strm : Exec.T.t Stream.t = Exec.TS.init lex in
  let l = Std.list_of_stream strm in
  l |> List.iter (fun t -> Fmt.(pf stdout "%s\n" (Exec.T.__str__ t))) ;
  if show_dfa then
    let open Exec in
    Fmt.(pf stdout "%s" (DFA.toLexerString lex.L._interp.LAS.decisionToDFA.(C._DEFAULT_MODE)))

module Test = struct

let file = Arg.(value & pos 0 file "" & info [] ~docv:"input-file")

let json_log_file =
  let doc = "json-log-file: file destination for JSON log, instead of stdout." in
  Arg.(value & opt (some string) None & info ["json-log-file"] ~doc)

let disable_logging =
  let doc = "disable JSON logging." in
  Arg.(value & flag & info ["disable-logging"] ~doc)

let show_dfa =
  let doc = "show DFA after run." in
  Arg.(value & flag & info ["show-dfa"] ~doc)

let cmd =
  let doc = "test" in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "test" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ file and+ disable_logging and+ show_dfa and+ json_log_file in
  test ~disable_logging ~json_log_file ~show_dfa file ;
  Cmdliner.Cmd.Exit.ok
end

let cmd =
  let doc = "The tool synopsis is TODO" in
  Cmd.group (Cmd.info "TODO" ~version:"%%VERSION%%" ~doc) @@
  [Test.cmd
  ]

let main () = Cmd.eval' cmd
let () = if !Sys.interactive then () else exit (main ())
