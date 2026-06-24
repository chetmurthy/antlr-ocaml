(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.utils,pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.yojson,pa_ppx.deriving_plugins.located_yojson,pa_ppx.import *)

open Atn

open Rresult.R
let state_id_to_yojson (STID n) = [%to_yojson: int] n
let state_id_of_yojson j =
  ([%of_yojson: int] j) >>= (fun n -> Result.Ok (STID n))
let state_id_to_located_yojson (STID n) = [%to_located_yojson: int] n
let state_id_of_located_yojson j =
  ([%of_located_yojson: int] j) >>= (fun n -> Result.Ok (STID n))

type config_t = {
    state : state_id[@yojson.to_yojson state_id_to_yojson]
              [@yojson.of_yojson state_id_of_yojson]
              [@located_yojson.to_located_yojson state_id_to_located_yojson]
              [@located_yojson.of_located_yojson state_id_of_located_yojson]
  ; alt : int
  ; context : prediction_context_t
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
              ; parents : prediction_context_t list
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
[@@deriving yojson,located_yojson, show]
