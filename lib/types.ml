(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.utils,pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.located_yojson,pa_ppx.deriving_plugins.yojson,pa_ppx.deriving_plugins.located_yojson,pa_ppx.import *)

type state_id = STID of int
  [@@deriving show]

type atn_state_type_t =
       INVALID_TYPE
     | BASIC
     | RULE_START
     | BLOCK_START
     | PLUS_BLOCK_START
     | STAR_BLOCK_START
     | TOKEN_START
     | RULE_STOP
     | BLOCK_END
     | STAR_LOOP_BACK
     | STAR_LOOP_ENTRY
     | PLUS_LOOP_BACK
     | LOOP_END
[@@deriving yojson,located_yojson, show { with_path = false }]

type node_t =
  BasicState
| RuleStartState of {
    mutable stopState : state_id option
  ; mutable isPrecedenceRule : bool
  }
| BasicBlockStartState of {
    mutable decision : int
  ; mutable nonGreedy : bool
  ; mutable endState : state_id option
  }
| PlusBlockStartState of {
    mutable decision : int
  ; mutable nonGreedy : bool
  ; mutable endState : state_id option
  ; mutable loopBackState : state_id option
  }
| StarBlockStartState of {
    mutable decision : int
  ; mutable nonGreedy : bool
  ; mutable endState : state_id option
  }
| TokensStartState of {
    mutable decision : int
  ; mutable nonGreedy : bool
  }
| RuleStopState
| BlockEndState of {
      mutable startState : state_id option
    }
| StarLoopbackState
| StarLoopEntryState of {
    mutable decision : int
  ; mutable nonGreedy : bool
  ; mutable loopBackState : state_id option
  ; mutable isPrecedenceDecision : bool option
  }
| PlusLoopbackState of {
    mutable decision : int
  ; mutable nonGreedy : bool
  }
| LoopEndState of {
    mutable loopBackState : state_id option
  }
and state_t = {
      stateNumber : state_id
    ; stateType : atn_state_type_t
    ; mutable node : node_t
    ; mutable ruleIndex : int
    ; mutable epsilonOnlyTransitions : bool
    ; mutable transitions : edge_t list
    }
and edge_serialization_type_t =
  EPSILON
  | RANGE
  | RULE
  | PREDICATE
  | ATOM
  | ACTION
  | SET
  | NOT_SET
  | WILDCARD
  | PRECEDENCE
and edge_t =
  EpsilonTransition of {
    _target : state_id
    ; label : IntervalSet.t option 
    ; outermostPrecedenceReturn : int
    ; serializationType : edge_serialization_type_t
  }
| RangeTransition of {
    _target : state_id
  ; label : IntervalSet.t
  ; start : int
  ; stop : int
  ; serializationType : edge_serialization_type_t
  }
| RuleTransition of {
    label : IntervalSet.t option 
  ; ruleStart : state_id
  ; ruleIndex : int
  ; precedence : int
  ; followState : state_id
  ; serializationType : edge_serialization_type_t
  }
| PredicateTransition of {
    _target : state_id
  ; ruleIndex : int
  ; predIndex : int
  ; isCtxDependent : bool
  ; label : IntervalSet.t option
  ; serializationType : edge_serialization_type_t
  }
| AtomTransition of {
    _target : state_id
  ; label_ : int
  ; label : IntervalSet.t
  ; serializationType : edge_serialization_type_t
  }
| ActionTransition of {
    _target : state_id
  ; ruleIndex : int
  ; actionIndex : int
  ; isCtxDependent : bool
  ; label : IntervalSet.t option
  ; serializationType : edge_serialization_type_t
  }
| SetTransition of {
    _target : state_id
  ; set : IntervalSet.t
  ; serializationType : edge_serialization_type_t
  }
| NotSetTransition of {
    _target : state_id
  ; set : IntervalSet.t
  ; serializationType : edge_serialization_type_t
  }
| WildcardTransition of {
    _target : state_id
  ; serializationType : edge_serialization_type_t
  ; label : IntervalSet.t option
  }
| PrecedencePredicateTransition of {
    _target : state_id
  ; precedence : int
  ; label : IntervalSet.t option
  ; serializationType : edge_serialization_type_t
  }

type lexer_action_t =
  LexerChannelAction of {
      actionType : int ;
      isPositionDependent : bool ;
      mutable channel : int
    }

| LexerCustomAction of {
      actionType : int ;
      isPositionDependent : bool ;
      mutable ruleIndex : int ;
      mutable actionIndex : int
    }

| LexerIndexedCustomAction of {
    actionType : int ;
    isPositionDependent : bool ;
    action : lexer_action_t ;
    offset : int
  }

| LexerModeAction of {
      actionType : int ;
      isPositionDependent : bool ;
      mutable mode : int
    }

| LexerMoreAction of {
      actionType : int ;
      isPositionDependent : bool ;
    }

| LexerPopModeAction of {
      actionType : int ;
      isPositionDependent : bool ;
    }

| LexerPushModeAction of {
      actionType : int ;
      isPositionDependent : bool ;
      mutable mode : int
    }

| LexerSkipAction of {
      actionType : int ;
      isPositionDependent : bool ;
    }

| LexerTypeAction of {
    actionType : int ;
    isPositionDependent : bool ;
    mutable type_ : int [@yojson.key "type"] [@located_yojson.key "type"]
  }

