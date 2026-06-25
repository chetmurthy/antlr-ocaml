(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.utils,pa_ppx.deriving_plugins.std *)

type state_id = STID of int
  [@@deriving show]

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
    ; mutable node : node_t
    ; mutable ruleIndex : int
    ; mutable epsilonOnlyTransitions : bool
    ; mutable transitions : edge_t list
    }
and edge_t =
  EpsilonTransition of {
    _target : state_id
  ; outermostPrecedenceReturn : int
  }
| RangeTransition of {
    _target : state_id
  ; label : IntervalSet.t
  ; start : int
  ; stop : int
  }
| RuleTransition of {
    ruleStart : state_id
  ; ruleIndex : int
  ; precedence : int
  ; followState : state_id
  }
| PredicateTransition of {
      _target : state_id
    ; ruleIndex : int
    ; predIndex : int
    ; isCtxDependent : bool
    }
| AtomTransition of {
    _target : state_id
  ; label_ : int
  ; label : IntervalSet.t
  }
| ActionTransition of {
    _target : state_id
  ; ruleIndex : int
  ; actionIndex : int
  ; isCtxDependent : bool
  }
| SetTransition of {
    _target : state_id
  ; set : IntervalSet.t
  }
| NotSetTransition of {
    _target : state_id
  ; set : IntervalSet.t
  }
| WildcardTransition of state_id
| PrecedencePredicateTransition of {
    _target : state_id
  ; precedence : int
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

