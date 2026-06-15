(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.utils,pa_ppx.deriving_plugins.std *)

type state_id = STID of int
  [@@deriving show]

type node_t =
  BasicState
| RuleStartState
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
| TokensStartState
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
| LoopEndState of state_id
and state_t = {
      stateNumber : state_id
    ; mutable node : node_t
    ; mutable ruleIndex : int
    ; mutable epsilonOnlyTransitions : bool
    ; mutable transitions : edge_t list
    ; mutable nonGreedy : bool
    ; mutable isPrecedenceRule : bool
    ; mutable stopState : state_id option
    }
and edge_t =
  EpsilonTransition of {
    _target : state_id
  ; outermostPrecedenceReturn : int
  }
| RangeTransition of {
    _target : state_id
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
  ; label : int
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

let isEpsilon = function
    (EpsilonTransition _
     | RuleTransition _
    | PredicateTransition _
    | ActionTransition _
    | PrecedencePredicateTransition _) -> true

  | (RangeTransition _
     | AtomTransition _
    | SetTransition _
    | NotSetTransition _
    | WildcardTransition _) -> false

type lexer_action_t =
  LexerChannelAction of {
      mutable isPositionDependent : bool ;
      mutable channel : int
    }

| LexerCustomAction of {
      mutable isPositionDependent : bool ;
      mutable ruleIndex : int ;
      mutable actionIndex : int
    }

| LexerModeAction of {
      mutable isPositionDependent : bool ;
      mutable mode : int
    }

| LexerMoreAction of {
      mutable isPositionDependent : bool ;
    }

| LexerPopModeAction of {
      mutable isPositionDependent : bool ;
    }

| LexerPushModeAction of {
      mutable isPositionDependent : bool ;
      mutable mode : int
    }

| LexerSkipAction of {
      mutable isPositionDependent : bool ;
    }

| LexerTypeAction of {
    mutable isPositionDependent : bool ;
    mutable type_ : int
  }

