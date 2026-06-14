(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.utils,pa_ppx.deriving_plugins.std *)

type state_id = STID of int
  [@@deriving show]

type 'a block_start_node_t =
  {
    mutable decision : int
  ; mutable nonGreedy : bool
  ; mutable endState : state_id option
  ; extra : 'a
  }

type plus_block_start_node_t =
  { mutable loopBackState : state_id option }

type node_t =
  BasicState
| RuleStartState
| BasicBlockStartState of unit block_start_node_t
| PlusBlockStartState of plus_block_start_node_t block_start_node_t
| StarBlockStartState of unit block_start_node_t
| TokensStartState
| RuleStopState
| BlockEndState of {
      mutable startState : state_id option
    }
| StarLoopbackState
| StarLoopEntryState
| PlusLoopbackState
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
