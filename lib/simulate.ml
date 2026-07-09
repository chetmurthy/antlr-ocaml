(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.utils,pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.yojson,pa_ppx.deriving_plugins.located_yojson,pa_ppx.import *)

open Pa_ppx_base
open Ppxutil
open Pa_ppx_utils
open Pa_ppx_located_yojson
open Exec
module M = Mimick

module Entrypoints = struct
let sim1 atns (i:int) (loc,j) = match j with
    M.PredictionContext_ENTER_merge (pc1, pc2, rootIsWildcard, mc_opt) -> begin
      try
        let pc1 = PC.of_mimick pc1 in
        let pc2 = PC.of_mimick pc2 in
        let mc_opt = Option.map PC.MC.of_mimick mc_opt in
        let pc3 = PC.merge pc1 pc2 rootIsWildcard mc_opt in
        ()
      with e ->
        let bt = Printexc.get_raw_backtrace () in
        Fmt.(pf stderr "sim1[%d]: %s: exception %a@." i
               (Ploc.string_of_location loc)
               exn e) ;
        Printexc.raise_with_backtrace e bt
    end

  | M.PredictionContext_ENTER_mergeArrays (pc1, pc2, rootIsWildcard, mc_opt) -> begin
      try
        let pc1 = PC.of_mimick pc1 in
        let pc2 = PC.of_mimick pc2 in
        let mc_opt = Option.map PC.MC.of_mimick mc_opt in
        let pc3 = PC.mergeArrays pc1 pc2 rootIsWildcard mc_opt in
        ()
      with e ->
        let bt = Printexc.get_raw_backtrace () in
        Fmt.(pf stderr "sim1[%d]: %s: exception %a@." i
               (Ploc.string_of_location loc)
               exn e) ;
        Printexc.raise_with_backtrace e bt
    end

  | M.PredictionContext_ENTER_mergeRoot (pc1, pc2, rootIsWildcard) -> begin
      try
        let pc1 = PC.of_mimick pc1 in
        let pc2 = PC.of_mimick pc2 in
        let pc3_opt = PC.mergeRoot pc1 pc2 rootIsWildcard in
        ()
      with e ->
        let bt = Printexc.get_raw_backtrace () in
        Fmt.(pf stderr "sim1[%d]: %s: exception %a@." i
               (Ploc.string_of_location loc)
               exn e) ;
        Printexc.raise_with_backtrace e bt
    end

  | M.MergeCache_ENTER_add (mc, a, b, merged) ->  begin
      try
        let mc = PC.MC.of_mimick mc in
        let a = PC.of_mimick a in
        let b = PC.of_mimick b in
        let merged = PC.of_mimick merged in
        PC.MC.add mc (a,b) merged ;
        ()
      with e ->
        let bt = Printexc.get_raw_backtrace () in
        Fmt.(pf stderr "sim1[%d]: %s: exception %a@." i
               (Ploc.string_of_location loc)
               exn e) ;
        Printexc.raise_with_backtrace e bt
    end
     
  | M.PredictionContext_ENTER_mergeSingletons (pc1, pc2, rootIsWildcard, mc_opt) -> begin
      try
        let pc1 = PC.of_mimick pc1 in
        let pc2 = PC.of_mimick pc2 in
        let mc_opt = Option.map PC.MC.of_mimick mc_opt in
        let pc3 = PC.mergeSingletons pc1 pc2 rootIsWildcard mc_opt in
        ()
      with e ->
        let bt = Printexc.get_raw_backtrace () in
        Fmt.(pf stderr "sim1[%d]: %s: exception %a@." i
               (Ploc.string_of_location loc)
               exn e) ;
        Printexc.raise_with_backtrace e bt
    end

  | _ ->
     Fmt.(pf stderr "%s: sim1[%d]: Match failure on @.%a@."
          (Ploc.string_of_location loc) i
          M.pp_json_log_t j) ;
     Fmt.(raise_failwithf loc "sim1[%d]: Match failure on @.%a@." i M.pp_json_log_t j)
end

module Caches = struct
  open Coll
  type t = {
      ac : AC.Cache.t
    ; acs : ACS.Cache.t
    }
  let mk () = {
      ac = AC.Cache.mk ()
    ; acs = ACS.Cache.mk ()
    }
end

module ACS = struct
open Caches
let sim1 caches atns (i:int) (loc,j) = match j with
    M.ATNConfigSet_ENTER_init (id, fullCtx) ->
     let rv = ACS._ATNConfigSet_init ~id fullCtx in
     ACS.Cache.add caches.acs rv ;
     ()

  | ATNConfigSet_ENTER_add (cs, c, mc_opt) -> begin
      try
      let cs = ACS.of_mimick ~acs_cache:(Some caches.acs) ~ac_cache:(Some caches.ac) atns cs in
      let c = AC.of_mimick ~ac_cache:(Some caches.ac) atns c in
      let mc_opt = Option.map PC.MC.of_mimick mc_opt in
      let rv = match mc_opt with
          None -> ACS.add cs c
        | Some mergeCache -> ACS.add ~mergeCache cs c
      in
      let cs2 = ACS.to_mimick cs in
      ()
      with e ->
        let bt = Printexc.get_raw_backtrace () in
        Fmt.(pf stderr "sim1[%d]: %s: exception %a@." i
               (Ploc.string_of_location loc)
               exn e) ;
        Printexc.raise_with_backtrace e bt
    end

end
