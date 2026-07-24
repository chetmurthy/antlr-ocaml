

open Pa_ppx_utils
open Antlr
open Cmdliner
open Cmdliner.Term.Syntax
open Camlp5_adapter

let __str__ self =
  let symbolic_names = (fst L.atns.lexer).Interp.Raw.token_symbolic_names in
  let type2string n =
    if n < 0 || n >= Array.length symbolic_names then string_of_int n
    else match symbolic_names.(n) with
           None -> string_of_int n
         | Some s -> Fmt.(str "%s=%d" s n) in
  let open Exec in
  let open Exec.T in
  let fmt_string pps n = Fmt.(pf pps "%s" n) in
  let fmt_int pps n = Fmt.(pf pps "%d" n) in
  let fmt_option ppsub pps nopt =
    match nopt with
      None -> Fmt.(pf pps "None")
    | Some n -> Fmt.(pf pps "%a" ppsub n) in
  let fmt_channel pps c =
    if c > 0 then Fmt.(pf pps ",channel=%d" c) else Fmt.(pf pps "") in
  Fmt.(str "[%@%a,%a:%a='%s',<%a>%a,%a:%a]"
         (fmt_option fmt_int) self.tokenIndex
         (fmt_option fmt_int) self.start
         (fmt_option fmt_int) self.stop
         (match self._text with
            Some txt -> Util.escape_string txt
          | None ->
             assert (Std.isSome self.start) ;
             assert (Std.isSome self.stop) ;
             let start = Std.outSome self.start in
             let stop = Std.outSome self.stop in
             let n = IS.size self._input in
             if start < n && stop < n then
               Util.escape_string (IS.getText self._input start stop)
             else "<EOF>"
         )
         (fmt_option fmt_string) (Option.map type2string self.type_)
         (fmt_option fmt_channel) self.channel
         (fmt_option fmt_int) self.line
         (fmt_option fmt_int) self.column)

let test ~show_dfa ~via_camlp5 ~with_locations ~disable_logging ~json_log_file file =
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
  let pp_token pps t =
    let loc = ploc_of_token ~file t in
    let prefix =
    if with_locations then
      let fname = Ploc.file_name loc in
      let linen = Ploc.line_nb loc in
      let bcoln = 1 + Ploc.((first_pos loc) - (bol_pos loc)) in
      let ecoln = 1 + Ploc.((last_pos loc) - (bol_pos loc)) in
      Printf.sprintf "File \"%s\", line %d, characters %d-%d: "
        fname linen bcoln ecoln
    else "" in
    let tokstring =
      if via_camlp5 then
        let tok = pattern_of_token t in
        Fmt.(str "%a" (parens (pair ~sep:(const string ", ") string Dump.string)) tok)
      else __str__ t in
    Printf.fprintf stdout "%s%s\n" prefix tokstring in
  l |> List.iter (fun t -> Fmt.(pf stdout "%a" pp_token t)) ;
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

let with_locations =
  let doc = "with locations." in
  Arg.(value & flag & info ["with-locations"] ~doc)

let via_camlp5 =
  let doc = "convert token to camlp5 pattern, then print." in
  Arg.(value & flag & info ["via-camlp5"] ~doc)

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
  let+ file and+ via_camlp5 and+ with_locations and+ disable_logging and+ show_dfa and+ json_log_file in
  test ~disable_logging ~json_log_file ~with_locations ~via_camlp5 ~show_dfa file ;
  Cmdliner.Cmd.Exit.ok
end

let cmd =
  let doc = "The tool synopsis is TODO" in
  Cmd.group (Cmd.info "TODO" ~version:"%%VERSION%%" ~doc) @@
  [Test.cmd
  ]

let main () = Cmd.eval' cmd
let () = if !Sys.interactive then () else exit (main ())
