

open Pa_ppx_utils
open Antlr
open Cmdliner
open Cmdliner.Term.Syntax


let test ~json_log_file file =
  Tracelog._enabled := true ;
  json_log_file |> Option.iter Tracelog.set_log_file ;
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
  let open Exec in
  Fmt.(pf stdout "%s" (DFA.toLexerString lex.L._interp.LAS.decisionToDFA.(C._DEFAULT_MODE)))

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
