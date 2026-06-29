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

type config_t = {
    state : deser_state_id
  ; alt : int
  ; context : prediction_context_t option
  ; semanticContext : semantic_context_t
  ; reachesIntoOuterContext : int
  ; precedenceFilterSuppressed : bool
  }
and config_set_t = {
    fullCtx : bool
  ; configs : config_t list
  ; readonly : bool
  ; conflictingAlts : int list option
  ; hasSemanticContext : bool
  ; dipsIntoOuterContext : bool
  ; id : int
  }
and prediction_context_t =
  PC_SINGLETON of { cachedHashCode : int64
                  ; parentCtx : prediction_context_t option
                  ; returnState : int
                  }[@yojson.name "SingletonPredictionContext"]
                    [@located_yojson.name "SingletonPredictionContext"]
| PC_EMPTY of { cachedHashCode : int64
              }
| PC_ARRAY of { cachedHashCode : int64
              ; parents : prediction_context_t option array
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
    id : int
  ; atnStartState : deser_state_id
  ; decision : int
  ; _states : dfa_state_t strmap
  ; s0 : dfa_state_t option
  }

and dfa_state_t = {
    stateNumber : int
  ; configs : config_set_t
  ; edges: int option array option
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
  ; hashCode : int64
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
      column : int
(* don't demarshal this, b/c it's big and never changes
    ; atn : Atn.t
 *)
    ; decisionToDFA : dfa_t array
    ; line : int
    ; mode : int
    ; prevAccept : sim_state_t
    ; sharedContextCache : prediction_context_cache_t
    ; startIndex : int
    }

and prediction_context_cache_t =
  PredictionContextCache of {
      cache : string strmap
    }

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
[@@deriving yojson,located_yojson, show]

type json_log_t =
  AtnConfigSet_getOrAdd of int * config_t[@yojson.name "AtnConfigSet.getOrAdd"]
                    [@located_yojson.name "AtnConfigSet.getOrAdd"]
| AtnConfigSet_optimizeConfigs of config_set_t
                                    [@yojson.name "AtnConfigSet.optimizeConfigs"]
                                    [@located_yojson.name "AtnConfigSet.optimizeConfigs"]
| AtnConfigSet_init of int * config_set_t
                                    [@yojson.name "AtnConfigSet.__init__"]
                                    [@located_yojson.name "AtnConfigSet.__init__"]
| AtnConfig_eq of config_t * config_t * bool
                                    [@yojson.name "AtnConfig.__eq__"]
                                    [@located_yojson.name "AtnConfig.__eq__"]
| AtnConfig_equalsForConfigSet of config_t * config_t * bool
                                    [@yojson.name "AtnConfig.equalsForConfigSet"]
                                    [@located_yojson.name "AtnConfig.equalsForConfigSet"]
| DFA_init of int * dfa_t
                      [@yojson.name "DFA.__init__"]
                      [@located_yojson.name "DFA.__init__"]
| ENTER_DFA_states_get of int * dfa_state_t * string option
                      [@yojson.name "ENTER DFA.states_get"]
                      [@located_yojson.name "ENTER DFA.states_get"]
| EXIT_DFA_states_get of int * dfa_state_t option
                      [@yojson.name "EXIT DFA.states_get"]
                      [@located_yojson.name "EXIT DFA.states_get"]
| EXIT_DFA_states_len of int * int
                      [@yojson.name "EXIT DFA.states_len"]
                      [@located_yojson.name "EXIT DFA.states_len"]
| ENTER_DFA_states_add of int * dfa_state_t
                      [@yojson.name "ENTER DFA.states_add"]
                      [@located_yojson.name "ENTER DFA.states_add"]
| EXIT_DFA_states_add of int * dfa_t
                      [@yojson.name "EXIT DFA.states_add"]
                      [@located_yojson.name "EXIT DFA.states_add"]
| LexerATNSimulator_add_state of int * dfa_state_t
                      [@yojson.name "LexerATNSimulator.__add_state__"]
                      [@located_yojson.name "LexerATNSimulator.__add_state__"]
| LexerATNSimulator_addDFAEdge of int * int * int option
                      [@yojson.name "END LexerATNSimulator.addDFAEdge"]
                      [@located_yojson.name "END LexerATNSimulator.addDFAEdge"]
| LexerATNSimulator_ENTER_init of Atn.t * dfa_t array * prediction_context_cache_t
                      [@yojson.name "ENTER LexerATNSimulator.__init__"]
                      [@located_yojson.name "ENTER LexerATNSimulator.__init__"]
| LexerATNSimulator_EXIT_init of lexer_atn_simulator_t
                      [@yojson.name "EXIT LexerATNSimulator.__init__"]
                      [@located_yojson.name "EXIT LexerATNSimulator.__init__"]
| LexerATNSimulator_ENTER_match of lexer_atn_simulator_t * int
                      [@yojson.name "ENTER LexerATNSimulator.match"]
                      [@located_yojson.name "ENTER LexerATNSimulator.match"]
| LexerATNSimulator_EXIT_match of lexer_atn_simulator_t * int
                      [@yojson.name "EXIT LexerATNSimulator.match"]
                      [@located_yojson.name "EXIT LexerATNSimulator.match"]
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
| Lexer_more of lexer_t
                      [@yojson.name "Lexer.more"]
                      [@located_yojson.name "Lexer.more"]

[@@deriving yojson,located_yojson, show]
