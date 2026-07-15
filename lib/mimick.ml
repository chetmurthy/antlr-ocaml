(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.utils,pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.yojson,pa_ppx.deriving_plugins.located_yojson,pa_ppx.import *)

open Util
open Atn

open Rresult.R
let state_id_to_yojson (STID n) = [%to_yojson: int] n
let state_id_of_yojson j =
  ([%of_yojson: int] j) >>= (fun n -> Result.Ok (STID n))
let state_id_to_located_yojson (STID n) = [%to_located_yojson: int] n
let state_id_of_located_yojson j =
  ([%of_located_yojson: int] j) >>= (fun n -> Result.Ok (STID n))

type deser_state_id = state_id[@yojson.to_yojson state_id_to_yojson]
              [@yojson.of_yojson state_id_of_yojson]
              [@located_yojson.to_located_yojson state_id_to_located_yojson]
              [@located_yojson.of_located_yojson state_id_of_located_yojson]
[@@deriving yojson,located_yojson, show]
let equal_deser_state_id (x:deser_state_id) y = x=y

type config_t =
  ATNConfig of {
    id : int
  ; state : deser_state_id
  ; alt : int
  ; context : prediction_context_t option
  ; semanticContext : semantic_context_t
  ; reachesIntoOuterContext : int
  ; precedenceFilterSuppressed : bool
  }
| LexerATNConfig of {
    id : int
  ; state : deser_state_id
  ; alt : int
  ; context : prediction_context_t option
  ; semanticContext : semantic_context_t
  ; reachesIntoOuterContext : int
  ; precedenceFilterSuppressed : bool
  ; lexerActionExecutor : lexer_action_executor_t option
  ; passedThroughNonGreedyDecision : bool
  }

and config_set_t = {
    fullCtx : bool
  ; configs : (string * config_t) list
  ; configHT : (string * (string * config_t) list) list option
  ; readonly : bool
  ; conflictingAlts : int list option
  ; hasSemanticContext : bool
  ; dipsIntoOuterContext : bool
  ; uniqueAlt : int
  ; id : int
  }
and prediction_context_t =
  PC_SINGLETON of { parentCtx : prediction_context_t option
                  ; returnState : int
                  }[@yojson.name "SingletonPredictionContext"]
                    [@located_yojson.name "SingletonPredictionContext"]
| PC_EMPTY[@yojson.name "EmptyPredictionContext"]
                    [@located_yojson.name "EmptyPredictionContext"]
| PC_ARRAY of { parents : prediction_context_t option list
              ; returnStates : int list
              }
                [@yojson.name "ArrayPredictionContext"]
                [@located_yojson.name "ArrayPredictionContext"]
and semantic_context_t =
  SC_EMPTY
    [@yojson.name "EmptySemanticContext"]
    [@located_yojson.name "EmptySemanticContext"]
| SC_PREDICATE of { ruleIndex : int
                  ; predIndex : int
                  ; isCtxDependent : bool
                  }
                    [@yojson.name "Predicate"]
                    [@located_yojson.name "Predicate"]
| SC_PRECEDENCE of { precedence : int
                   }
                     [@yojson.name "PrecedencePredicate"]
                     [@located_yojson.name "PrecedencePredicate"]
| SC_AND of { opnds : semantic_context_t list }
              [@yojson.name "AND"]
              [@located_yojson.name "AND"]
| SC_OR of { opnds : semantic_context_t list }
             [@yojson.name "OR"]
             [@located_yojson.name "OR"]

and dfa_t = {
    grammarType : atn_type_t
  ; id : int
  ; atnStartState : deser_state_id
  ; decision : int
  ; _states : dfa_state_t strmap
  ; precedenceDfa : bool
  ; s0 : dfa_state_t option
  }

and dfa_state_t = {
    id : int
  ; stateNumber : int
  ; configset : config_set_t
  ; edges : int option array
  ; isAcceptState : bool
  ; prediction : int
  ; lexerActionExecutor : lexer_action_executor_t option
  ; requiresFullContext : bool
  ; predicates : pred_prediction_t list option
  }

and pred_prediction_t =
  PredPrediction of {
      alt : int
    ; pred : semantic_context_t
    }
and lexer_action_executor_t = {
    lexerActions : Atn.LexerAction.t list
  }

and sim_state_t =
  SimState of {
      index : int
    ; line : int
    ; column : int
    ; dfaState : dfa_state_t option
  }

and lexer_atn_simulator_t =
  LexerATNSimulator of {
      id : int
    ; sharedContextCache : prediction_context_cache_t
(* don't demarshal this, b/c it's big and never changes
    ; atn : Atn.t
 *)
    ; column : int
    ; decisionToDFA : dfa_t array
    ; line : int
    ; mode : int
    ; prevAccept : sim_state_t
    ; startIndex : int
    }

and prediction_context_cache_t = prediction_context_t list

and common_token_factory_t =
  CommonTokenFactory of {
      copyText : bool
    }
and token_t =
  Token of {
      _text : string option
    ; _type : int
    ; channel : int
    ; column : int
    ; line : int
    ; source : string * string
    ; start : int
    ; stop : int
    ; tokenIndex : int
    }
and lexer_t = 
  Lexer of {
      _channel : int
    ; _factory : common_token_factory_t
    ; _interp : lexer_atn_simulator_t option
    ; _hitEOF : bool
    ; _mode : int
    ; _modeStack : int list
    ; _text : string option
    ; _token : token_t option
    ; _tokenStartCharIndex : int
    ; _tokenStartColumn : int
    ; _tokenStartLine : int
    ; _type: int
  }

and prediction_mode_t =
  SLL[@yojson.name "PredictionMode.LL"]
                    [@located_yojson.name "PredictionMode.SLL"]
 | LL[@yojson.name "PredictionMode.SLL"]
                    [@located_yojson.name "PredictionMode.LL"]
 | LL_EXACT_AMBIG_DETECTION[@yojson.name "PredictionMode.LL_EXACT_AMBIG_DETECTION"]
                    [@located_yojson.name "PredictionMode.LL_EXACT_AMBIG_DETECTION"]

and parser_atn_simulator_t =
  ParserATNSimulator of {
      id : int
    ; sharedContextCache : prediction_context_cache_t
(* don't demarshal this, b/c it's big and never changes
    ; atn : Atn.t
 *)
    ; decisionToDFA : dfa_t array
    ; predictionMode : prediction_mode_t
    ; _startIndex : int
    ; _outerContext : int option
    ; _dfa : dfa_t option
    ; mergeCache : int option
    }

and merge_cache_entry_t = {
    k : prediction_context_t * prediction_context_t
  ; v : prediction_context_t
  }

and merge_cache_t =
  MergeCache of (string * merge_cache_entry_t) list

and input_stream_t =
  InputStream of {
      id : int
    ; name : string
    ; strdata : string
    ; _index : int
    ; data : int array
    ; _size : int
  }

and edge_serialization_type_t = [%import: Types.edge_serialization_type_t]
and edge_t = [%import: Types.edge_t]

[@@deriving yojson,located_yojson, show]

type json_log_t =
  ATNConfig_ENTER_eq of config_t * config_t
                                    [@yojson.name "ENTER ATNConfig.__eq__"]
                                    [@located_yojson.name "ENTER ATNConfig.__eq__"]
| ATNConfig_EXIT_eq of bool
                                    [@yojson.name "EXIT ATNConfig.__eq__"]
                                    [@located_yojson.name "EXIT ATNConfig.__eq__"]
| LexerATNConfig_ENTER_eq of config_t * config_t
                                    [@yojson.name "ENTER LexerATNConfig.__eq__"]
                                    [@located_yojson.name "ENTER LexerATNConfig.__eq__"]
| LexerATNConfig_EXIT_eq of bool
                                    [@yojson.name "EXIT LexerATNConfig.__eq__"]
                                    [@located_yojson.name "EXIT LexerATNConfig.__eq__"]
| ATNConfig_ENTER_equalsForConfigSet of config_t * config_t
                                    [@yojson.name "ENTER ATNConfig.equalsForConfigSet"]
                                    [@located_yojson.name "ENTER ATNConfig.equalsForConfigSet"]
| ATNConfig_EXIT_equalsForConfigSet of bool
                                    [@yojson.name "EXIT ATNConfig.equalsForConfigSet"]
                                    [@located_yojson.name "EXIT ATNConfig.equalsForConfigSet"]
| ATNConfig_ENTER_incrementRIOC of config_t
                                    [@yojson.name "ENTER ATNConfig.incrementRIOC"]
                                    [@located_yojson.name "ENTER ATNConfig.incrementRIOC"]
| ATNConfig_EXIT_incrementRIOC of config_t
                                    [@yojson.name "EXIT ATNConfig.incrementRIOC"]
                                    [@located_yojson.name "EXIT ATNConfig.incrementRIOC"]

| ATNConfig_ENTER_update_RIOC of config_t * int
                                    [@yojson.name "ENTER ATNConfig.update_RIOC"]
                                    [@located_yojson.name "ENTER ATNConfig.update_RIOC"]
| ATNConfig_EXIT_update_RIOC of config_t
                                    [@yojson.name "EXIT ATNConfig.update_RIOC"]
                                    [@located_yojson.name "EXIT ATNConfig.update_RIOC"]

| ATNConfig_ENTER_set_PFS of config_t
                                    [@yojson.name "ENTER ATNConfig.set_PFS"]
                                    [@located_yojson.name "ENTER ATNConfig.set_PFS"]
| ATNConfig_EXIT_set_PFS of config_t
                                    [@yojson.name "EXIT ATNConfig.set_PFS"]
                                    [@located_yojson.name "EXIT ATNConfig.set_PFS"]

| ATNConfigSet_ENTER_update_HSC of config_set_t * bool
                                    [@yojson.name "ENTER ATNConfigSet.update_HSC"]
                                    [@located_yojson.name "ENTER ATNConfigSet.update_HSC"]
| ATNConfigSet_EXIT_update_HSC of config_set_t
                                    [@yojson.name "EXIT ATNConfigSet.update_HSC"]
                                    [@located_yojson.name "EXIT ATNConfigSet.update_HSC"]

| ATNConfigSet_ENTER_setReadonly of config_set_t * bool
                                    [@yojson.name "ENTER ATNConfigSet.setReadonly"]
                                    [@located_yojson.name "ENTER ATNConfigSet.setReadonly"]
| ATNConfigSet_EXIT_setReadonly of config_set_t
                                    [@yojson.name "EXIT ATNConfigSet.setReadonly"]
                                    [@located_yojson.name "EXIT ATNConfigSet.setReadonly"]


| DFAState_ENTER_init of int * int * config_set_t
                      [@yojson.name "ENTER DFAState.__init__"]
                      [@located_yojson.name "ENTER DFAState.__init__"]
| DFAState_EXIT_init of dfa_state_t
                      [@yojson.name "EXIT DFAState.__init__"]
                      [@located_yojson.name "EXIT DFAState.__init__"]

| DFAState_ENTER_makeEdges of dfa_state_t * int option array
                      [@yojson.name "ENTER DFAState.makeEdges"]
                      [@located_yojson.name "ENTER DFAState.makeEdges"]
| DFAState_EXIT_makeEdges of dfa_state_t
                      [@yojson.name "EXIT DFAState.makeEdges"]
                      [@located_yojson.name "EXIT DFAState.makeEdges"]


| DFAState_ENTER_setEdge of dfa_state_t * int * dfa_state_t
                      [@yojson.name "ENTER DFAState.setEdge"]
                      [@located_yojson.name "ENTER DFAState.setEdge"]
| DFAState_EXIT_setEdge of dfa_state_t
                      [@yojson.name "EXIT DFAState.setEdge"]
                      [@located_yojson.name "EXIT DFAState.setEdge"]

| DFAState_ENTER_set_stateNumber of dfa_state_t * int
                      [@yojson.name "ENTER DFAState.set_stateNumber"]
                      [@located_yojson.name "ENTER DFAState.set_stateNumber"]
| DFAState_EXIT_set_stateNumber of dfa_state_t
                      [@yojson.name "EXIT DFAState.set_stateNumber"]
                      [@located_yojson.name "EXIT DFAState.set_stateNumber"]

| DFAState_ENTER_set_configs of dfa_state_t * config_set_t
                      [@yojson.name "ENTER DFAState.set_configs"]
                      [@located_yojson.name "ENTER DFAState.set_configs"]
| DFAState_EXIT_set_configs of dfa_state_t
                      [@yojson.name "EXIT DFAState.set_configs"]
                      [@located_yojson.name "EXIT DFAState.set_configs"]

| DFAState_ENTER_set_isAcceptState of dfa_state_t * bool
                      [@yojson.name "ENTER DFAState.set_isAcceptState"]
                      [@located_yojson.name "ENTER DFAState.set_isAcceptState"]
| DFAState_EXIT_set_isAcceptState of dfa_state_t
                      [@yojson.name "EXIT DFAState.set_isAcceptState"]
                      [@located_yojson.name "EXIT DFAState.set_isAcceptState"]

| DFAState_ENTER_set_requiresFullContext of dfa_state_t * bool
                      [@yojson.name "ENTER DFAState.set_requiresFullContext"]
                      [@located_yojson.name "ENTER DFAState.set_requiresFullContext"]
| DFAState_EXIT_set_requiresFullContext of dfa_state_t
                      [@yojson.name "EXIT DFAState.set_requiresFullContext"]
                      [@located_yojson.name "EXIT DFAState.set_requiresFullContext"]

| DFAState_ENTER_set_prediction of dfa_state_t * int
                      [@yojson.name "ENTER DFAState.set_prediction"]
                      [@located_yojson.name "ENTER DFAState.set_prediction"]
| DFAState_EXIT_set_prediction of dfa_state_t
                      [@yojson.name "EXIT DFAState.set_prediction"]
                      [@located_yojson.name "EXIT DFAState.set_prediction"]

| DFAState_ENTER_set_predicates of dfa_state_t * pred_prediction_t list option
                      [@yojson.name "ENTER DFAState.set_predicates"]
                      [@located_yojson.name "ENTER DFAState.set_predicates"]
| DFAState_EXIT_set_predicates of dfa_state_t
                      [@yojson.name "EXIT DFAState.set_predicates"]
                      [@located_yojson.name "EXIT DFAState.set_predicates"]

| DFAState_ENTER_set_lexerActionExecutor of dfa_state_t * lexer_action_executor_t option
                      [@yojson.name "ENTER DFAState.set_lexerActionExecutor"]
                      [@located_yojson.name "ENTER DFAState.set_lexerActionExecutor"]
| DFAState_EXIT_set_lexerActionExecutor of dfa_state_t
                      [@yojson.name "EXIT DFAState.set_lexerActionExecutor"]
                      [@located_yojson.name "EXIT DFAState.set_lexerActionExecutor"]


| DFA_ENTER_init of int * atn_type_t * deser_state_id * int
                      [@yojson.name "ENTER DFA.__init__"]
                      [@located_yojson.name "ENTER DFA.__init__"]
| DFA_EXIT_init of int * dfa_t
                      [@yojson.name "EXIT DFA.__init__"]
                      [@located_yojson.name "EXIT DFA.__init__"]
| DFA_ENTER_states_get of dfa_t * dfa_state_t
                      [@yojson.name "ENTER DFA.states_get"]
                      [@located_yojson.name "ENTER DFA.states_get"]
| DFA_EXIT_states_get of int * dfa_state_t option
                      [@yojson.name "EXIT DFA.states_get"]
                      [@located_yojson.name "EXIT DFA.states_get"]
| DFA_ENTER_states_len of dfa_t
                      [@yojson.name "ENTER DFA.states_len"]
                      [@located_yojson.name "ENTER DFA.states_len"]
| DFA_EXIT_states_len of int
                      [@yojson.name "EXIT DFA.states_len"]
                      [@located_yojson.name "EXIT DFA.states_len"]
| DFA_ENTER_states_add of dfa_t * dfa_state_t
                      [@yojson.name "ENTER DFA.states_add"]
                      [@located_yojson.name "ENTER DFA.states_add"]
| DFA_EXIT_states_add of int * dfa_t
                      [@yojson.name "EXIT DFA.states_add"]
                      [@located_yojson.name "EXIT DFA.states_add"]

| DFA_ENTER_set_s0 of dfa_t * dfa_state_t
                      [@yojson.name "ENTER DFA.set_s0"]
                      [@located_yojson.name "ENTER DFA.set_s0"]
| DFA_EXIT_set_s0 of int * dfa_t
                      [@yojson.name "EXIT DFA.set_s0"]
                      [@located_yojson.name "EXIT DFA.set_s0"]

| DFA_ENTER_setPrecedenceStartState of dfa_t * int * dfa_state_t
                      [@yojson.name "ENTER DFA.setPrecedenceStartState"]
                      [@located_yojson.name "ENTER DFA.setPrecedenceStartState"]
| DFA_EXIT_setPrecedenceStartState of dfa_t
                      [@yojson.name "EXIT DFA.setPrecedenceStartState"]
                      [@located_yojson.name "EXIT DFA.setPrecedenceStartState"]

| LexerATNSimulator_add_state of int * dfa_state_t
                      [@yojson.name "LexerATNSimulator.__add_state__"]
                      [@located_yojson.name "LexerATNSimulator.__add_state__"]

| LexerATNSimulator_ENTER_addDFAEdge of lexer_atn_simulator_t * dfa_state_t * int * dfa_state_t option * config_set_t option
                      [@yojson.name "ENTER LexerATNSimulator.addDFAEdge"]
                      [@located_yojson.name "ENTER LexerATNSimulator.addDFAEdge"]
| LexerATNSimulator_EXIT_addDFAEdge of lexer_atn_simulator_t * dfa_state_t
                      [@yojson.name "EXIT LexerATNSimulator.addDFAEdge"]
                      [@located_yojson.name "EXIT LexerATNSimulator.addDFAEdge"]

| LexerATNSimulator_ENTER_addDFAState of lexer_atn_simulator_t * config_set_t
                      [@yojson.name "ENTER LexerATNSimulator.addDFAState"]
                      [@located_yojson.name "ENTER LexerATNSimulator.addDFAState"]
| LexerATNSimulator_EXIT_addDFAState of lexer_atn_simulator_t * dfa_state_t
                      [@yojson.name "EXIT LexerATNSimulator.addDFAState"]
                      [@located_yojson.name "EXIT LexerATNSimulator.addDFAState"]

| LexerATNSimulator_ENTER_init of int * dfa_t array * prediction_context_cache_t
                      [@yojson.name "ENTER LexerATNSimulator.__init__"]
                      [@located_yojson.name "ENTER LexerATNSimulator.__init__"]
| LexerATNSimulator_EXIT_init of lexer_atn_simulator_t
                      [@yojson.name "EXIT LexerATNSimulator.__init__"]
                      [@located_yojson.name "EXIT LexerATNSimulator.__init__"]
| LexerATNSimulator_ENTER_match of lexer_atn_simulator_t * input_stream_t * int
                      [@yojson.name "ENTER LexerATNSimulator.match"]
                      [@located_yojson.name "ENTER LexerATNSimulator.match"]
| LexerATNSimulator_EXIT_match of lexer_atn_simulator_t * int
                      [@yojson.name "EXIT LexerATNSimulator.match"]
                      [@located_yojson.name "EXIT LexerATNSimulator.match"]
| LexerATNSimulator_ENTER_matchATN of lexer_atn_simulator_t * input_stream_t
                      [@yojson.name "ENTER LexerATNSimulator.matchATN"]
                      [@located_yojson.name "ENTER LexerATNSimulator.matchATN"]
| LexerATNSimulator_EXIT_matchATN of lexer_atn_simulator_t * int
                      [@yojson.name "EXIT LexerATNSimulator.matchATN"]
                      [@located_yojson.name "EXIT LexerATNSimulator.matchATN"]

| LexerATNSimulator_ENTER_execATN of lexer_atn_simulator_t * input_stream_t * dfa_state_t
                      [@yojson.name "ENTER LexerATNSimulator.execATN"]
                      [@located_yojson.name "ENTER LexerATNSimulator.execATN"]
| LexerATNSimulator_EXIT_execATN of lexer_atn_simulator_t * int
                      [@yojson.name "EXIT LexerATNSimulator.execATN"]
                      [@located_yojson.name "EXIT LexerATNSimulator.execATN"]
| LexerATNSimulator_ENTER_evaluatePredicate of lexer_atn_simulator_t * input_stream_t * int * int * bool
                      [@yojson.name "ENTER LexerATNSimulator.evaluatePredicate"]
                      [@located_yojson.name "ENTER LexerATNSimulator.evaluatePredicate"]
| LexerATNSimulator_EXIT_evaluatePredicate of lexer_atn_simulator_t * bool
                      [@yojson.name "EXIT LexerATNSimulator.evaluatePredicate"]
                      [@located_yojson.name "EXIT LexerATNSimulator.evaluatePredicate"]

| LexerATNSimulator_ENTER_closure of lexer_atn_simulator_t * input_stream_t * config_t * config_set_t * bool * bool * bool
                      [@yojson.name "ENTER LexerATNSimulator.closure"]
                      [@located_yojson.name "ENTER LexerATNSimulator.closure"]
| LexerATNSimulator_EXIT_closure of lexer_atn_simulator_t * bool * config_set_t
                      [@yojson.name "EXIT LexerATNSimulator.closure"]
                      [@located_yojson.name "EXIT LexerATNSimulator.closure"]

| LexerATNSimulator_ENTER_getEpsilonTarget of lexer_atn_simulator_t * input_stream_t * config_t * edge_t * config_set_t * bool * bool
                      [@yojson.name "ENTER LexerATNSimulator.getEpsilonTarget"]
                      [@located_yojson.name "ENTER LexerATNSimulator.getEpsilonTarget"]
| LexerATNSimulator_EXIT_getEpsilonTarget of lexer_atn_simulator_t * config_t option * config_set_t
                      [@yojson.name "EXIT LexerATNSimulator.getEpsilonTarget"]
                      [@located_yojson.name "EXIT LexerATNSimulator.getEpsilonTarget"]


| LexerATNSimulator_ENTER_captureSimState of lexer_atn_simulator_t * sim_state_t * input_stream_t * dfa_state_t
                      [@yojson.name "ENTER LexerATNSimulator.captureSimState"]
                      [@located_yojson.name "ENTER LexerATNSimulator.captureSimState"]
| LexerATNSimulator_EXIT_captureSimState of lexer_atn_simulator_t * sim_state_t
                      [@yojson.name "EXIT LexerATNSimulator.captureSimState"]
                      [@located_yojson.name "EXIT LexerATNSimulator.captureSimState"]


| LexerATNSimulator_ENTER_computeStartState of lexer_atn_simulator_t * input_stream_t * deser_state_id
                      [@yojson.name "ENTER LexerATNSimulator.computeStartState"]
                      [@located_yojson.name "ENTER LexerATNSimulator.computeStartState"]
| LexerATNSimulator_EXIT_computeStartState of config_set_t
                      [@yojson.name "EXIT LexerATNSimulator.computeStartState"]
                      [@located_yojson.name "EXIT LexerATNSimulator.computeStartState"]


| Lexer_init of lexer_t
                      [@yojson.name "Lexer.__init__"]
                      [@located_yojson.name "Lexer.__init__"]
| Lexer_ENTER_nextToken of lexer_t
                      [@yojson.name "ENTER Lexer.nextToken"]
                      [@located_yojson.name "ENTER Lexer.nextToken"]
| Lexer_EXIT_nextToken of lexer_t * token_t
                      [@yojson.name "EXIT Lexer.nextToken"]
                      [@located_yojson.name "EXIT Lexer.nextToken"]
| Lexer_emit of lexer_t * token_t
                      [@yojson.name "Lexer.emit"]
                      [@located_yojson.name "Lexer.emit"]
| Lexer_emitEOF of lexer_t * token_t
                      [@yojson.name "Lexer.emitEOF"]
                      [@located_yojson.name "Lexer.emitEOF"]
| Lexer_skip of lexer_t
                      [@yojson.name "Lexer.skip"]
                      [@located_yojson.name "Lexer.skip"]
| Lexer_mode of lexer_t * int
                      [@yojson.name "Lexer.mode"]
                      [@located_yojson.name "Lexer.mode"]
| Lexer_pushMode of lexer_t * int
                      [@yojson.name "Lexer.pushMode"]
                      [@located_yojson.name "Lexer.pushMode"]
| Lexer_popMode of lexer_t * int
                      [@yojson.name "Lexer.popMode"]
                      [@located_yojson.name "Lexer.popMode"]
| Lexer_more of lexer_t
                      [@yojson.name "Lexer.more"]
                      [@located_yojson.name "Lexer.more"]

| ParserATNSimulator_ENTER_init of dfa_t array * prediction_context_cache_t
                      [@yojson.name "ENTER ParserATNSimulator.__init__"]
                      [@located_yojson.name "ENTER ParserATNSimulator.__init__"]
| ParserATNSimulator_EXIT_init of parser_atn_simulator_t
                      [@yojson.name "EXIT ParserATNSimulator.__init__"]
                      [@located_yojson.name "EXIT ParserATNSimulator.__init__"]

| PredictionContext_ENTER_merge of prediction_context_t * prediction_context_t * bool * merge_cache_t option
                      [@yojson.name "ENTER PredictionContext.merge"]
                      [@located_yojson.name "ENTER PredictionContext.merge"]
| PredictionContext_EXIT_merge of prediction_context_t
                      [@yojson.name "EXIT PredictionContext.merge"]
                      [@located_yojson.name "EXIT PredictionContext.merge"]
| PredictionContext_ENTER_mergeRoot of prediction_context_t * prediction_context_t * bool
                      [@yojson.name "ENTER PredictionContext.mergeRoot"]
                      [@located_yojson.name "ENTER PredictionContext.mergeRoot"]
| PredictionContext_EXIT_mergeRoot of prediction_context_t option
                      [@yojson.name "EXIT PredictionContext.mergeRoot"]
                      [@located_yojson.name "EXIT PredictionContext.mergeRoot"]
| PredictionContext_ENTER_mergeArrays of prediction_context_t * prediction_context_t * bool * merge_cache_t option
                      [@yojson.name "ENTER PredictionContext.mergeArrays"]
                      [@located_yojson.name "ENTER PredictionContext.mergeArrays"]
| PredictionContext_EXIT_mergeArrays of prediction_context_t
                      [@yojson.name "EXIT PredictionContext.mergeArrays"]
                      [@located_yojson.name "EXIT PredictionContext.mergeArrays"]

| MergeCache_ENTER_add of merge_cache_t * prediction_context_t * prediction_context_t * prediction_context_t
                      [@yojson.name "ENTER mergeCache_add"]
                      [@located_yojson.name "ENTER mergeCache_add"]
| MergeCache_EXIT_add of merge_cache_t
                      [@yojson.name "EXIT mergeCache_add"]
                      [@located_yojson.name "EXIT mergeCache_add"]
| PredictionContext_ENTER_mergeSingletons of prediction_context_t * prediction_context_t * bool * merge_cache_t option
                      [@yojson.name "ENTER PredictionContext.mergeSingletons"]
                      [@located_yojson.name "ENTER PredictionContext.mergeSingletons"]
| PredictionContext_EXIT_mergeSingletons of prediction_context_t * merge_cache_t option
                      [@yojson.name "EXIT PredictionContext.mergeSingletons"]
                      [@located_yojson.name "EXIT PredictionContext.mergeSingletons"]

| ATNConfig_ENTER_init of int * deser_state_id option * int option * prediction_context_t option * semantic_context_t option * config_t option
                                    [@yojson.name "ENTER ATNConfig.__init__"]
                                    [@located_yojson.name "ENTER ATNConfig.__init__"]
| ATNConfig_EXIT_init of config_t
                                    [@yojson.name "EXIT ATNConfig.__init__"]
                                    [@located_yojson.name "EXIT ATNConfig.__init__"]

| LexerATNConfig_ENTER_init of deser_state_id option * int option * prediction_context_t option * semantic_context_t option * lexer_action_executor_t option * config_t option
                                    [@yojson.name "ENTER LexerATNConfig.__init__"]
                                    [@located_yojson.name "ENTER LexerATNConfig.__init__"]
| LexerATNConfig_EXIT_init of config_t
                                    [@yojson.name "EXIT LexerATNConfig.__init__"]
                                    [@located_yojson.name "EXIT LexerATNConfig.__init__"]

| ATNConfigSet_ENTER_init of int * bool
                                    [@yojson.name "ENTER ATNConfigSet.__init__"]
                                    [@located_yojson.name "ENTER ATNConfigSet.__init__"]
| ATNConfigSet_EXIT_init of config_set_t
                                    [@yojson.name "EXIT ATNConfigSet.__init__"]
                                    [@located_yojson.name "EXIT ATNConfigSet.__init__"]
| OrderedATNConfigSet_ENTER_init
                                    [@yojson.name "ENTER OrderedATNConfigSet.__init__"]
                                    [@located_yojson.name "ENTER OrderedATNConfigSet.__init__"]
| OrderedATNConfigSet_EXIT_init of config_set_t
                                    [@yojson.name "EXIT OrderedATNConfigSet.__init__"]
                                    [@located_yojson.name "EXIT OrderedATNConfigSet.__init__"]


| ATNConfigSet_ENTER_add of config_set_t * config_t * merge_cache_t option
                                    [@yojson.name "ENTER ATNConfigSet.add"]
                                    [@located_yojson.name "ENTER ATNConfigSet.add"]
| ATNConfigSet_EXIT_add of config_set_t * bool
                                    [@yojson.name "EXIT ATNConfigSet.add"]
                                    [@located_yojson.name "EXIT ATNConfigSet.add"]

| ATNConfigSet_ENTER_getOrAdd of config_set_t * config_t[@yojson.name "ENTER ATNConfigSet.getOrAdd"]
                                  [@located_yojson.name "ENTER ATNConfigSet.getOrAdd"]
| ATNConfigSet_EXIT_getOrAdd of config_set_t * config_t[@yojson.name "EXIT ATNConfigSet.getOrAdd"]
                                  [@located_yojson.name "EXIT ATNConfigSet.getOrAdd"]

| ATNConfigSet_optimizeConfigs of config_set_t
                                    [@yojson.name "ATNConfigSet.optimizeConfigs"]
                                    [@located_yojson.name "ATNConfigSet.optimizeConfigs"]

| ATNConfigSet_ENTER_eq of config_set_t * config_set_t
                                    [@yojson.name "ENTER ATNConfigSet.__eq__"]
                                    [@located_yojson.name "ENTER ATNConfigSet.__eq__"]
| ATNConfigSet_EXIT_eq of bool
                                    [@yojson.name "EXIT ATNConfigSet.__eq__"]
                                    [@located_yojson.name "EXIT ATNConfigSet.__eq__"]
| ATNConfigSet_ENTER_set_DIOC of config_set_t
                                    [@yojson.name "ENTER ATNConfigSet.set_DIOC"]
                                    [@located_yojson.name "ENTER ATNConfigSet.set_DIOC"]
| ATNConfigSet_EXIT_set_DIOC of config_set_t
                                    [@yojson.name "EXIT ATNConfigSet.set_DIOC"]
                                    [@located_yojson.name "EXIT ATNConfigSet.set_DIOC"]

| ATNConfigSet_ENTER_set_UA of config_set_t * int
                                    [@yojson.name "ENTER ATNConfigSet.set_UA"]
                                    [@located_yojson.name "ENTER ATNConfigSet.set_UA"]
| ATNConfigSet_EXIT_set_UA of config_set_t
                                    [@yojson.name "EXIT ATNConfigSet.set_UA"]
                                    [@located_yojson.name "EXIT ATNConfigSet.set_UA"]

| ATNConfigSet_ENTER_set_CA of config_set_t * int list option
                                    [@yojson.name "ENTER ATNConfigSet.set_CA"]
                                    [@located_yojson.name "ENTER ATNConfigSet.set_CA"]
| ATNConfigSet_EXIT_set_CA of config_set_t
                                    [@yojson.name "EXIT ATNConfigSet.set_CA"]
                                    [@located_yojson.name "EXIT ATNConfigSet.set_CA"]

| InputStream_ENTER_init of int * string
                                    [@yojson.name "ENTER InputStream.__init__"]
                                    [@located_yojson.name "ENTER InputStream.__init__"]
| InputStream_EXIT_init of input_stream_t
                                    [@yojson.name "EXIT InputStream.__init__"]
                                    [@located_yojson.name "EXIT InputStream.__init__"]

| InputStream_ENTER_reset of input_stream_t
                                    [@yojson.name "ENTER InputStream.reset"]
                                    [@located_yojson.name "ENTER InputStream.reset"]
| InputStream_EXIT_reset of input_stream_t
                                    [@yojson.name "EXIT InputStream.reset"]
                                    [@located_yojson.name "EXIT InputStream.reset"]

| InputStream_ENTER_consume of input_stream_t
                                    [@yojson.name "ENTER InputStream.consume"]
                                    [@located_yojson.name "ENTER InputStream.consume"]
| InputStream_EXIT_consume of input_stream_t
                                    [@yojson.name "EXIT InputStream.consume"]
                                    [@located_yojson.name "EXIT InputStream.consume"]

| InputStream_ENTER_LA of input_stream_t * int
                                    [@yojson.name "ENTER InputStream.LA"]
                                    [@located_yojson.name "ENTER InputStream.LA"]
| InputStream_EXIT_LA of input_stream_t * int
                                    [@yojson.name "EXIT InputStream.LA"]
                                    [@located_yojson.name "EXIT InputStream.LA"]

| InputStream_ENTER_seek of input_stream_t * int
                                    [@yojson.name "ENTER InputStream.seek"]
                                    [@located_yojson.name "ENTER InputStream.seek"]
| InputStream_EXIT_seek of input_stream_t
                                    [@yojson.name "EXIT InputStream.seek"]
                                    [@located_yojson.name "EXIT InputStream.seek"]


| InputStream_ENTER_getText of input_stream_t * int * int
                                    [@yojson.name "ENTER InputStream.getText"]
                                    [@located_yojson.name "ENTER InputStream.getText"]
| InputStream_EXIT_getText of input_stream_t * string
                                    [@yojson.name "EXIT InputStream.getText"]
                                    [@located_yojson.name "EXIT InputStream.getText"]

[@@deriving yojson,located_yojson, show]
