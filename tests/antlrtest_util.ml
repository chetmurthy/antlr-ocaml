(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.deriving_plugins.std *)

open Pa_ppx_utils
open Pa_ppx_base
open Ppxutil

Pa_ppx_runtime.Exceptions.Ploc.pp_loc_verbose := true ;;

open Antlr

let caches = Simulate.Caches.mk () ;;
Exec.file_init ~dfast_cache:caches.dfast ~acs_cache:caches.acs ~ac_cache:caches.ac () ;;

open ST4.Api

(** generate an antlrtest directory from a test
    descriptor and a template directory

    (a) read the descriptor
    (b) 

 *)

[
  (
    {|<ToStringTree("$r.ctx"):writeln()>|},
    {|print($r.ctx.toStringTree(recog=self), file=self._output)|}
  )
; (
    {|<ToStringTree("$ctx"):writeln()>|},
    {|print($ctx.toStringTree(recog=self), file=self._output)|}
  )
; (
    {|<ContextMember("$ctx", "r"):ToStringTree():writeln()>|},
    {|print($ctx.r.toStringTree(recog=self), file=self._output)|}
  )
; (
    {|<ContextMember("$ctx", "r"):WalkListener()>|},
    {|if "." in __name__:
    from .TListener import TListener
else:
    from TListener import TListener
TParser.LeafListener.__bases__ = (TListener,)
walker = ParseTreeWalker()
walker.walk(TParser.LeafListener(self._output), $ctx.r)|}
  )
] |> List.iter
Antlrtest.Stg.Template.add_include_hack ;;

let generate_antlrtest ~debug ~helperfile ~destroot ~testname ~templatedir file =
  let open Antlrtest in
  if templatedir = "" then
    failwith "must specify --template-dir|-t" ;
  let templatedir = Fpath.v templatedir in
  if helperfile = "" then
    failwith "must specify --helper-file|-h" ;
  let helperfile = Fpath.v helperfile in
  if destroot = "" then
    failwith "must specify --dest-root|-d" ;
  if testname = "" then
    failwith "must specify --test-name|-t" ;
  let destroot = Fpath.v destroot in
  let destdir = Fpath.(append destroot (v testname)) in
  if destdir |> Bos.OS.Dir.exists |> Rresult.R.failwith_error_msg then
    Fmt.(failwithf "destdir %s must not already exist!" (Fpath.to_string destdir));
  let destexpected_dir = Fpath.(append destdir (v "expected")) in
  let destraw_dir = Fpath.(append destdir (v "raw")) in

  let module D = Descriptor in
  let d = D.load ~testname file in
  let env = D.to_env d in
  let includes = Stg.Group.load helperfile in
  let env = {(env) with includes = includes } in

  let ctxt = GLC.mk FC.mt in
  let group = Group.load ctxt helperfile in
  let st4simple_env = List.map (fun (n,v) -> (n, [v])) env.attributes in
  let grammar_names = d.D.grammar.name ::(List.map (fun (_,sg) -> sg.D.name) d.D.slaveGrammars) in
  let st4simple_env = ("grammarNames",grammar_names)::st4simple_env in

  if [%match {|python3|} / s i pcre2 pred] (match D.stanza_opt d "skip" with None -> "" | Some (_,(_, s)) -> s) then
    Fmt.(pf stderr "SKIP %s@." file)
 else

  let templatefiles =
    templatedir
    |> (Bos.OS.Dir.contents ~rel:true)
    |> Rresult.R.failwith_error_msg
  in

  let gen_one f =
    let full = Fpath.append templatedir f in
    let dstfull = Fpath.append destdir f in
    let dstnew = dstfull in
    [(dstnew, Template.Simple.transform_file ~group st4simple_env full)
    ]
  in

  let generated_files = List.concat_map gen_one templatefiles in
  let generated_files =
    let grammar_file = Fpath.(append destraw_dir (v Fmt.(str "%s.g4" d.grammar.name))) in
    []
    @[grammar_file, d.D.grammar.txt]
    @generated_files in

  let expected_generated_files =
    let input_l = D.stanza_all d "input" in
    let output_l = D.stanza_all d "output" in
    let errors_l = D.stanza_all d "errors" in

    let file_name root p =
      let namesuff = match List.assoc_opt "name" p with
          Some suff -> "."^suff
        | None -> "" in
      let typesuff = match List.assoc_opt "type" p with
          Some suff -> "-"^suff
        | None -> "" in
      root^typesuff^namesuff in

    let generate_files kind files_l =
      files_l
      |> List.filter_map (fun (p,(_, txt)) ->
             if txt = "" then None
             else
               Some (Fpath.(append destexpected_dir (v (file_name kind p))), txt)
           ) in
      

    let input_files = generate_files "input" input_l in
    let output_files = generate_files "output" output_l in
    let errors_files = generate_files "errors" errors_l in

    input_files@output_files@errors_files
  in

  let generated_files = expected_generated_files@generated_files in
  let generated_files =
    if d.D.is_composite then
      let l =
        d.D.slaveGrammars
        |> List.concat_map (fun (_, slaveg) ->
               let slave_name = slaveg.D.name in
               let slavetxt = slaveg.D.txt in
               let slavefull = Fpath.(append destraw_dir (v Fmt.(str "%s.g4" slave_name))) in
               [(slavefull, slavetxt)
               ]
             ) in
      l@generated_files
    else generated_files in

  let generated_files =
    generated_files
    |> List.map (fun (f, txt) ->
           if Std.ends_with ~pat:".py" (Fpath.to_string f) then
             (f, Stg.clean_blank_lines txt)
           else (f,txt)) in

  ignore(destdir |> Bos.OS.Dir.create ~mode:0o755 ~path:true |> Rresult.R.failwith_error_msg : bool) ;
  ignore(destraw_dir |> Bos.OS.Dir.create ~mode:0o755 ~path:true |> Rresult.R.failwith_error_msg : bool) ;
  ignore(destexpected_dir |> Bos.OS.Dir.create ~mode:0o755 ~path:true |> Rresult.R.failwith_error_msg : bool);
  generated_files
  |> List.iter
       (fun (full, txt) ->
         Bos.OS.File.write ~mode:0o644 full txt |> Rresult.R.failwith_error_msg) ;
  ()
  

open Cmdliner
open Cmdliner.Term.Syntax

let file =
  let docv = "The test descriptor file." in
  let absent = "absent." in
  Arg.(required & pos 0 (some file) None & info [] ~absent ~docv)

let templatedir =
  let docv = "The template directory." in
  Arg.(value & opt dir "fixtures/antlrtest.1" & info ["t"; "template-dir"] ~docv)

let helperfile =
  let docv = "The helper file (for include definitions)." in
  Arg.(value & opt file "fixtures/Python3.test.stg" & info ["h"; "helper-file"] ~docv)

let destroot =
  let docv = "The generated destination root directory." in
  Arg.(value & opt string "" & info ["d"; "dest-root"] ~docv)

let testname =
  let docv = "The name of the test (e.g. LexerExec/CharSet)." in
  Arg.(value & opt string "" & info ["n"; "test-name"] ~docv)

let debug =
  let doc = "enable debugging." in
  Arg.(value & flag & info ["debug"] ~doc)

let generate_cmd =
  let doc = "generate a testdir from a test descriptor" in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "generate" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ file and+ debug and+ templatedir and+ destroot and+ testname and+ helperfile in
  generate_antlrtest ~debug ~helperfile ~destroot ~testname ~templatedir file ;
  Cmdliner.Cmd.Exit.ok

let cmd =
  let doc = "The tool synopsis is TODO" in
  Cmd.group (Cmd.info "TODO" ~version:"%%VERSION%%" ~doc) @@
  [generate_cmd]

let main () = Cmd.eval' cmd
let () = if !Sys.interactive then () else exit (main ())
