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
