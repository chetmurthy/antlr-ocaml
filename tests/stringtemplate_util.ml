(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.deriving_plugins.std *)

open Pa_ppx_utils
open Pa_ppx_base
open Ppxutil

Pa_ppx_runtime.Exceptions.Ploc.pp_loc_verbose := true ;;

open Stringtemplate

let filename_to_testname file =
  Fpath.(file |> v |> rem_ext |> basename)

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

let multi =
  let doc = "process a MULTI file (multiple testcases in a single file)." in
  Arg.(value & flag & info ["m";"multi"] ~doc)

module Generate = struct

let generate_one_test ~debug ~force ~destroot ~testname th =
  let open Testharness in
  if destroot = "" then
    failwith "must specify --dest-root|-d" ;
  let destroot = Fpath.v destroot in
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

let generate_st4_test ~debug ~force ~destroot ~multi ~testname file =
  let open Testharness in
  if destroot = "" then
    failwith "must specify --dest-root|-d" ;
  if multi then
    let thl = Multi.load ~file in
    thl
    |> List.iter (fun (testname,th) ->
           generate_one_test ~debug ~force ~destroot ~testname th)
  else
  let th = load ~file in
  let testname = if testname <> "" then testname else filename_to_testname file in
  generate_one_test ~debug ~force ~destroot ~testname th

let cmd =
  let doc = "generate a testdir for a Stringtemplate4 test" in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "generate" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ file and+ debug and+ force and+ multi and+ destroot and+ testname in
  generate_st4_test ~debug ~force ~destroot ~testname ~multi file ;
  Cmdliner.Cmd.Exit.ok

end

module Compile = struct
let compile_one_test ~debug ~destroot ~testname th =
  let open Testharness in
  if destroot = "" then
    failwith "must specify --dest-root|-d" ;
  let destroot = Fpath.v destroot in
  let destdir = Fpath.(append destroot (v testname)) in
  if not (destdir |> Bos.OS.Dir.exists |> Result.get_ok) then
      Fmt.(failwithf "destdir %s must already exist!" (Fpath.to_string destdir));
  let cmd = Fmt.(str "make -C %s compile" (Fpath.to_string destdir)) in
  cmd |> system |> Rresult.R.failwith_error_msg ;
  ()

let compile_st4_test ~debug ~destroot ~multi ~testname file =
  let open Testharness in
  if destroot = "" then
    failwith "must specify --dest-root|-d" ;
  if multi then
    let thl = Multi.load ~file in
    thl
    |> List.iter (fun (testname,th) ->
           compile_one_test ~debug ~destroot ~testname th)
  else
  let th = load ~file in
  let testname = if testname <> "" then testname else filename_to_testname file in
  compile_one_test ~debug ~destroot ~testname th

let cmd =
  let doc = "compile testdir for a Stringtemplate4 test" in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "compile" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ file and+ debug and+ multi and+ destroot and+ testname in
  compile_st4_test ~debug ~multi ~destroot ~testname file ;
  Cmdliner.Cmd.Exit.ok
end

module Execute = struct

let execute_one_test ~debug ~destroot ~testname th =
  let open Testharness in
  if destroot = "" then
    failwith "must specify --dest-root|-d" ;
  let destroot = Fpath.v destroot in
  let destdir = Fpath.(append destroot (v testname)) in
  if not (destdir |> Bos.OS.Dir.exists |> Result.get_ok) then
      Fmt.(failwithf "destdir %s must already exist!" (Fpath.to_string destdir));
  let cmd = Fmt.(str "make -C %s test" (Fpath.to_string destdir)) in
  cmd |> system |> Rresult.R.failwith_error_msg ;
  ()

let execute_st4_test ~debug ~destroot ~multi ~testname file =
  let open Testharness in
  if destroot = "" then
    failwith "must specify --dest-root|-d" ;
  if multi then
    let thl = Multi.load ~file in
    thl
    |> List.iter (fun (testname,th) ->
           execute_one_test ~debug ~destroot ~testname th)
  else
  let th = load ~file in
  let testname = if testname <> "" then testname else filename_to_testname file in
  execute_one_test ~debug ~destroot ~testname th

let cmd =
  let doc = "execute testdir for a Stringtemplate4 test" in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "execute" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ file and+ debug and+ multi and+ destroot and+ testname in
  execute_st4_test ~debug ~multi ~destroot ~testname file ;
  Cmdliner.Cmd.Exit.ok
end

module Check = struct
let check ~testname th output =
  let open Testharness in
  let output =
    match [%match {|<RoNnIe\|(.*)\|RaYgUn>|} / strings !1 s] output with
      None -> Fmt.(failwithf "test %s: no output found" testname)
    | Some output -> output in
  if output <> th.expected then begin
      Fmt.(pf stderr "st4_util check: test %s: output didn't match@.expected: {foo|%s|foo}@.actual: {bar|%s|bar}@."
             testname th.expected output) ;
      Fmt.(failwithf "test %s: output didn't match@.expected: {foo|%s|foo}@.actual: {bar|%s|bar}@."
             testname th.expected output)
    end


let check_one_test ~debug ~destroot ~testname th =
  let open Testharness in
  if destroot = "" then
    failwith "must specify --dest-root|-d" ;
  let destroot = Fpath.v destroot in
  let destdir = Fpath.(append destroot (v testname)) in
  if not (destdir |> Bos.OS.Dir.exists |> Result.get_ok) then
      Fmt.(failwithf "destdir %s must already exist!" (Fpath.to_string destdir));
  let outputfile = Fpath.(append destdir (v "output")) in
  let output_txt = outputfile |> Bos.OS.File.read |> Rresult.R.failwith_error_msg in
  check ~testname th output_txt

let check_st4_test ~debug ~destroot ~multi ~testname file =
  let open Testharness in
  if destroot = "" then
    failwith "must specify --dest-root|-d" ;
  if multi then
    let thl = Multi.load ~file in
    thl
    |> List.iter (fun (testname,th) ->
           check_one_test ~debug ~destroot ~testname th)
  else
  let th = load ~file in
  let testname = if testname <> "" then testname else filename_to_testname file in
  check_one_test ~debug ~destroot ~testname th

let cmd =
  let doc = "check output for a Stringtemplate4 test" in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "check" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ file and+ debug and+ multi and+ destroot and+ testname in
  check_st4_test ~debug ~multi ~destroot ~testname file ;
  Cmdliner.Cmd.Exit.ok
end

module Full = struct

let full_one_test ~debug ~force ~destroot ~testname th =
  Generate.generate_one_test ~debug ~force ~destroot ~testname th ;
  Compile.compile_one_test ~debug ~destroot ~testname th ;
  Execute.execute_one_test ~debug ~destroot ~testname th ;
  Check.check_one_test ~debug ~destroot ~testname th ;
  ()

let full_st4_test ~debug ~destroot ~force ~multi ~testname file =
  let open Testharness in
  if destroot = "" then
    failwith "must specify --dest-root|-d" ;
  if multi then
    let thl = Multi.load ~file in
    thl
    |> List.iter (fun (testname,th) ->
           full_one_test ~debug ~force ~destroot ~testname th)
  else
  let th = load ~file in
  let testname = if testname <> "" then testname else filename_to_testname file in
  full_one_test ~debug ~force ~destroot ~testname th

let cmd =
  let doc = "full test trip for a Stringtemplate4 test" in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "full" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ file and+ debug and+ force and+ multi and+ destroot and+ testname in
  full_st4_test ~debug ~force ~multi ~destroot ~testname file ;
  Cmdliner.Cmd.Exit.ok
end

let cmd =
  let doc = "The tool synopsis is TODO" in
  Cmd.group (Cmd.info "TODO" ~version:"%%VERSION%%" ~doc) @@
  [Generate.cmd; Compile.cmd; Execute.cmd; Check.cmd; Full.cmd]

let main () = Cmd.eval' cmd
let () = if !Sys.interactive then () else exit (main ())
