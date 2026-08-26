(**pp -syntax camlp5o -package pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.located_sexp,pa_ppx.utils,pa_ppx_regexp,pa_ppx.import *)

open Pa_ppx_base
open Ppxutil
open Pa_ppx_utils
open Coll

open Antlr
open Sttypes2
open Stg_types

module STPa = Pa.STG2_STPa
module STGPa = Pa.STG2_STGPa

module FileCache = struct
  type t = Eval.FileCache.t
  let mk here_filecache ploc_filecache =
    Eval.FileCache.mk here_filecache ploc_filecache

let mt = Eval.FileCache.mt
end
module FC = FileCache

module GroupLoadContext = struct
  type t = Eval.GLC.t

  let mk filecache = Eval.GLC.mk filecache

end
module GLC = GroupLoadContext


module Group = struct
  type t = Eval.Group.t
  let mk () = Eval.Group.mk()
  let load ctxt file = Eval.Group.load ctxt file

let of_located_string ctxt ~stg locs =
  Eval.Group.of_located_string ctxt ~stg locs

let of_here_string ctxt ~stg locs =
  Eval.Group.of_here_string ctxt ~stg locs

end

module GroupDir = struct
end

module Template = struct

type t = Sttypes2.template_t

let of_string s =
  let t =
    s
    |> STPa.Template.of_string
    |> St_ops.coalesce
    |> St_ops.insert_indentation
  in
  assert (St_ops.balanced_indentation t) ;
  t

let eval env t =
  let open Eval in
  let open Doit in
  let group = Group.mk () in
  let ctxt = EC.mk ~group () in
  t
  |> eval_elements ctxt env
  |> render_attr_value
  |> OutputToken.flatten
  |> Std.stream_of_list
  |> FIW.render_stream
  |> Std.list_of_stream
  |> String.concat ""

end
