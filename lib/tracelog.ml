(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.utils,pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.yojson,pa_ppx.deriving_plugins.located_yojson,pa_ppx.import *)

open Pa_ppx_utils
open Coll
open Pa_ppx_located_yojson
module M = Mimick

let _enabled = ref false
let _oc = ref stdout

let enabled () = !_enabled
let oc() = !_oc

let disabled =
  MHS.ofList [
(*
    "ENTER ATNConfigSet.add";
    "EXIT ATNConfigSet.add";
    "ENTER ATNConfigSet.__init__";
    "EXIT ATNConfigSet.__init__";
    "ENTER ATNConfigSet.__eq__";
    "EXIT ATNConfigSet.__eq__";
    "ENTER ATNConfigSet.set_DIOC";
    "EXIT ATNConfigSet.set_DIOC";
    "ENTER ATNConfigSet.setReadonly";
    "EXIT ATNConfigSet.setReadonly";
    "ENTER ATNConfigSet.update_HSC";
    "EXIT ATNConfigSet.update_HSC";
    "ENTER ATNConfigSet.set_UA";
    "EXIT ATNConfigSet.set_UA";
    "ENTER ATNConfigSet.set_CA";
    "EXIT ATNConfigSet.set_CA";
    "ENTER ATNConfigSet.getOrAdd";
    "EXIT ATNConfigSet.getOrAdd";
    "ATNConfigSet.optimizeConfigs";
    "ENTER OrderedATNConfigSet.__init__";
    "EXIT OrderedATNConfigSet.__init__";

    "ENTER ATNConfig.__init__";
    "EXIT ATNConfig.__init__";
    "ENTER ATNConfig.__eq__";
    "EXIT ATNConfig.__eq__";
    "ENTER ATNConfig.equalsForConfigSet";
    "EXIT ATNConfig.equalsForConfigSet";
    "ENTER ATNConfig.incrementRIOC";
    "EXIT ATNConfig.incrementRIOC";
    "ENTER ATNConfig.update_RIOC";
    "EXIT ATNConfig.update_RIOC";
    "ENTER ATNConfig.set_PFS";
    "EXIT ATNConfig.set_PFS";

    "ENTER LexerATNConfig.__init__";
    "EXIT LexerATNConfig.__init__";
    "ENTER LexerATNConfig.__eq__";
    "EXIT LexerATNConfig.__eq__";
 *)
    "ENTER mergeCache_add";
    "EXIT mergeCache_add";
    "ENTER PredictionContext.merge";
    "EXIT PredictionContext.merge";
    "ENTER PredictionContext.mergeSingletons";
    "EXIT PredictionContext.mergeSingletons";
    "ENTER PredictionContext.mergeRoot";
    "EXIT PredictionContext.mergeRoot";
    "ENTER PredictionContext.mergeArrays";
    "EXIT PredictionContext.mergeArrays";
(*    
    "ENTER DFA.__init__";
    "EXIT DFA.__init__";
    "ENTER DFA.set_s0";
    "EXIT DFA.set_s0";
    "ENTER DFA.states_add";
    "EXIT DFA.states_add";
    "ENTER DFA.states_get";
    "EXIT DFA.states_get";
    "ENTER DFA.states_len";
    "EXIT DFA.states_len";

    "ENTER DFAState.__init__";
    "EXIT DFAState.__init__";
    "ENTER DFAState.makeEdges";
    "EXIT DFAState.makeEdges";
    "ENTER DFAState.setEdge";
    "EXIT DFAState.setEdge";
    "ENTER DFAState.set_isAcceptState";
    "EXIT DFAState.set_isAcceptState";
    "ENTER DFAState.set_lexerActionExecutor";
    "EXIT DFAState.set_lexerActionExecutor";
    "ENTER DFAState.set_prediction";
    "EXIT DFAState.set_prediction";
    "ENTER DFAState.set_stateNumber";
    "EXIT DFAState.set_stateNumber";

    "ENTER LexerATNSimulator.__init__";
    "EXIT LexerATNSimulator.__init__";
    "ENTER LexerATNSimulator.match";
    "EXIT LexerATNSimulator.match";
    "ENTER Lexer.nextToken";
    "EXIT Lexer.nextToken";
 *)
    "Lexer.__init__";
    "Lexer.reset";
    "Lexer.skip";
    "Lexer.more";
    "Lexer.mode";
    "Lexer.pushMode";
    "Lexer.popMode";
    "Lexer.emitToken";
    "Lexer.emit";
    "Lexer.emitEOF";

    "EXIT ParserATNSimulator.__init__"
    ] 23

let is_disabled j =
    match j with
      (_, `List ((_, `String s) :: _)) -> MHS.mem s disabled
    | _ -> false

let write jlog =
  if enabled() then
    let j = [%to_located_yojson: M.json_log_t] jlog in
    if not (is_disabled j) then
      Json.pp_hum_to_channel ~std:true (oc()) j

let writemsg txt =
  if enabled() then
  let j = (Ploc.dummy, `List [(Ploc.dummy, `String txt)]) in
    Json.pp_hum_to_channel ~std:true (oc()) j

let with_disabled f () =
  let old_enabled = !_enabled in
  try
    _enabled := false ;
    let rv = f () in
    _enabled := old_enabled ;
    rv
  with exc ->
    let bt = Printexc.get_raw_backtrace () in
    _enabled := old_enabled ;
    Printexc.raise_with_backtrace exc bt
