(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.deriving_plugins.std *)

open Pa_ppx_utils

(** generate an antlrtest directory from a test
    descriptor and a template directory

    (a) read the descriptor
    (b) 

 *)

let generate_antlrtest ~debug ~helperfile ~destdir ~templatedir file =
  let open Antlrtest in
  if templatedir = "" then
    failwith "must specify --template-dir|-t" ;
  let templatedir = Fpath.v templatedir in
  if helperfile = "" then
    failwith "must specify --helper-file|-h" ;
  let helperfile = Fpath.v helperfile in
  if destdir = "" then
    failwith "must specify --dest-dir|-d" ;
  let destdir = Fpath.v destdir in
  if destdir |> Bos.OS.Dir.exists |> Result.get_ok then
    failwith "destdir must not already exist!" ;

  let module D = Descriptor in
  let d = D.load file in
  let env = D.to_env d in
  let includes = Stg.Group.load helperfile in
  let env = {(env) with includes = includes } in

  let templatefiles =
    templatedir |> (Bos.OS.Dir.contents ~rel:true) |> Result.get_ok in

  let gen_one f =
    let full = Fpath.append templatedir f in
    let dstfull = Fpath.append destdir f in
    (dstfull, Stg.transform_file env full) in

  let generated_files = List.map gen_one templatefiles in
  let generated_files =
    [Fpath.(append destdir (v Fmt.(str "%s.g4" d.grammar_name))),
     Stg.transform env d.D.grammar
    ;Fpath.(append destdir (v "input")),
     D.clean_triple_quotes (match D.stanza_opt d "input" with None -> "" | Some s -> s)
    ;Fpath.(append destdir (v "output")),
     D.clean_triple_quotes (match D.stanza_opt d "output" with None -> "" | Some s -> s)
    ]@generated_files in
  let generated_files =
    if d.D.is_composite then
      let l =
        d.D.slaveGrammars
        |> List.map (fun slavetxt ->
               let slave_name = D.grammar_name ~file slavetxt in
               (Fpath.(append destdir (v Fmt.(str "%s.g4" slave_name))),
                Stg.transform env slavetxt)) in
      l@generated_files
    else generated_files in

  let generated_files =
    generated_files
    |> List.map (fun (f, txt) ->
           if Std.ends_with ~pat:".py" (Fpath.to_string f) then
             (f, Stg.clean_blank_lines txt)
           else (f,txt)) in

  destdir |> Bos.OS.Dir.create ~mode:0o755 ~path:true |> Result.get_ok ;
  generated_files
  |> List.iter
       (fun (full, txt) ->
         Bos.OS.File.write ~mode:0o644 full txt |> Result.get_ok) ;
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

let destdir =
  let docv = "The generated destination directory." in
  Arg.(value & opt string "" & info ["d"; "dest-dir"] ~docv)

let debug =
  let doc = "enable debugging." in
  Arg.(value & flag & info ["debug"] ~doc)

let generate_cmd =
  let doc = "generate a testdir from a test descriptor" in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "generate_antlrtest" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ file and+ debug and+ templatedir and+ destdir and+ helperfile in
  generate_antlrtest ~debug ~helperfile ~destdir ~templatedir file

let main () = Cmd.eval generate_cmd
let () = if !Sys.interactive then () else exit (main ())
