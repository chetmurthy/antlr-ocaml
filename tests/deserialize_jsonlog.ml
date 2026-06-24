(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.deriving_plugins.std *)

open Pa_ppx_utils

(** deserialize the "json.log" files into Atn.json_log_t objects
 *)

let deser1 file =
  let l = Pa_ppx_located_yojson.Json.JsonListEOI.load file in
  let l = List.map Antlr.Atn.json_log_t_of_located_yojson l in
  l |> List.iter
         (function
            Result.Ok _ -> ()
          | Error (loc, msg) ->
             Fmt.(pf stdout "%s: error %s@." (Ploc.string_of_location loc) msg))

let deserialize_jsonlog ~debug files =
  let open Antlrtest in
  List.iter deser1 files

open Cmdliner
open Cmdliner.Term.Syntax

let files = Arg.(non_empty & pos_all file [] & info [] ~docv:"JSON-FILE")

let debug =
  let doc = "enable debugging." in
  Arg.(value & flag & info ["debug"] ~doc)

let deserialize_cmd =
  let doc = "deserialize json.log files into json_log_t objects" in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <bugs@example.org>." ]
  in
  Cmd.make (Cmd.info "deserialize_jsonlog" ~version:"%%VERSION%%" ~doc ~man) @@
  let+ files and+ debug in
  deserialize_jsonlog ~debug files

let main () = Cmd.eval deserialize_cmd
let () = if !Sys.interactive then () else exit (main ())
