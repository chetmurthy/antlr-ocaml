(**pp -syntax camlp5o -package camlp5.parser_quotations,camlp5.extfun *)
(* camlp5o *)
(* pa_here.ml,v *)
(* Copyright (c) INRIA 2007-2017 *)

open Pa_ppx_base
open Pa_passthru
open Ppxutil

let rewrite_expr arg = function
  <:expr:< [%trace $exp:e$] >> ->
   <:expr< (let open Mimick in if Tracelog.enabled() then Tracelog.write $e$ else ()) >>
| _ -> assert false


let install () = 
let ef = EF.mk () in 
let ef = EF.{ (ef) with
            expr = extfun ef.expr with [
    <:expr:< [%trace $exp:_$ ] >> as z ->
    fun arg fallback ->
      Some (rewrite_expr arg z)
  ] } in
  Pa_passthru.(install { name = "pa_tracelog"; ef =  ef ; pass = None ; before = [] ; after = [] })
;;

install();;
