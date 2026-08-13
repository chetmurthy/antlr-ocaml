

open Pa_ppx_utils
open Antlr
open Cmdliner
open Cmdliner.Term.Syntax

module TestLexer(Lex : Exec.FULL_LEXER with type lexer_t = Exec.L.lexer_t) = struct

let type2string lexer n =
  let ty2name = (fst Lex.full_atn).Interp.Raw.token_symbolic_names in
  if n < 0 then Some "EOF"
  else ty2name.(n)

let _Token_named_type__str__ lexer (self : Exec.T.t) =
  let open Exec.T in
  let open Lex in
  let fmt_int pps n = Fmt.(pf pps "%d" n) in
  let fmt_option ppsub pps nopt =
    match nopt with
      None -> Fmt.(pf pps "None")
    | Some n -> Fmt.(pf pps "%a" ppsub n) in
  let fmt_channel pps c =
    if c > 0 then Fmt.(pf pps ",channel=%d" c) else Fmt.(pf pps "") in
  let esc_text = Util.escape_string (Exec.R.text lexer.recog lexer._interp.Exec.LAS.cursor) in
  Fmt.(str "[%@%a,%a:%a='%s',<%a>%a,%a:%a]"
         (fmt_option fmt_int) self.tokenIndex
         (fmt_option fmt_int) self.start
         (fmt_option fmt_int) self.stop
         esc_text
         (fmt_option string) (type2string lexer (Std.outSome self.type_))
         (fmt_option fmt_channel) self.channel
         (fmt_option fmt_int) self.line
         (fmt_option fmt_int) self.column)

module TS = Exec.TokenStreamFunctor(Lex)

let test ~show_dfa ~disable_logging ~named_types ~json_log_file file =
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
  let lex = Lex.full_init ~input ~output:stdout in
  Exec.(R.mode lex.L.recog L_constants.Modes._Outside) ;  
  let strm : Exec.T.t Stream.t = TS.init lex in
  let l = Std.list_of_stream strm in
  l |> List.iter (fun t -> Fmt.(pf stdout "%s\n" (Exec.T.__str__ t))) ;
  if show_dfa then
    let open Exec in
    Fmt.(pf stdout "%s" (DFA.toLexerString lex.Lex._interp.LAS.decisionToDFA.(C._DEFAULT_MODE)))
end

module Test = TestLexer(L.Full)

module TestCmd = struct

let file = Arg.(value & pos 0 file "" & info [] ~docv:"input-file")

let json_log_file =
  let doc = "json-log-file: file destination for JSON log, instead of stdout." in
  Arg.(value & opt (some string) None & info ["json-log-file"] ~doc)

let disable_logging =
  let doc = "disable JSON logging." in
  Arg.(value & flag & info ["disable-logging"] ~doc)

let named_types =
  let doc = "print tokens with named types." in
  Arg.(value & flag & info ["named-types"] ~doc)

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
  let+ file and+ disable_logging and+ named_types and+ show_dfa and+ json_log_file in
  Test.test ~disable_logging ~named_types ~json_log_file ~show_dfa file ;
  Cmdliner.Cmd.Exit.ok
end

let cmd =
  let doc = "The tool synopsis is TODO" in
  Cmd.group (Cmd.info "TODO" ~version:"%%VERSION%%" ~doc) @@
  [TestCmd.cmd
  ]

let main () = Cmd.eval' cmd
let () = if !Sys.interactive then () else exit (main ())
