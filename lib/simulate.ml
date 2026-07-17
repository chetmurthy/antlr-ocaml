
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
    ; dfast : DFASt.Cache.t
    ; dfa : DFA.Cache.t
    ; is : IS.Cache.t
    ; las : LAS.Cache.t
    ; lexer : Lexer.t option ref
    }
  let mk () = {
      ac = AC.Cache.mk ()
    ; acs = ACS.Cache.mk ()
    ; dfast = DFASt.Cache.mk ()
    ; dfa = DFA.Cache.mk ()
    ; is = IS.Cache.mk ()
    ; las = LAS.Cache.mk ()
    ; lexer = ref None
    }
end

module ACS = struct
open Caches
let sim1 caches atns (i:int) (loc,j) =
  try
    begin
      match j with
        M.LexerATNConfig_ENTER_init (state_opt, alt_opt, context_opt, semantic_opt, lexerActionExecutor_opt, config_opt) ->
         let atn = atns.Atns.lexer in
         let context_opt = Option.map PC.of_mimick context_opt in
         let semantic_opt = Option.map SC.of_mimick semantic_opt in
         let config_opt = Option.map (AC.of_mimick ~ac_cache:(Some caches.ac) atns) config_opt in
         let rv = AC.init_LexerATNConfig atn state_opt alt_opt context_opt semantic_opt config_opt lexerActionExecutor_opt in
         AC.recache ~ac_cache:caches.ac rv ;
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
         AC.recache ~ac_cache:caches.ac rv ;
         ()

      | ATNConfigSet_ENTER_init (id, fullCtx) ->
         let rv = ACS.init ~id ~fullCtx () in
         ACS.recache ~acs_cache:caches.acs ~ac_cache:caches.ac rv ;
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

      | ATNConfigSet_ENTER_eq (cs1, cs2) ->
         let cs1 = ACS.of_mimick ~acs_cache:(Some caches.acs) ~ac_cache:(Some caches.ac) atns cs1 in
         let cs2 = ACS.of_mimick ~acs_cache:(Some caches.acs) ~ac_cache:(Some caches.ac) atns cs2 in
         let rv = ACS.__eq__ cs1 cs2 in
         ()

      | ATNConfig_ENTER_eq (c1, c2) ->
         let c1 = AC.of_mimick ~ac_cache:(Some caches.ac) atns c1 in
         let c2 = AC.of_mimick ~ac_cache:(Some caches.ac) atns c2 in
         let rv = AC.__eq__ c1 c2 in
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
         ACS.update_HSC cs v ;
         ()

      | ATNConfigSet_ENTER_setReadonly (cs, v) ->
         let cs = ACS.of_mimick ~acs_cache:(Some caches.acs) ~ac_cache:(Some caches.ac) atns cs in
         ACS.setReadonly cs v ;
         ()

      | ATNConfigSet_ENTER_set_UA (cs, v) ->
         let cs = ACS.of_mimick ~acs_cache:(Some caches.acs) ~ac_cache:(Some caches.ac) atns cs in
         ACS.set_UA cs v ;
         ()

      | ATNConfigSet_ENTER_set_CA (cs, v) ->
         let cs = ACS.of_mimick ~acs_cache:(Some caches.acs) ~ac_cache:(Some caches.ac) atns cs in
         Tracelog.write (ATNConfigSet_ENTER_set_CA (ACS.to_mimick cs, v)) ;
         cs.ACS.conflictingAlts <- v ;
         Tracelog.write (ATNConfigSet_EXIT_set_CA (ACS.to_mimick cs)) ;
         ()

      | DFA_ENTER_init (predicted_id, grammarType, atnStartState, decision) ->
         let atn  = Atns.for_grammar atns grammarType in
         let rv = DFA.init ~predicted_id atn grammarType atnStartState decision in
         let _ = DFA.recache ~dfa_cache:caches.dfa ~dfast_cache:caches.dfast ~acs_cache:caches.acs ~ac_cache:caches.ac rv in
         ()

      | DFA_ENTER_states_get(dfa, st) ->
         let dfa = Tracelog.with_disabled (fun () -> DFA.of_mimick ~dfa_cache:(Some caches.dfa) ~dfast_cache:(Some caches.dfast) ~acs_cache:(Some caches.acs) ~ac_cache:(Some caches.ac) atns dfa) () in
         let rv = DFA.states_get dfa (DFASt.of_mimick ~dfast_cache:(Some caches.dfast) ~acs_cache:(Some caches.acs) ~ac_cache:(Some caches.ac) atns st) in
         ()

      | DFA_ENTER_states_len(dfa) ->
         let dfa = Tracelog.with_disabled (fun () -> DFA.of_mimick ~dfa_cache:(Some caches.dfa) ~dfast_cache:(Some caches.dfast) ~acs_cache:(Some caches.acs) ~ac_cache:(Some caches.ac) atns dfa) () in
         let rv = DFA.states_len dfa in
         ()

      | DFA_ENTER_states_add(dfa, st) ->
         let dfa = Tracelog.with_disabled (fun () -> DFA.of_mimick ~dfa_cache:(Some caches.dfa)  ~dfast_cache:(Some caches.dfast) ~acs_cache:(Some caches.acs) ~ac_cache:(Some caches.ac) atns dfa) () in
         let rv = DFA.states_add dfa (DFASt.of_mimick ~dfast_cache:(Some caches.dfast) ~acs_cache:(Some caches.acs) ~ac_cache:(Some caches.ac) atns st) in
         ()

      | DFA_ENTER_set_s0(dfa, st) ->
         let dfa = Tracelog.with_disabled (fun () -> DFA.of_mimick ~dfa_cache:(Some caches.dfa)  ~dfast_cache:(Some caches.dfast) ~acs_cache:(Some caches.acs) ~ac_cache:(Some caches.ac) atns dfa) () in
         let st = DFASt.of_mimick ~dfast_cache:(Some caches.dfast) ~acs_cache:(Some caches.acs) ~ac_cache:(Some caches.ac) atns st in
         DFA.set_s0 dfa st ;
         ()

      | DFA_ENTER_setPrecedenceStartState(dfa, precedence, st) ->
         let dfa = Tracelog.with_disabled (fun () -> DFA.of_mimick ~dfa_cache:(Some caches.dfa)  ~dfast_cache:(Some caches.dfast) ~acs_cache:(Some caches.acs) ~ac_cache:(Some caches.ac) atns dfa) () in
         let st = DFASt.of_mimick ~dfast_cache:(Some caches.dfast) ~acs_cache:(Some caches.acs) ~ac_cache:(Some caches.ac) atns st in
         DFA.setPrecedenceStartState dfa precedence st ;
         ()

      | DFAState_ENTER_init (predicted_id, stateNumber, configs) ->
         let configs = ACS.of_mimick ~acs_cache:(Some caches.acs) ~ac_cache:(Some caches.ac) atns configs in
         let rv = DFASt.init ~predicted_id ~stateNumber ~configs () in
         let _ = DFASt.recache ~dfast_cache:caches.dfast ~acs_cache:caches.acs ~ac_cache:caches.ac rv  in
         ()


      | DFAState_ENTER_set_stateNumber(st, n) ->
         let st = Tracelog.with_disabled (fun () -> DFASt.of_mimick ~dfast_cache:(Some caches.dfast) ~acs_cache:(Some caches.acs) ~ac_cache:(Some caches.ac) atns st) () in
         let () = DFASt.set_stateNumber st n in
         ()

      | DFAState_ENTER_set_configs(st, configs) ->
         let st = DFASt.of_mimick ~dfast_cache:(Some caches.dfast) ~acs_cache:(Some caches.acs) ~ac_cache:(Some caches.ac) atns st in
         let configs = ACS.of_mimick ~acs_cache:(Some caches.acs) ~ac_cache:(Some caches.ac) atns configs in         let () = DFASt.set_configs st configs in
         ()

      | DFAState_ENTER_set_isAcceptState(st, n) ->
         let st = DFASt.of_mimick ~dfast_cache:(Some caches.dfast) ~acs_cache:(Some caches.acs) ~ac_cache:(Some caches.ac) atns st in
         let () = DFASt.set_isAcceptState st n in
         ()

      | DFAState_ENTER_set_requiresFullContext(st, n) ->
         let st = DFASt.of_mimick ~dfast_cache:(Some caches.dfast) ~acs_cache:(Some caches.acs) ~ac_cache:(Some caches.ac) atns st in
         let () = DFASt.set_requiresFullContext st n in
         ()


      | DFAState_ENTER_set_prediction(st, n) ->
         let st = DFASt.of_mimick ~dfast_cache:(Some caches.dfast) ~acs_cache:(Some caches.acs) ~ac_cache:(Some caches.ac) atns st in
         let () = DFASt.set_prediction st n in
         ()

      | DFAState_ENTER_set_predicates(st, n) ->
         let st = DFASt.of_mimick ~dfast_cache:(Some caches.dfast) ~acs_cache:(Some caches.acs) ~ac_cache:(Some caches.ac) atns st in
         let () = DFASt.set_predicates st (Option.map (List.map PP.of_mimick) n) in
         ()


      | DFAState_ENTER_set_lexerActionExecutor(st, n) ->
         let st = DFASt.of_mimick ~dfast_cache:(Some caches.dfast) ~acs_cache:(Some caches.acs) ~ac_cache:(Some caches.ac) atns st in
         let () = DFASt.set_lexerActionExecutor st n in
         ()


      | DFAState_ENTER_makeEdges(st, n) ->
         let st = DFASt.of_mimick ~dfast_cache:(Some caches.dfast) ~acs_cache:(Some caches.acs) ~ac_cache:(Some caches.ac) atns st in
         let () = DFASt.makeEdges st n in
         ()


      | DFAState_ENTER_setEdge(st, n, v) ->
         let st = DFASt.of_mimick ~dfast_cache:(Some caches.dfast) ~acs_cache:(Some caches.acs) ~ac_cache:(Some caches.ac) atns st in
         let v = DFASt.of_mimick ~dfast_cache:(Some caches.dfast) ~acs_cache:(Some caches.acs) ~ac_cache:(Some caches.ac) atns v in
         let () = DFASt.setEdge st n v in
         ()

      | InputStream_ENTER_init (predicted_id, strdata) ->
         let rv = IS.init ~predicted_id strdata () in
         let _ = IS.recache ~is_cache:caches.is rv  in
         ()

      | InputStream_ENTER_LA (is, n) ->
         let rv = IS.la (IS.of_mimick ~is_cache:(Some caches.is) is) n in
         ()

      | InputStream_ENTER_consume is ->
         let rv = IS.consume (IS.of_mimick ~is_cache:(Some caches.is) is) in
         ()

      | InputStream_ENTER_seek (is, n) ->
         let rv = IS.seek (IS.of_mimick ~is_cache:(Some caches.is) is) n in
         ()

      | InputStream_ENTER_getText (is, n, m) ->
         let rv = IS.getText (IS.of_mimick ~is_cache:(Some caches.is) is) n m in
         ()

      | LexerATNSimulator_ENTER_init (predicted_id, decisionToDFA, sharedContextCache) ->
         let atn  = Atns.for_grammar atns Atn.LEXER in
         let decisionToDFA = Array.map (DFA.of_mimick ~dfa_cache:(Some caches.dfa)  ~dfast_cache:(Some caches.dfast) ~acs_cache:(Some caches.acs) ~ac_cache:(Some caches.ac) atns) decisionToDFA in
         let sharedContextCache = List.map PC.of_mimick sharedContextCache in
         let recog = match !(caches.lexer) with
             None -> failwith "internal error in simulation: exer not initialized"
           | Some l -> l.recog in
         let rv : LAS.t = LAS.init ~predicted_id atn decisionToDFA sharedContextCache ~recog () in
         let _ : LAS.t = LAS.recache ~las_cache:caches.las ~dfa_cache:caches.dfa ~dfast_cache:caches.dfast ~acs_cache:caches.acs ~ac_cache:caches.ac rv  in
         ()

      | LexerATNSimulator_ENTER_match (las, is, n) ->
         let las = LAS.of_mimick ~las_cache:(Some caches.las) ~dfa_cache:(Some caches.dfa) ~dfast_cache:(Some caches.dfast) ~acs_cache:(Some caches.acs) ~ac_cache:(Some caches.ac) ~recog:(Some (Std.outSome !(caches.lexer)).recog) atns las in
         let is = IS.of_mimick ~is_cache:(Some caches.is) is in
         let rv = LAS._match las is n in
         ()

      | Lexer_ENTER_init is ->
         let interp = match LAS.Cache.get caches.las 0 with
             las -> las
           | exception Not_found ->
              failwith "No LexerATNSimulator inited before Lexer.__init__" in
         let is = IS.of_mimick ~is_cache:(Some caches.is) is in
         let l : Lexer.t = Lexer.init is () in
         assert (!(caches.lexer) = None) ;
         caches.lexer := Some l ;
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
