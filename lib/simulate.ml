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
let sim1 caches atns (i:int) (loc,j) =
  try
    begin
      match j with
        M.LexerATNConfig_ENTER_init (state_opt, alt_opt, context_opt, semantic_opt, lexerActionExecutor_opt, config_opt) ->
         let atn = atns.lexer in
         let context_opt = Option.map PC.of_mimick context_opt in
         let semantic_opt = Option.map SC.of_mimick semantic_opt in
         let config_opt = Option.map (AC.of_mimick ~ac_cache:(Some caches.ac) atns) config_opt in
         let rv = AC.init_LexerATNConfig atn state_opt alt_opt context_opt semantic_opt config_opt lexerActionExecutor_opt in
         AC.Cache.add caches.ac rv ;
         ()

      | ATNConfig_ENTER_init (id, state_opt, alt_opt, context_opt, semantic_opt, config_opt) ->
         let atn = match atns._parser with
             None ->
             Fmt.(failwith "%s: sim1[%d]: in ATNConfig_ENTER_init, parser ATN was None" 
                    (Ploc.string_of_location loc) i)
           | Some atn -> atn in
         let context_opt = Option.map PC.of_mimick context_opt in
         let semantic_opt = Option.map SC.of_mimick semantic_opt in
         let config_opt = Option.map (AC.of_mimick ~ac_cache:(Some caches.ac) atns) config_opt in
         let rv = AC.init_ATNConfig atn state_opt alt_opt context_opt semantic_opt config_opt in
         AC.Cache.add caches.ac rv ;
         ()

      | ATNConfigSet_ENTER_init (id, fullCtx) ->
         let rv = ACS.init ~id fullCtx in
         ACS.Cache.add caches.acs rv ;
         ()

      | ATNConfigSet_ENTER_add (cs, c, mc_opt) ->
         let cs = ACS.of_mimick ~acs_cache:(Some caches.acs) ~ac_cache:(Some caches.ac) atns cs in
         let c = AC.of_mimick ~ac_cache:(Some caches.ac) atns c in
         let mc_opt = Option.map PC.MC.of_mimick mc_opt in
         let rv = match mc_opt with
             None -> ACS.add cs c
           | Some mergeCache -> ACS.add ~mergeCache cs c
         in
         let cs2 = ACS.to_mimick cs in
         ()

      | ATNConfig_ENTER_incrementRIOC c ->
         let c = AC.of_mimick ~ac_cache:(Some caches.ac) atns c in
         Tracelog.write (ATNConfig_ENTER_incrementRIOC (AC.to_mimick c)) ;
         c.AC.reachesIntoOuterContext <- c.AC.reachesIntoOuterContext + 1 ;
         Tracelog.write (ATNConfig_EXIT_incrementRIOC (AC.to_mimick c)) ;
         ()

      | ATNConfig_ENTER_update_RIOC (c, v) ->
         let c = AC.of_mimick ~ac_cache:(Some caches.ac) atns c in
         Tracelog.write (ATNConfig_ENTER_update_RIOC (AC.to_mimick c, v)) ;
         c.AC.reachesIntoOuterContext <- v ;
         Tracelog.write (ATNConfig_EXIT_update_RIOC (AC.to_mimick c)) ;
         ()

      | ATNConfig_ENTER_set_PFS (c) ->
         let c = AC.of_mimick ~ac_cache:(Some caches.ac) atns c in
         Tracelog.write (ATNConfig_ENTER_set_PFS (AC.to_mimick c)) ;
         c.AC.precedenceFilterSuppressed <- true ;
         Tracelog.write (ATNConfig_EXIT_set_PFS (AC.to_mimick c)) ;
         ()

      | ATNConfigSet_ENTER_set_DIOC cs ->
         let cs = ACS.of_mimick ~acs_cache:(Some caches.acs) ~ac_cache:(Some caches.ac) atns cs in
         Tracelog.write (ATNConfigSet_ENTER_set_DIOC (ACS.to_mimick cs)) ;
         cs.ACS.dipsIntoOuterContext <- true ;
         Tracelog.write (ATNConfigSet_EXIT_set_DIOC (ACS.to_mimick cs)) ;
         ()

      | ATNConfigSet_ENTER_update_HSC (cs, v) ->
         let cs = ACS.of_mimick ~acs_cache:(Some caches.acs) ~ac_cache:(Some caches.ac) atns cs in
         Tracelog.write (ATNConfigSet_ENTER_update_HSC (ACS.to_mimick cs, v)) ;
         cs.ACS.hasSemanticContext <- v ;
         Tracelog.write (ATNConfigSet_EXIT_update_HSC (ACS.to_mimick cs)) ;
         ()

      | ATNConfigSet_ENTER_setReadonly (cs, v) ->
         let cs = ACS.of_mimick ~acs_cache:(Some caches.acs) ~ac_cache:(Some caches.ac) atns cs in
         Tracelog.write (ATNConfigSet_ENTER_setReadonly (ACS.to_mimick cs, v)) ;
         cs.ACS.readonly <- v ;
         Tracelog.write (ATNConfigSet_EXIT_setReadonly (ACS.to_mimick cs)) ;
         ()


    end
  with exc ->
    let bt = Printexc.get_raw_backtrace () in
    Fmt.(pf stderr "%s: ACS.sim1[%d]: Exception @.%a@.%a@."
           (Ploc.string_of_location loc) i
           exn exc
           M.pp_json_log_t j) ;
        Printexc.raise_with_backtrace exc bt
end
