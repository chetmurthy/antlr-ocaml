(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.located_yojson *)

open Pa_ppx_utils
open Pa_ppx_located_yojson

(** deserialize the "json.log" files into Atn.json_log_t objects
 *)

open Cmdliner
open Cmdliner.Term.Syntax


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
open Antlr
let filter_json_stream matchers strm =
  let filter1 j = match j with
      (_,`List ((_,`String tag)::l)) ->
       if List.exists (fun rex -> Pcre2.pmatch ~rex tag) matchers then
         [< 'j >]
       else [< >]
    | _ -> [< 'j >] in
      
  Std.stream_concat_map filter1 strm

let pp_json_stream oc strm =
  Util.stream_iter (Json.pp_hum_to_channel ~std:true oc) strm

let filter1 ~verbose matchers file =
  if verbose then
    Fmt.(pf stderr "[READ %s]@." file) ;
  let doit stream =
    stream |> filter_json_stream matchers |> pp_json_stream stdout in
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

module Simulate = struct
open Antlr

let simulate1 ~verbose matchers file =
  if verbose then
    Fmt.(pf stderr "[READ %s]@." file) ;
  Tracelog._enabled := true ;
  let doit stream =
    stream
    |> Filter.filter_json_stream matchers
    |> Std.stream_map [%of_located_yojson: Mimick.json_log_t]
    |> Std.stream_map Json.raise_failwith_error_msg
    |> Util.stream_iter Simulate.sim1 in
  Pa_json.with_input_file Pa_json.g Json.JsonOrEOI.parse_parsable doit ~file

let simulate ~verbose ~yojson ~debug ~pattern ~case_insensitive files =
  let flags = if case_insensitive then [`CASELESS] else [] in
  let matchers = List.map (Pcre2.regexp ~flags) pattern in
  List.iter (simulate1 ~verbose matchers) files

let cmd =
  let doc = "simulate json.log files for only selected JSON log objects." in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "simulate" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ files and+ debug and+ verbose and+ pattern and+ case_insensitive in
  simulate ~verbose ~yojson ~debug ~pattern ~case_insensitive files ;
  Cmdliner.Cmd.Exit.ok
end

let cmd =
  let doc = "The tool synopsis is TODO" in
  Cmd.group (Cmd.info "TODO" ~version:"%%VERSION%%" ~doc) @@
  [Deserialize.cmd; Filter.cmd; Simulate.cmd]

let main () = Cmd.eval' cmd
let () = if !Sys.interactive then () else exit (main ())
