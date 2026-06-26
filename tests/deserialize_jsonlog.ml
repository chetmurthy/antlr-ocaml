(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.deriving_plugins.std *)

open Pa_ppx_utils
open Pa_ppx_located_yojson

(** deserialize the "json.log" files into Atn.json_log_t objects
 *)

let pa_json_list strm =
  let rec parec = parser
    [< j = Json.JsonOrEOI.parse ; strm >] ->
       (match j with
          None -> [< >]
        | Some j -> [< 'j ; parec strm >])

  | [< >] -> [< >]
  in parec strm

let deser_json_stream strm =
  strm
  |> pa_json_list
  |> Stream.iter (fun j ->
         match Antlr.Mimick.json_log_t_of_located_yojson j with
           Result.Ok _ -> ()
         | Error (loc, msg) ->
            Fmt.(pf stdout "%s: error %s@." (Ploc.string_of_location loc) msg))

let deser1 ~verbose file =
  if verbose then
    Fmt.(pf stderr "[READ %s]@." file) ;
  let ic = open_in file in
  Pa_json.with_input_file deser_json_stream ~file

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

let deserialize_cmd =
  let doc = "deserialize json.log files into json_log_t objects" in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "deserialize_jsonlog" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ files and+ debug and+ yojson and+ verbose in
  deserialize_jsonlog ~verbose ~yojson ~debug files

let main () = Cmd.eval deserialize_cmd
let () = if !Sys.interactive then () else exit (main ())
