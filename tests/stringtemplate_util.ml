(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.deriving_plugins.std *)

open Pa_ppx_utils
open Pa_ppx_base
open Ppxutil

Pa_ppx_runtime.Exceptions.Ploc.pp_loc_verbose := true ;;

open Stringtemplate

let filename_to_testname file =
  Fpath.(file |> v |> rem_ext |> basename)

let generate_st4_test ~debug ~force ~destroot ~testname file =
  let open Testharness in
  if destroot = "" then
    failwith "must specify --dest-root|-d" ;
  let destroot = Fpath.v destroot in
  let th = load ~file in
  let testname = if testname <> "" then testname else filename_to_testname file in
  let testfilename = th.classname^".java" in
  let destdir = Fpath.(append destroot (v testname)) in
  if destdir |> Bos.OS.Dir.exists |> Result.get_ok then
    if force then
      destdir |> Bos.OS.Dir.delete ~must_exist:true ~recurse:true |> Rresult.R.failwith_error_msg
    else
      Fmt.(failwithf "destdir %s must not already exist!" (Fpath.to_string destdir));

  destdir |> Bos.OS.Dir.create ~mode:0o755 ~path:true |> Rresult.R.failwith_error_msg ;
  th.groupfile
  |> Option.map (fun (groupfilename, contents) ->
         let full = Fpath.(append destdir (v groupfilename)) in
         Bos.OS.File.write ~mode:0o644 full contents |> Rresult.R.failwith_error_msg) ;
  let javafile  = Fpath.(append destdir (v testfilename)) in
  Bos.OS.File.write ~mode:0o644 javafile Fmt.(str "%a" emit th) |> Rresult.R.failwith_error_msg ;
  let maketxt =
    Fmt.(str {|
test:
	java -cp classes:/usr/share/java/stringtemplate4-4.0.8.jar:$(CLASSPATH) %s > output.NEW && mv output.NEW output

compile:
	javac -d classes %s.java
|}
           th.classname th.classname) in
  let makefile  = Fpath.(append destdir (v "Makefile")) in
  Bos.OS.File.write ~mode:0o644 makefile maketxt |> Rresult.R.failwith_error_msg ;
  
  ()

let system cmd =
  let st = Unix.system cmd in
  match st with
    Unix.WEXITED 0 -> Ok ()
  | Unix.WEXITED n -> exit n
  | WSIGNALED n ->
     Error
       (`Msg
          (Printf.sprintf "st4_util: command killed by signal %d" n))
  | WSTOPPED n ->
     Error
       (`Msg
          (Printf.sprintf "st4_util: command stopped by signal %d" n))

let compile_st4_test ~debug ~force ~destroot ~testname file =
  let open Testharness in
  if destroot = "" then
    failwith "must specify --dest-root|-d" ;
  let destroot = Fpath.v destroot in
  let th = load ~file in
  let testname = if testname <> "" then testname else filename_to_testname file in
  let destdir = Fpath.(append destroot (v testname)) in
  if not (destdir |> Bos.OS.Dir.exists |> Result.get_ok) then
      Fmt.(failwithf "destdir %s must already exist!" (Fpath.to_string destdir));
  let cmd = Fmt.(str "make -C %s compile" (Fpath.to_string destdir)) in
  cmd |> system |> Rresult.R.failwith_error_msg ;
  ()

let execute_st4_test ~debug ~force ~destroot ~testname file =
  let open Testharness in
  if destroot = "" then
    failwith "must specify --dest-root|-d" ;
  let destroot = Fpath.v destroot in
  let th = load ~file in
  let testname = if testname <> "" then testname else filename_to_testname file in
  let destdir = Fpath.(append destroot (v testname)) in
  if not (destdir |> Bos.OS.Dir.exists |> Result.get_ok) then
      Fmt.(failwithf "destdir %s must already exist!" (Fpath.to_string destdir));
  let cmd = Fmt.(str "make -C %s test" (Fpath.to_string destdir)) in
  cmd |> system |> Rresult.R.failwith_error_msg ;
  ()

open Cmdliner
open Cmdliner.Term.Syntax

let file =
  let docv = "The test descriptor file." in
  let absent = "absent." in
  Arg.(required & pos 0 (some file) None & info [] ~absent ~docv)

let testname =
  let docv = "The name of the test directory (if absent, taken from test JSON)." in
  Arg.(value & opt string "" & info ["n"; "test-name"] ~docv)

let destroot =
  let docv = "The generated destination root directory." in
  Arg.(value & opt string "" & info ["d"; "dest-root"] ~docv)

let debug =
  let doc = "enable debugging." in
  Arg.(value & flag & info ["debug"] ~doc)

let force =
  let doc = "force generation (delete existing directory)." in
  Arg.(value & flag & info ["f";"force"] ~doc)

let generate_cmd =
  let doc = "generate a testdir for a Stringtemplate4 test" in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "generate" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ file and+ debug and+ force and+ destroot and+ testname in
  generate_st4_test ~debug ~force ~destroot ~testname file ;
  Cmdliner.Cmd.Exit.ok

let compile_cmd =
  let doc = "compile testdir for a Stringtemplate4 test" in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "compile" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ file and+ debug and+ destroot and+ testname in
  compile_st4_test ~debug ~force ~destroot ~testname file ;
  Cmdliner.Cmd.Exit.ok

let execute_cmd =
  let doc = "execute testdir for a Stringtemplate4 test" in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "execute" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ file and+ debug and+ destroot and+ testname in
  execute_st4_test ~debug ~force ~destroot ~testname file ;
  Cmdliner.Cmd.Exit.ok

let cmd =
  let doc = "The tool synopsis is TODO" in
  Cmd.group (Cmd.info "TODO" ~version:"%%VERSION%%" ~doc) @@
  [generate_cmd; compile_cmd; execute_cmd]

let main () = Cmd.eval' cmd
let () = if !Sys.interactive then () else exit (main ())
