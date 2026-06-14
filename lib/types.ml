(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.utils,pa_ppx.deriving_plugins.std *)

type state_id = STID of int
  [@@deriving show]

module EpsilonTransition = struct
type t =
  {
    _target : state_id
  ; outermostPrecedenceReturn : int
  }
  [@@deriving show]

let mk ~target ~outermostPrecedenceReturn =
  { _target=target ; outermostPrecedenceReturn }
let target t = t._target
end

module RangeTransition = struct
type t =
  {
    _target : state_id
  ; start : int
  ; stop : int
  }
  [@@deriving show]

let mk ~target ~start ~stop =
  { _target=target ; start ; stop }
let target t = t._target
end

module RuleTransition = struct
type t =
  {
    ruleStart : state_id
  ; ruleIndex : int
  ; precedence : int
  ; followState : state_id
  }
  [@@deriving show]

let mk ~ruleStart ~ruleIndex ~precedence ~followState =
  { ruleStart ; ruleIndex ; precedence ; followState }
let target t = t.ruleStart
end

module PredicateTransition = struct
  type t =
    {
      _target : state_id
    ; ruleIndex : int
    ; predIndex : int
    ; isCtxDependent : bool
    }
  [@@deriving show]

  let mk ~target ~ruleIndex ~predIndex ~isCtxDependent =
    { _target=target ; ruleIndex ; predIndex ; isCtxDependent }
  let target t = t._target
end

module ActionTransition = struct
type t =
  {
    _target : state_id
  ; ruleIndex : int
  ; actionIndex : int
  ; isCtxDependent : bool
  }
  [@@deriving show]

let mk ~target ~ruleIndex ~actionIndex ~isCtxDependent =
  { _target=target ; ruleIndex ; actionIndex ; isCtxDependent }
let target t = t._target
end

module SetTransition = struct
type t =
  {
    _target : state_id
  ; set : IntervalSet.t
  }
  [@@deriving show]

let mk ~target ~set =
  { _target=target ; set }
let target t = t._target
end

module PrecedencePredicateTransition = struct
type t =
  {
    _target : state_id
  ; precedence : int
  }
  [@@deriving show]

let mk ~target ~precedence =
  { _target=target ; precedence }
let target t = t._target
end

module AtomTransition = struct
type t =
  {
    _target : state_id
  ; label : int
  }
  [@@deriving show]

let mk ~target ~label =
  { _target=target ; label }
let target t = t._target
end

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
| StarBlockStartState of state_id
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
