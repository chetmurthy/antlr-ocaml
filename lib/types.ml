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
| BasicBlockStartState of state_id
| PlusBlockStartState of state_id
| StarBlockStartState of state_id
| TokensStartState
| RuleStopState
| BlockEndState
| StarLoopbackState
| StarLoopEntryState
| PlusLoopbackState
| LoopEndState of state_id
and state_t = {
      num : state_id
    ; mutable node : node_t
    ; mutable ruleIndex : int
    ; mutable nonGreedy : bool
    ; mutable isPrecedenceRule : bool
    ; mutable stopState : state_id option
    ; mutable transitions : edge_t list
    ; mutable epsilonOnlyTransitions : bool
    }
and edge_t =
  EpsilonTransition of EpsilonTransition.t
| RangeTransition of RangeTransition.t
| RuleTransition of RuleTransition.t
| PredicateTransition of PredicateTransition.t
| AtomTransition of AtomTransition.t
| ActionTransition of ActionTransition.t
| SetTransition of SetTransition.t
| NotSetTransition of SetTransition.t
| WildcardTransition of state_id
| PrecedencePredicateTransition of PrecedencePredicateTransition.t

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

let mkEpsilonTransition ?(outermostPrecedenceReturn= -1) ~target () =
  EpsilonTransition (EpsilonTransition.mk ~target ~outermostPrecedenceReturn)

let mkRangeTransition ~target ~start ~stop () =
  RangeTransition (RangeTransition.mk ~target ~start ~stop)

let mkRuleTransition ~ruleStart ~ruleIndex ~precedence ~followState () =
  RuleTransition (RuleTransition.mk ~ruleStart ~ruleIndex ~precedence ~followState)

let mkPredicateTransition ~target ~ruleIndex ~predIndex ~isCtxDependent () =
  PredicateTransition (PredicateTransition.mk ~target ~ruleIndex ~predIndex ~isCtxDependent)

let mkAtomTransition ~target ~label () =
  AtomTransition (AtomTransition.mk ~target ~label)

let mkActionTransition ~target ~ruleIndex ~actionIndex ~isCtxDependent () =
  ActionTransition (ActionTransition.mk ~target ~ruleIndex ~actionIndex ~isCtxDependent)

let mkSetTransition ~target ?set () =
  let set = match set with
      None -> IntervalSet.(() |> mk |> addOne Token._INVALID_TYPE)
    | Some set -> set
  in
  SetTransition (SetTransition.mk ~target ~set)

let mkNotSetTransition ~target ?set () =
  let set = match set with
      None -> IntervalSet.(() |> mk |> addOne Token._INVALID_TYPE)
    | Some set -> set
  in
  NotSetTransition (SetTransition.mk ~target ~set)

let mkWildcardTransition ~target () =
  WildcardTransition target

let mkPrecedencePredicateTransition ~target ~precedence () =
  PrecedencePredicateTransition (PrecedencePredicateTransition.mk ~target  ~precedence)
