(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.located_yojson *)

open Pa_ppx_base
open Ppxutil
open Pa_ppx_utils
open Pa_ppx_located_yojson
open Antlr

Pa_ppx_runtime.Exceptions.Ploc.pp_loc_verbose := true ;;
(*
Pa_ppx_runtime_fat.Exceptions.Ploc.pp_loc_verbose := true ;;
 *)
(** deserialize the "json.log" files into Atn.json_log_t objects
 *)

open Cmdliner
open Cmdliner.Term.Syntax

let file = Arg.(value & pos 0 file "" & info [] ~docv:"JSON-FILE")

let files = Arg.(non_empty & pos_all file [] & info [] ~docv:"JSON-FILE")

let debug =
  let doc = "enable debugging." in
  Arg.(value & flag & info ["debug"] ~doc)

let verbose =
  let doc = "verbose (log filenames)." in
  Arg.(value & flag & info ["v"; "verbose"] ~doc)

let yojson =
  let doc = "use YOJSON instead." in
  Arg.(value & flag & info ["yojson"] ~doc)

let case_insensitive =
  let doc = "case-insensitive patterns." in
  Arg.(value & flag & info ["i"] ~doc)

let pattern =
  let doc = "pattern: if JSON's car matches this, it is passed by the filter ." in
  Arg.(value & opt_all string [] & info ["t";"tag-pattern"] ~doc)

let entry_exit_name =
  let doc = "entry-exit-name: extract events with tag '{ENTER,EXIT} name'." in
  Arg.(value & opt_all string [] & info ["e";"entry-exit-name"] ~doc)

let json_log_file =
  let doc = "json-log-file: file destination for JSON log, instead of stdout." in
  Arg.(value & opt (some string) None & info ["json-log-file"] ~doc)

let start_nth =
  let doc = "start-nth: start (inclusive) of range of accepted event-tree with tag '{ENTER,EXIT} name'." in
  Arg.(value & opt (some int) None & info ["start-nth"] ~doc)

let stop_nth =
  let doc = "stop-nth: limit (exclusive) of range of accepted ac event-tree with tag '{ENTER,EXIT} name'." in
  Arg.(value & opt (some int) None & info ["stop-nth"] ~doc)

let lexer_atn =
  let doc = "lexer-atn: lexer ATN filename'." in
  Arg.(value & opt (some file) None & info ["lexer-atn"] ~doc)

let parser_atn =
  let doc = "parser-atn: parser ATN filename'." in
  Arg.(value & opt (some file) None & info ["parser-atn"] ~doc)

let only_outermost_enter =
  let doc = "pass thru only the outermost ENTER of a tree of events." in
  Arg.(value & flag & info ["ooe"; "only-outermost-enter"] ~doc)

let pp_json_stream oc strm =
  Util.stream_iter (Json.pp_hum_to_channel ~std:true oc) strm

module Deserialize = struct
let deser_json_stream strm =
  strm
  |> Stream.iter (fun j ->
         match Antlr.Mimick.json_log_t_of_located_yojson j with
           Result.Ok _ -> ()
         | Error (loc, msg) ->
            Fmt.(pf stdout "%s: error %s@." (Ploc.string_of_location loc) msg))

let deser1 ~verbose file =
  if verbose then
    Fmt.(pf stderr "[READ %s]@." file) ;
  Pa_json.with_input_file Pa_json.g Json.JsonOrEOI.parse_parsable deser_json_stream ~file

let deser1_yojson ~verbose file =
  if verbose then
    Fmt.(pf stderr "[READ %s]@." file) ;
  let seq = Yojson.Safe.seq_from_file file in
  seq
  |> Seq.iter
       (fun j -> match Antlr.Mimick.json_log_t_of_yojson j with
                   Result.Ok _ -> ()
                 | Error msg ->
                    Fmt.(pf stdout "error %s@." msg))

let deserialize_jsonlog ~verbose ~debug ~yojson files =
  let open Antlrtest in
  if yojson then
    List.iter (deser1_yojson ~verbose) files
  else
    List.iter (deser1 ~verbose) files

let cmd =
  let doc = "deserialize json.log files into json_log_t objects" in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "deserialize" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ files and+ debug and+ yojson and+ verbose in
  deserialize_jsonlog ~verbose ~yojson ~debug files ;
  Cmdliner.Cmd.Exit.ok
end

module Filter = struct
let make_matchers ~pattern ~case_insensitive =
  let flags = if case_insensitive then [`CASELESS] else [] in
  List.map (Pcre2.regexp ~flags) pattern

let filter_json_stream matchers strm =
  let filter1 j = match j with
      (_,`List ((_,`String tag)::l)) ->
       if List.exists (fun rex -> Pcre2.pmatch ~rex tag) matchers then
         [< 'j >]
       else [< >]
    | _ -> [< 'j >] in
      
  Std.stream_concat_map filter1 strm

let filter1_then ~verbose matchers consumer file =
  if verbose then
    Fmt.(pf stderr "[READ %s]@." file) ;
  let doit stream =
    stream
    |> filter_json_stream matchers
    |> consumer in
  Pa_json.with_input_file Pa_json.g Json.JsonOrEOI.parse_parsable doit ~file

let filter ~verbose ~yojson ~debug ~pattern ~case_insensitive files =
  let matchers = make_matchers ~pattern ~case_insensitive in
  List.iter (filter1_then ~verbose matchers (pp_json_stream stdout)) files

let cmd =
  let doc = "filter json.log files for only selected JSON log objects." in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "filter" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ files and+ debug and+ verbose and+ pattern and+ case_insensitive in
  filter ~verbose ~yojson ~debug ~pattern ~case_insensitive files ;
  Cmdliner.Cmd.Exit.ok
end

module EntryExit = struct

let filter1_then ?start_nth ?stop_nth ~only_outermost_enter ~verbose names consumer file =
  if verbose then
    Fmt.(pf stderr "[READ %s]@." file) ;
  let doit stream =
    stream
    |> Util.entry_exit_yojson ?start_nth ?stop_nth ~only_outermost_enter names
    |> consumer in
  Pa_json.with_input_file Pa_json.g Json.JsonOrEOI.parse_parsable doit ~file

let filter ?start_nth ?stop_nth ~verbose ~yojson ~debug ~entry_exit_name ~only_outermost_enter files =
  List.iter (filter1_then ?start_nth ?stop_nth ~only_outermost_enter ~verbose entry_exit_name (pp_json_stream stdout)) files

let cmd =
  let doc = "filter json.log files for selected ENTER events." in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "entry-exit" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ files and+ debug and+ verbose and+ entry_exit_name and+ start_nth and+ stop_nth and+ only_outermost_enter in
     filter ?start_nth ?stop_nth ~only_outermost_enter ~verbose ~yojson ~debug ~entry_exit_name files ;
  Cmdliner.Cmd.Exit.ok
end

module Depth = struct

let filter1_then ~verbose consumer file =
  if verbose then
    Fmt.(pf stderr "[READ %s]@." file) ;
  let doit stream =
    stream
    |> Util.entry_exit_decorate_depth
    |> consumer in
  Pa_json.with_input_file Pa_json.g Json.JsonOrEOI.parse_parsable doit ~file

let pp1 ~indent oc (depth, (j : Pa_ppx_located_yojson.Json.t)) = match (depth, j) with
    (depth, (_,`List((_,`String name)::_))) ->
     let indent =
       let indent1 =
         if indent < 2 then ""
         else "|"^(String.make (indent-1) ' ') in
       depth |> Std.range |> List.map (fun _ -> indent1) |> String.concat "" in
    Printf.fprintf oc "%s%s\n" indent name
  | _ -> ()

let filter ~indent ~verbose ~with_line_numbers files =
  List.iter (filter1_then ~verbose (Stream.iter (pp1 ~indent stdout))) files

let with_line_numbers =
  let doc = "with file/line numbers." in
  Arg.(value & flag & info ["n"; "with-line-numbers"] ~doc)

let indent =
  let doc = "indent: indentation width." in
  Arg.(value & opt (some int) (Some 2) & info ["i"; "indent"] ~doc)

let cmd =
  let doc = "Print ENTRY/EXIT events indented by depth." in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "entry-exit-depth" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ files and+ verbose and+ with_line_numbers and+ indent in
     filter ~indent:(Std.outSome indent) ~verbose ~with_line_numbers files ;
  Cmdliner.Cmd.Exit.ok
end

module Entrypoints = struct

let simulate_json atns stream =
  let open Rresult.R in
  let demarsh j =
    let loc = Json.loc_of_json j in
    ([%of_located_yojson: Mimick.json_log_t] j)
    >>= (fun j ->  Result.Ok(loc,j)) in
  stream
  |> Std.stream_map demarsh
  |> Std.stream_map Json.raise_failwith_error_msg
  |> Util.stream_iter_i (Simulate.Entrypoints.sim1 atns)

let simulate1_filter ~atns ~verbose ~pattern ~case_insensitive file =
  Tracelog._enabled := true ;
  let matchers = Filter.make_matchers ~pattern ~case_insensitive in
  Filter.filter1_then ~verbose matchers (simulate_json atns) file

let simulate1_entry_exit ~atns ?start_nth ?stop_nth ~verbose ~entry_exit_name ~only_outermost_enter file =
  Tracelog._enabled := true ;
  EntryExit.filter1_then  ?start_nth ?stop_nth ~only_outermost_enter ~verbose entry_exit_name (simulate_json atns) file

let simulate ~lexer_atn ~parser_atn ~verbose ~yojson ~debug ~pattern ~case_insensitive ~entry_exit_name ?start_nth ?stop_nth ~only_outermost_enter file =
  let lexer_atn = match lexer_atn with
      None -> failwith "simulate: must provide lexer-atn"
    | Some x -> x in
  let open Exec in
  let atns = Atns.load ~lexer_atn ~parser_atn in
  match (pattern, entry_exit_name) with
    (_::_,[]) ->
    simulate1_filter ~atns ~verbose ~pattern ~case_insensitive file
  | ([],_::_) ->
     simulate1_entry_exit ~atns ?start_nth ?stop_nth ~verbose ~entry_exit_name ~only_outermost_enter file

  | ([],[]) -> Fmt.(failwith "simulate: must provide either pattern or entry-exit-name")
  | (_::_, _::_) ->
     Fmt.(failwith "simulate: must NOT provide BOTH pattern AND entry-exit-name")

let cmd =
  let doc = "simulate json.log files for only selected UNRELATED JSON log objects." in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "entrypoints" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ file and+ parser_atn and+ lexer_atn and+ debug and+ verbose and+ pattern and+ case_insensitive
     and+ entry_exit_name and+ start_nth and+ stop_nth and+ only_outermost_enter in
  simulate ~lexer_atn ~parser_atn ~verbose ~yojson ~debug ~pattern ~case_insensitive ~entry_exit_name ?start_nth ?stop_nth ~only_outermost_enter file ;
  Cmdliner.Cmd.Exit.ok
end

module ACS = struct

let simulate_json caches atns stream =
  let open Rresult.R in
  let demarsh j =
    let loc = Json.loc_of_json j in
    ([%of_located_yojson: Mimick.json_log_t] j)
    >>= (fun j ->  Result.Ok(loc,j)) in
  stream
  |> Std.stream_map demarsh
  |> Std.stream_map Json.raise_failwith_error_msg
  |> Util.stream_iter_i (Simulate.ACS.sim1 caches atns)

let simulate1_entry_exit caches ~json_log_file ~atns ?start_nth ?stop_nth ~verbose ~entry_exit_name ~only_outermost_enter file =
  let open Simulate.Caches in
  Tracelog._enabled := true ;
  json_log_file |> Option.iter Tracelog.set_log_file ;
  Exec.file_init ~dfast_cache:caches.dfast ~acs_cache:caches.acs ~ac_cache:caches.ac () ;
  EntryExit.filter1_then  ?start_nth ?stop_nth ~only_outermost_enter ~verbose entry_exit_name (simulate_json caches atns) file

let simulate ~json_log_file ~lexer_atn ~parser_atn ~verbose ~entry_exit_name ?start_nth ?stop_nth ~only_outermost_enter file =
  let open Exec in
  let lexer_atn = match lexer_atn with
      None -> failwith "simulate: must provide lexer-atn"
    | Some x -> x in
  let caches = Simulate.Caches.mk () in
  let atns = Atns.load ~lexer_atn ~parser_atn in
  simulate1_entry_exit caches ~json_log_file ~atns ?start_nth ?stop_nth ~verbose ~entry_exit_name ~only_outermost_enter file

let cmd =
  let doc = "simulate json.log files for AtnConfigSet." in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "acs" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ json_log_file and+ file and+ parser_atn and+ lexer_atn and+ verbose
     and+ entry_exit_name and+ start_nth and+ stop_nth and+ only_outermost_enter in
  simulate ~json_log_file ~lexer_atn ~parser_atn ~verbose ~entry_exit_name ?start_nth ?stop_nth ~only_outermost_enter file ;
  Cmdliner.Cmd.Exit.ok
end

let cmd =
  let doc = "The tool synopsis is TODO" in
  Cmd.group (Cmd.info "TODO" ~version:"%%VERSION%%" ~doc) @@
  [Deserialize.cmd
  ; Filter.cmd
  ; EntryExit.cmd
  ; Depth.cmd
  ; Entrypoints.cmd
  ; ACS.cmd
]

let main () = Cmd.eval' cmd
let () = if !Sys.interactive then () else exit (main ())
