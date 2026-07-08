(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.located_yojson *)

open Pa_ppx_base
open Ppxutil
open Pa_ppx_utils
open Pa_ppx_located_yojson
open Antlr

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

let entry_exit_nth =
  let doc = "entry-exit-nth: extract NTH event-tree with tag '{ENTER,EXIT} name'." in
  Arg.(value & opt (some int) None & info ["n";"entry-exit-nth"] ~doc)

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
let filter_json_stream matchers strm =
  let filter1 j = match j with
      (_,`List ((_,`String tag)::l)) ->
       if List.exists (fun rex -> Pcre2.pmatch ~rex tag) matchers then
         [< 'j >]
       else [< >]
    | _ -> [< 'j >] in
      
  Std.stream_concat_map filter1 strm

let filter1 ~verbose matchers file =
  if verbose then
    Fmt.(pf stderr "[READ %s]@." file) ;
  let doit stream =
    stream
    |> filter_json_stream matchers
    |> pp_json_stream stdout in
  Pa_json.with_input_file Pa_json.g Json.JsonOrEOI.parse_parsable doit ~file

let filter ~verbose ~yojson ~debug ~pattern ~case_insensitive files =
  let flags = if case_insensitive then [`CASELESS] else [] in
  let matchers = List.map (Pcre2.regexp ~flags) pattern in
  List.iter (filter1 ~verbose matchers) files

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

let filter1 ?nth ~only_outermost_enter ~verbose names file =
  if verbose then
    Fmt.(pf stderr "[READ %s]@." file) ;
  let doit stream =
    stream |> Util.entry_exit_yojson ?nth ~only_outermost_enter names |> pp_json_stream stdout in
  Pa_json.with_input_file Pa_json.g Json.JsonOrEOI.parse_parsable doit ~file

let filter ?nth ~verbose ~yojson ~debug ~entry_exit_name ~only_outermost_enter files =
  List.iter (filter1 ?nth ~only_outermost_enter ~verbose entry_exit_name) files

let cmd =
  let doc = "filter json.log files for selected ENTER events." in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "entry-exit" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ files and+ debug and+ verbose and+ entry_exit_name and+ entry_exit_nth and+ only_outermost_enter in
  begin match entry_exit_nth with
    None ->
     filter ~only_outermost_enter ~verbose ~yojson ~debug ~entry_exit_name files
  | Some nth ->
     filter ~nth ~only_outermost_enter ~verbose ~yojson ~debug ~entry_exit_name files
  end ;
  Cmdliner.Cmd.Exit.ok
end


module Simulate = struct

let read_atn ~grammarType file =
  let atn = 
    file
    |> Fpath.v
    |>  Bos.OS.File.read
    |> Result.get_ok
    |> Antlr.Interp_syntax.read_raw
    |> Antlr.Atn.deser ~verify:true in
  if atn.Atn.grammarType <> grammarType then
    Fmt.(failwithf "%s: ATN was supposed to be %a but was %a@."
           file Atn.pp_atn_type_t atn.Atn.grammarType Atn.pp_atn_type_t grammarType) ;
  atn

let simulate1_filter ~atns ~verbose ~pattern ~case_insensitive file =
  let flags = if case_insensitive then [`CASELESS] else [] in
  let matchers = List.map (Pcre2.regexp ~flags) pattern in
  let open Rresult.R in
  if verbose then
    Fmt.(pf stderr "[READ %s]@." file) ;
  Tracelog._enabled := true ;
  let demarsh j =
    let loc = Json.loc_of_json j in
    ([%of_located_yojson: Mimick.json_log_t] j)
    >>= (fun j ->  Result.Ok(loc,j)) in
  let caches = Simulate.Caches.mk() in
  let doit stream =
    stream
    |> Filter.filter_json_stream matchers
    |> Std.stream_map demarsh
    |> Std.stream_map Json.raise_failwith_error_msg
    |> Util.stream_iter_i (Simulate.Entrypoints.sim1 caches atns) in
  Pa_json.with_input_file Pa_json.g Json.JsonOrEOI.parse_parsable doit ~file

let simulate1_entry_exit ~atns ?nth ~verbose ~entry_exit_name ~only_outermost_enter file =
  let open Rresult.R in
  if verbose then
    Fmt.(pf stderr "[READ %s]@." file) ;
  Tracelog._enabled := true ;
  let demarsh j =
    let loc = Json.loc_of_json j in
    ([%of_located_yojson: Mimick.json_log_t] j)
    >>= (fun j ->  Result.Ok(loc,j)) in
  let caches = Simulate.Caches.mk() in
  let doit stream =
    stream
    |> Util.entry_exit_yojson ?nth ~only_outermost_enter entry_exit_name
    |> Std.stream_map demarsh
    |> Std.stream_map Json.raise_failwith_error_msg
    |> Util.stream_iter_i (Simulate.Entrypoints.sim1 caches atns) in
  Pa_json.with_input_file Pa_json.g Json.JsonOrEOI.parse_parsable doit ~file

let simulate ~lexer_atn ~parser_atn ~verbose ~yojson ~debug ~pattern ~case_insensitive ~entry_exit_name ~entry_exit_nth ~only_outermost_enter file =
  let atns = match (lexer_atn, parser_atn) with
      (None, None) -> failwith "must specify at least lexer-atn"
    | (None, Some _) -> failwith "cannot specify parser-atn without lexer-atn"
    | (Some f1, None) ->
       Exec.{ lexer = read_atn ~grammarType:Atn.LEXER f1
            ; _parser = None }
    | (Some f1, Some f2) ->
       Exec.{ lexer = read_atn ~grammarType:Atn.LEXER f1
            ; _parser = Some (read_atn ~grammarType:Atn.PARSER f2) } in
  match (pattern, entry_exit_name) with
    (_::_,[]) ->
    simulate1_filter ~atns ~verbose ~pattern ~case_insensitive file
  | ([],_::_) -> begin
      match entry_exit_nth with
        None ->
        simulate1_entry_exit ~atns ~verbose ~entry_exit_name ~only_outermost_enter file
      | Some nth ->
         simulate1_entry_exit ~atns ~nth ~verbose ~entry_exit_name ~only_outermost_enter file
    end
  | ([],[]) -> Fmt.(failwith "simulate: must provide either pattern or entry-exit-name")
  | (_::_, _::_) ->
     Fmt.(failwith "simulate: must NOT provide BOTH pattern AND entry-exit-name")

let cmd =
  let doc = "simulate json.log files for only selected JSON log objects." in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "simulate" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ file and+ parser_atn and+ lexer_atn and+ debug and+ verbose and+ pattern and+ case_insensitive
     and+ entry_exit_name and+ entry_exit_nth and+ only_outermost_enter in
  simulate ~lexer_atn ~parser_atn ~verbose ~yojson ~debug ~pattern ~case_insensitive ~entry_exit_name ~entry_exit_nth ~only_outermost_enter file ;
  Cmdliner.Cmd.Exit.ok
end

let cmd =
  let doc = "The tool synopsis is TODO" in
  Cmd.group (Cmd.info "TODO" ~version:"%%VERSION%%" ~doc) @@
  [Deserialize.cmd
  ; Filter.cmd
  ; EntryExit.cmd
  ; Simulate.cmd
]

let main () = Cmd.eval' cmd
let () = if !Sys.interactive then () else exit (main ())
