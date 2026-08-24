(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.deriving_plugins.std *)

open Pa_ppx_utils
open Pa_ppx_base
open Ppxutil
open Antlr

Pa_ppx_runtime.Exceptions.Ploc.pp_loc_verbose := true ;;

let caches = Simulate.Caches.mk () ;;
Exec.file_init ~dfast_cache:caches.dfast ~acs_cache:caches.acs ~ac_cache:caches.ac () ;;

open ST4
open Testharness

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

let select_tests ~onlytest ~file =
  let last = filename_to_testname file in 
  let prepend_last testname =
    Fpath.(to_string (append (v last) (v testname))) in
  let thl = Multi.load ~file in
  match onlytest with
     None ->
     thl |> List.map (fun (testname, th) -> (prepend_last testname, th))
  | Some testname ->
     match List.assoc_opt testname thl with
       Some th ->
        [(prepend_last testname, th)]
     | None -> Fmt.(failwithf "ST4_util: selected test %s does not exist in multi-file %s"
                      testname file)

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

let onlytest =
  let docv = "Choose only named test from multi-test file" in
  Arg.(value & opt (some string) None & info ["o"; "only-test"] ~docv)

let debug =
  let doc = "enable debugging." in
  Arg.(value & flag & info ["debug"] ~doc)

let verbose =
  let doc = "enable verbose logging." in
  Arg.(value & flag & info ["v";"verbose"] ~doc)

let force =
  let doc = "force generation (delete existing directory)." in
  Arg.(value & flag & info ["f";"force"] ~doc)

let multi =
  let doc = "process a MULTI file (multiple testcases in a single file)." in
  Arg.(value & flag & info ["m";"multi"] ~doc)

module Generate = struct

let one_test ~debug ~verbose ~force ~destroot ~testname th =
  if th.ignore then
    Fmt.(pf stderr "[ignore %s]@." testname)
  else begin
      if verbose then Fmt.(pf stderr "[generate %s]@." testname) ;
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
      ((match th.groupfile with None -> [] | Some x -> [x])@th.groupfiles)
      |> List.map (fun (groupfilename, (_, contents)) ->
             let full = Fpath.(append destdir (v groupfilename)) in
             let dir = Fpath.parent full in
             Bos.OS.Dir.create ~path:true ~mode:0o755 dir |> Rresult.R.failwith_error_msg ;
             Bos.OS.File.write ~mode:0o644 full contents |> Rresult.R.failwith_error_msg) ;
      let javafile  = Fpath.(append destdir (v testfilename)) in
      Bos.OS.File.write ~mode:0o644 javafile Fmt.(str "%a" emit th) |> Rresult.R.failwith_error_msg ;
      let maketxt =
        Fmt.(str {|
test: classes
	java -cp classes:$(CLASSPATH) %s > output.NEW 2> errors.NEW && mv output.NEW output && mv errors.NEW errors

test-manually: classes
	java -cp classes:$(CLASSPATH) %s

classes compile: %s.java
	javac -d classes %s.java

clean::
	rm -rf classes *.NEW
|}
               th.classname th.classname th.classname th.classname) in
      let makefile  = Fpath.(append destdir (v "Makefile")) in
      Bos.OS.File.write ~mode:0o644 makefile maketxt |> Rresult.R.failwith_error_msg ;
      ()
    end

let st4_test ~debug ~verbose ~force ~destroot ~onlytest ~multi ~testname file =
  if destroot = "" then
    failwith "must specify --dest-root|-d" ;
  if multi then
    let thl = select_tests ~onlytest ~file in
    thl
    |> List.iter (fun (testname,th) ->
           one_test ~debug ~verbose ~force ~destroot ~testname th)
  else
  let th = load ~file in
  let testname = if testname <> "" then testname else filename_to_testname file in
  one_test ~debug ~verbose ~force ~destroot ~testname th

let cmd =
  let doc = "generate a testdir for a Stringtemplate4 test" in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "generate" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ file and+ debug and+ verbose and+ force and+ onlytest and+ multi and+ destroot and+ testname in
  st4_test ~debug ~verbose ~force ~destroot ~testname ~onlytest ~multi file ;
  Cmdliner.Cmd.Exit.ok

end

module Compile = struct
let one_test ~debug ~verbose ~destroot ~testname th =
  if th.ignore then
    Fmt.(pf stderr "[ignore %s]@." testname)
  else begin
      if verbose then Fmt.(pf stderr "[compile %s]@." testname) ;
      if destroot = "" then
        failwith "must specify --dest-root|-d" ;
      let destroot = Fpath.v destroot in
      let destdir = Fpath.(append destroot (v testname)) in
      if not (destdir |> Bos.OS.Dir.exists |> Result.get_ok) then
        Fmt.(failwithf "destdir %s must already exist!" (Fpath.to_string destdir));
      let cmd = Fmt.(str "make -C %s compile" (Fpath.to_string destdir)) in
      cmd |> system |> Rresult.R.failwith_error_msg ;
      ()
    end

let st4_test ~debug ~verbose ~destroot ~onlytest ~multi ~testname file =
  if destroot = "" then
    failwith "must specify --dest-root|-d" ;
  if multi then
    let thl = select_tests ~onlytest ~file in
    thl
    |> List.iter (fun (testname,th) ->
           one_test ~debug ~verbose ~destroot ~testname th)
  else
  let th = load ~file in
  let testname = if testname <> "" then testname else filename_to_testname file in
  one_test ~debug ~verbose ~destroot ~testname th

let cmd =
  let doc = "compile testdir for a Stringtemplate4 test" in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "compile" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ file and+ debug and+ verbose and+ onlytest and+ multi and+ destroot and+ testname in
  st4_test ~debug ~verbose ~onlytest ~multi ~destroot ~testname file ;
  Cmdliner.Cmd.Exit.ok
end

module Execute = struct

let one_test ~debug ~verbose ~destroot ~testname th =
  if th.ignore then
    Fmt.(pf stderr "[ignore %s]@." testname)
  else begin
      if verbose then Fmt.(pf stderr "[execute %s]@." testname) ;
      if destroot = "" then
        failwith "must specify --dest-root|-d" ;
      let destroot = Fpath.v destroot in
      let destdir = Fpath.(append destroot (v testname)) in
      if not (destdir |> Bos.OS.Dir.exists |> Result.get_ok) then
        Fmt.(failwithf "destdir %s must already exist!" (Fpath.to_string destdir));
      let cmd = Fmt.(str "make -C %s test" (Fpath.to_string destdir)) in
      cmd |> system |> Rresult.R.failwith_error_msg ;
      ()
    end

let st4_test ~debug ~verbose ~destroot ~onlytest ~multi ~testname file =
  if destroot = "" then
    failwith "must specify --dest-root|-d" ;
  if multi then
    let thl = select_tests ~onlytest ~file in
    thl
    |> List.iter (fun (testname,th) ->
           one_test ~debug ~verbose ~destroot ~testname th)
  else
  let th = load ~file in
  let testname = if testname <> "" then testname else filename_to_testname file in
  one_test ~debug ~verbose ~destroot ~testname th

let cmd =
  let doc = "execute testdir for a Stringtemplate4 test" in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "execute" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ file and+ debug and+ verbose and+ onlytest and+ multi and+ destroot and+ testname in
  st4_test ~debug ~verbose ~onlytest ~multi ~destroot ~testname file ;
  Cmdliner.Cmd.Exit.ok
end

module Check = struct
open Antlr

let error_ok th errors =
  if th.errorsContains = "" then
    errors = th.errors
  else
    Util.string_contains ~pat:th.errorsContains errors

let check_run_output ~testname i (output, r) =
  let name =
    if r.name <> "" then Fmt.(str "%d/%s" i r.name)
    else Fmt.(str "%d/%a" i Dump.string (snd r.input)) in
  let output =
    match [%match {|<RoNnIe\|(.*)\|RaYgUn>|} / strings !1 s] output with
      None -> Fmt.(failwithf "test %s/%s: no output found" testname name)
    | Some output -> output in
  if output <> r.output then
    Fmt.(pf stderr "st4_util check: test %s/%s: output didn't match@.expected: {foo|%s|foo}@.actual: {bar|%s|bar}@."
           testname name r.output output) ;
  (output <> r.output)

let check ~testname ~output ~errors (th : t) =
  let output_l =
    output
  |> [%split {|====|}]
  |> List.filter [%match {|RoNnIe|} / pred s] in
  let runs = List.filter (fun r -> not r.disabled && not r.disabled_ocaml) th.runs in
  if List.length output_l <> List.length runs then begin
      Fmt.(pf stderr "check %s: #outputs (%d) <> #expected outputs (%d)@."
             testname (List.length output_l) (List.length th.runs)) ;
      failwith "output count mismatch"
    end ;
  let pairs = Std.combine output_l runs in
  let output_mismatch = pairs |> List.mapi (check_run_output ~testname) |> List.exists (fun x -> x) in
  if not (error_ok th errors) then
    Fmt.(pf stderr "st4_util check: test %s: unexpected errors: {bar|%s|bar}@."
           testname errors) ;

  let l = (if output_mismatch then ["output"] else [])
          @(if not(error_ok th errors) then  ["errors"] else []) in
  if l <> [] then
    Fmt.(failwithf "test %s: %a didn't match expected"
           testname
           (list ~sep:(const string ", ") string) l
    )


let one_test ~debug ~verbose ~destroot ~testname th =
  if th.ignore then
    Fmt.(pf stderr "[ignore %s]@." testname)
  else begin
      if verbose then Fmt.(pf stderr "[check %s]@." testname) ;
      if destroot = "" then
        failwith "must specify --dest-root|-d" ;
      let destroot = Fpath.v destroot in
      let destdir = Fpath.(append destroot (v testname)) in
      if not (destdir |> Bos.OS.Dir.exists |> Result.get_ok) then
        Fmt.(failwithf "destdir %s must already exist!" (Fpath.to_string destdir));
      let outputfile = Fpath.(append destdir (v "output")) in
      let output_txt = outputfile |> Bos.OS.File.read |> Rresult.R.failwith_error_msg in
      let errorsfile = Fpath.(append destdir (v "errors")) in
      let errors_txt = errorsfile |> Bos.OS.File.read |> Rresult.R.failwith_error_msg in
      check ~testname ~output:output_txt ~errors:errors_txt th
    end

let st4_test ~debug ~verbose ~destroot ~onlytest ~multi ~testname file =
  if destroot = "" then
    failwith "must specify --dest-root|-d" ;
  if multi then
    let thl = select_tests ~onlytest ~file in
    thl
    |> List.iter (fun (testname,th) ->
           one_test ~debug ~verbose ~destroot ~testname th)
  else
  let th = load ~file in
  let testname = if testname <> "" then testname else filename_to_testname file in
  one_test ~debug ~verbose ~destroot ~testname th

let cmd =
  let doc = "check output for a Stringtemplate4 test" in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "check" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ file and+ debug and+ verbose and+ onlytest and+ multi and+ destroot and+ testname in
  st4_test ~debug ~verbose ~onlytest ~multi ~destroot ~testname file ;
  Cmdliner.Cmd.Exit.ok
end

module Verify = struct
open Antlr

let one_test ~debug ~verbose ~testname th =
  if th.ignore then
    Fmt.(pf stderr "[ignore %s]@." testname)
  else begin
      if verbose then Fmt.(pf stderr "[verify %s]@." testname) ;
      try
        verify ~verbose th
      with ex ->
        let rbt = Printexc.get_raw_backtrace() in
        Fmt.(pf stderr "====@.verify %s: exception@.%a@.====@."
               testname exn_backtrace (ex, rbt))
    end

let st4_test ~debug ~verbose ~onlytest ~multi ~testname file =
  if multi then
    let thl = select_tests ~onlytest ~file in
    thl
    |> List.iter (fun (testname,th) ->
           one_test ~debug ~verbose ~testname th)
  else
  let th = load ~file in
  one_test ~debug ~verbose ~testname th

let cmd =
  let doc = "verify a Stringtemplate4 test" in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "verify" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ file and+ debug and+ verbose and+ onlytest and+ multi and+ testname in
  st4_test ~debug ~verbose ~onlytest ~multi ~testname file ;
  Cmdliner.Cmd.Exit.ok
end

module Full = struct

let one_test ~debug ~verbose ~force ~destroot ~testname th =
  if th.ignore then
    Fmt.(pf stderr "[ignore %s]@." testname)
  else begin
      Verify.one_test ~debug ~verbose ~testname th ;
      Generate.one_test ~debug ~verbose ~force ~destroot ~testname th ;
      Compile.one_test ~debug ~verbose ~destroot ~testname th ;
      Execute.one_test ~debug ~verbose ~destroot ~testname th ;
      Check.one_test ~debug ~verbose ~destroot ~testname th ;
      ()
    end

let st4_test ~debug ~verbose ~destroot ~force ~onlytest ~multi ~testname file =
  if destroot = "" then
    failwith "must specify --dest-root|-d" ;
  if multi then
    let thl = select_tests ~onlytest ~file in
    thl
    |> List.iter (fun (testname,th) ->
           one_test ~debug ~verbose ~force ~destroot ~testname th)
  else
  let th = load ~file in
  let testname = if testname <> "" then testname else filename_to_testname file in
  one_test ~debug ~verbose ~force ~destroot ~testname th

let cmd =
  let doc = "full test trip for a Stringtemplate4 test" in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "full" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ file and+ debug and+ verbose and+ force and+ onlytest and+ multi and+ destroot and+ testname in
  st4_test ~debug ~verbose ~force ~onlytest ~multi ~destroot ~testname file ;
  Cmdliner.Cmd.Exit.ok
end

module TestOCaml = struct
open Eval
  
module STPa = ST4.Pa.STG2_STPa
module STGPa = ST4.Pa.STG2_STGPa

let stparse s =
  let t =
    s
    |> STPa.Template.of_string
    |> St_ops.coalesce
    |> St_ops.insert_indentation
  in
  assert (St_ops.balanced_indentation t) ;
  t

let steval ?group ?groupdir env t =
  let open Doit in
  let ctxt = Context.mk ?group ?groupdir () in
  t
  |> eval_elements ctxt env
  |> render_attr_value
  |> OutputToken.flatten
  |> Std.stream_of_list
  |> FIW.render_stream
  |> Std.list_of_stream
  |> String.concat ""

let doit ?group ?groupdir r =
  try
         let t = stparse (snd r.input) in
         let env = [r.attributes] in
         let output = steval ?group ?groupdir env t in
         (output, "")
  with ex ->
    let rbt = Printexc.get_raw_backtrace () in
    ("", Fmt.(str "%a" exn_backtrace (ex,rbt)))

let runtest ~verbose testname th =
  let ploc_filecache =
    (Option.fold ~none:[] ~some:(fun x -> [x]) th.groupfile)@th.groupfiles in
  let (group, groupdir) =
    match (th.groupfile, th.groupfiles) with
      (None, []) -> (Some (Group.mk()), None)
    | (Some (file, _), _) ->
       (Some (Group.load ~ploc_filecache file), None)
    | (None, _::_) ->
       (None, Some (GroupDir.load ~ploc_filecache ~files:(List.map fst th.groupfiles) ())) in

  let errorbuf = Buffer.create 23 in
  th.runs
  |> List.iteri (fun i r ->
         if not r.disabled && not r.disabled_ocaml then
           let name =
             if r.name <> "" then Fmt.(str "%d/%s" i r.name)
             else Fmt.(str "%d/%a" i Dump.string (snd r.input)) in
           if verbose then
             Fmt.(pf stderr "[run %s]@." name) ;
           let (output, errors) = doit ?group ?groupdir r in
           if output <> r.output then
             Fmt.(pf stderr "st4_util test-ocaml: test %s/%s: output didn't match@.expected: {foo|%s|foo}@.actual: {bar|%s|bar}@."
                    testname name r.output output) ;
           Buffer.add_string errorbuf errors
       ) ;
  let errors = Buffer.contents errorbuf in
  if errors <> th.errors then
    Fmt.(pf stderr "st4_util test-ocaml: test %s: errors didn't match@.expected: {foo|%s|foo}@.actual: {bar|%s|bar}@."
           testname th.errors errors)

let one_test ~debug ~verbose ~force ~testname th =
  if th.ignore then
    Fmt.(pf stderr "[ignore %s]@." testname)
  else begin
      if verbose then Fmt.(pf stderr "[%s]@." testname) ;
      runtest ~verbose testname th
    end

let st4_test ~debug ~verbose ~force ~onlytest ~multi ~testname file =
  if multi then
    let thl = select_tests ~onlytest ~file in
    thl
    |> List.iter (fun (testname,th) ->
           one_test ~debug ~verbose ~force ~testname th)
  else
  let th = load ~file in
  let testname = if testname <> "" then testname else filename_to_testname file in
  one_test ~debug ~verbose ~force ~testname th

let cmd =
  let doc = "full test trip for a Stringtemplate4 test" in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "test-ocaml" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ file and+ debug and+ verbose and+ force and+ onlytest and+ multi and+ testname in
  st4_test ~debug ~verbose ~force ~onlytest ~multi ~testname file ;
  Cmdliner.Cmd.Exit.ok
end

let cmd =
  let doc = "The tool synopsis is TODO" in
  Cmd.group (Cmd.info "TODO" ~version:"%%VERSION%%" ~doc) @@
  [Generate.cmd; Compile.cmd; Execute.cmd; Check.cmd; Verify.cmd; Full.cmd; TestOCaml.cmd]

let main () = Cmd.eval' cmd
let () = if !Sys.interactive then () else exit (main ())
