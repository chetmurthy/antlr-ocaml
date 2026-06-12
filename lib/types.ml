(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.utils,pa_ppx.deriving_plugins.std *)

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
    }

module RuleTransition = struct
type t =
  {
    ruleStart : int
  ; ruleIndex : int
  ; precedence : int
  }
let mk ~ruleStart ~ruleIndex ~precedence =
  { ruleStart ; ruleIndex ; precedence }
end

module PredicateTransition = struct
  type t =
    {
      ruleIndex : int
    ; predIndex : int
    ; isCtxDependent : int
    }
end

module ActionTransition = struct
type t =
  {
    ruleIndex : int
  ; actionIndex : int
  ; isCtxDependent : bool
  }
end

type raw_edge_t =
  EpsilonTransition of int
| RangeTransition of Range.t
| RuleTransition of RuleTransition.t
| PredicateTransition of PredicateTransition.t
| AtomTransition of int
| ActionTransition of ActionTransition.t
| SetTransition of IntervalSet.t option
| NotSetTransition of IntervalSet.t option
| WildCardTransition
| PrecedencePredicateTransition of int

type edge_t = { target : int ; it : raw_edge_t }
