(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.utils,pa_ppx.deriving_plugins.std *)

module EpsilonTransition = struct
type t =
  {
    target : int
  ; outermostPrecedenceReturn : int
  }
  [@@deriving show]

let mk ~target ~outermostPrecedenceReturn =
  { target ; outermostPrecedenceReturn }
let target t = t.target
end

module RangeTransition = struct
type t =
  {
    target : int
  ; start : int
  ; stop : int
  }
  [@@deriving show]

let mk ~target ~start ~stop =
  { target ; start ; stop }
let target t = t.target
end

module RuleTransition = struct
type t =
  {
    ruleStart : int
  ; ruleIndex : int
  ; precedence : int
  ; followState : int
  }
  [@@deriving show]

let mk ~ruleStart ~ruleIndex ~precedence ~followState =
  { ruleStart ; ruleIndex ; precedence ; followState }
let target t = t.ruleStart
end

module PredicateTransition = struct
  type t =
    {
      target : int
    ; ruleIndex : int
    ; predIndex : int
    ; isCtxDependent : bool
    }
  [@@deriving show]

  let mk ~target ~ruleIndex ~predIndex ~isCtxDependent =
    { target ; ruleIndex ; predIndex ; isCtxDependent }
  let target t = t.target
end

module ActionTransition = struct
type t =
  {
    target : int
  ; ruleIndex : int
  ; actionIndex : int
  ; isCtxDependent : bool
  }
  [@@deriving show]

let mk ~target ~ruleIndex ~actionIndex ~isCtxDependent =
  { target ; ruleIndex ; actionIndex ; isCtxDependent }
let target t = t.target
end

module SetTransition = struct
type t =
  {
    target : int
  ; set : IntervalSet.t
  }
  [@@deriving show]

let mk ~target ~set =
  { target ; set }
let target t = t.target
end

module PrecedencePredicateTransition = struct
type t =
  {
    target : int
  ; precedence : int
  }
  [@@deriving show]

let mk ~target ~precedence =
  { target ; precedence }
let target t = t.target
end

module AtomTransition = struct
type t =
  {
    target : int
  ; label : int
  }
  [@@deriving show]

let mk ~target ~label =
  { target ; label }
let target t = t.target
end

type node_t =
  BasicState
| RuleStartState
| BasicBlockStartState of int
| PlusBlockStartState of int
| StarBlockStartState of int
| TokensStartState
| RuleStopState
| BlockEndState
| StarLoopbackState
| StarLoopEntryState
| PlusLoopbackState
| LoopEndState of int
and state_t = {
      num : int
    ; mutable node : (node_t * int) option
    ; mutable nonGreedy : bool
    ; mutable isPrecedenceRule : bool
    ; mutable stopState : int option
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
| WildcardTransition of int
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
  let set = match set with None -> IntervalSet.(() |> mk |> addOne Token._INVALID_TYPE) in
  SetTransition (SetTransition.mk ~target ~set)

let mkNotSetTransition ~target ?set () =
  let set = match set with None -> IntervalSet.(() |> mk |> addOne Token._INVALID_TYPE) in
  NotSetTransition (SetTransition.mk ~target ~set)

let mkWildcardTransition ~target () =
  WildcardTransition target

let mkPrecedencePredicateTransition ~target ~precedence () =
  PrecedencePredicateTransition (PrecedencePredicateTransition.mk ~target  ~precedence)
