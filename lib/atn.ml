(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.utils,pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.located_yojson,pa_ppx.deriving_plugins.yojson,pa_ppx.deriving_plugins.located_yojson,pa_ppx.import *)

open Pa_ppx_base
open Ppxutil
open Pa_ppx_utils.Std
open Interp
open Util

let debug = ref false

let readInt = parser [< 'n >] -> n

let readBool = parser [< 'n >] -> n<>0

let _INVALID_ALT_NUMBER = 0
let _SERIALIZED_VERSION = 4

type state_id = [%import: Types.state_id]
[@@deriving yojson,located_yojson, show]

let state_id_to_yojson (STID n) = `Int n
let state_id_of_yojson = function
    `Int n -> Result.Ok (STID n)
  | _ -> Result.Error "state_id"

let state_id_to_located_yojson (STID n) = (Ploc.dummy, `Int n)
let state_id_of_located_yojson = function
    (_, `Int n) -> Result.Ok (STID n)
  | (loc, _) -> Result.Error (loc, "state_id")

let dump_state_id pps (STID n) = Fmt.(pf pps "%d" n)

let dump_state_id_opt pps = function
    None -> Fmt.(pf pps "None")
  | Some stid -> Fmt.(pf pps "%a" dump_state_id stid)

let dump_pybool pps b =
  Fmt.(pf pps "%s" (if b then "True" else "False"))

let dump_bool_opt pps = function
    None -> Fmt.(pf pps "None")
  | Some b -> Fmt.(pf pps "%a" dump_pybool b)

module Node = struct
type t = [%import: Types.node_t]
[@@deriving yojson,located_yojson, show]


let dump pps = function
    BasicState -> ()
| RuleStartState { stopState ; isPrecedenceRule } ->
   Fmt.(pf pps {|  stopState: %a@.|} dump_state_id_opt stopState)
  ; Fmt.(pf pps {|  isPrecedenceRule: %a@.|} dump_pybool isPrecedenceRule)

| BasicBlockStartState { decision ; nonGreedy ; endState } ->
   Fmt.(pf pps {|  decision: %d@.|} decision)
  ; Fmt.(pf pps {|  nonGreedy: %a@.|} dump_pybool nonGreedy)
  ; Fmt.(pf pps {|  endState: %a@.|} dump_state_id_opt endState)

| PlusBlockStartState { decision ; nonGreedy ; endState ; loopBackState } ->
   Fmt.(pf pps {|  decision: %d@.|} decision)
  ; Fmt.(pf pps {|  nonGreedy: %a@.|} dump_pybool nonGreedy)
  ; Fmt.(pf pps {|  endState: %a@.|} dump_state_id_opt endState)
  ; Fmt.(pf pps {|  loopBackState: %a@.|} dump_state_id_opt loopBackState)
   
| StarBlockStartState { decision ; nonGreedy ; endState } ->
   Fmt.(pf pps {|  decision: %d@.|} decision)
  ; Fmt.(pf pps {|  nonGreedy: %a@.|} dump_pybool nonGreedy)
  ; Fmt.(pf pps {|  endState: %a@.|} dump_state_id_opt endState)

| TokensStartState { decision ; nonGreedy } ->
   Fmt.(pf pps {|  decision: %d@.|} decision)
  ; Fmt.(pf pps {|  nonGreedy: %a@.|} dump_pybool nonGreedy)

| RuleStopState -> ()
| BlockEndState { startState } ->
   Fmt.(pf pps {|  startState: %a@.|} dump_state_id_opt startState)

| StarLoopbackState -> ()
| StarLoopEntryState { decision ; nonGreedy ; loopBackState ; isPrecedenceDecision } ->
   Fmt.(pf pps {|  decision: %d@.|} decision)
  ; Fmt.(pf pps {|  nonGreedy: %a@.|} dump_pybool nonGreedy)
  ; Fmt.(pf pps {|  loopBackState: %a@.|} dump_state_id_opt loopBackState)
  ; Fmt.(pf pps {|  isPrecedenceDecision: %a@.|} dump_bool_opt isPrecedenceDecision)

| PlusLoopbackState { decision ; nonGreedy } ->
   Fmt.(pf pps {|  decision: %d@.|} decision)
  ; Fmt.(pf pps {|  nonGreedy: %a@.|} dump_pybool nonGreedy)

| LoopEndState { loopBackState } ->
   Fmt.(pf pps {|  loopBackState: %a@.|} dump_state_id_opt loopBackState)

let deser_state_type bp = function
  0 -> Types.INVALID_TYPE
| 1 -> BASIC
| 2 -> RULE_START
| 3 -> BLOCK_START
| 4 -> PLUS_BLOCK_START
| 5 -> STAR_BLOCK_START
| 6 -> TOKEN_START
| 7 -> RULE_STOP
| 8 -> BLOCK_END
| 9 -> STAR_LOOP_BACK
| 10 -> STAR_LOOP_ENTRY
| 11 -> PLUS_LOOP_BACK
| 12 -> LOOP_END
| n ->
   Fmt.(failwithf "pos %d: deser_state_type with invalid arg %d" bp n)


let serialization_name =
  function
  BasicState -> Types.BASIC
| RuleStartState _ -> RULE_START
| BasicBlockStartState _ -> BLOCK_START
| PlusBlockStartState _ -> PLUS_BLOCK_START
| StarBlockStartState _ -> STAR_BLOCK_START
| TokensStartState _ -> TOKEN_START
| RuleStopState -> RULE_STOP
| BlockEndState _ -> BLOCK_END
| StarLoopbackState -> STAR_LOOP_BACK
| StarLoopEntryState _ -> STAR_LOOP_ENTRY
| PlusLoopbackState _ -> PLUS_LOOP_BACK
| LoopEndState _ -> LOOP_END
end

module Edge = struct
  type t = [%import: Types.edge_t]
  and edge_serialization_type_t = [%import: Types.edge_serialization_type_t]
[@@deriving yojson,located_yojson, show]

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

let _matches e symbol minVocabSymbol maxVocabSymbol =
  match e with
    EpsilonTransition _ -> false
  | RangeTransition t -> t.start <= symbol && symbol <= t.stop
  | RuleTransition _ -> false
  | PredicateTransition _ -> false
  | AtomTransition t -> t.label_ = symbol
  | ActionTransition _ -> false
  | SetTransition t -> IntervalSet.contains t.set symbol
  | NotSetTransition t ->
     symbol >= minVocabSymbol
     && symbol <= maxVocabSymbol
     && not (IntervalSet.contains t.set symbol)

  | WildcardTransition _ ->  symbol >= minVocabSymbol && symbol <= maxVocabSymbol
  | PrecedencePredicateTransition _ -> false

let matches e symbol minVocabSymbol maxVocabSymbol =
  Tracelog.write
    (Transition_ENTER_matches (e, symbol, minVocabSymbol, maxVocabSymbol)) ;
  let rv = _matches e symbol minVocabSymbol maxVocabSymbol in
  Tracelog.write
    (Transition_EXIT_matches rv) ;
  rv

let serialization_type e = match e with
    EpsilonTransition _ -> EPSILON
  | RangeTransition _ -> RANGE
  | RuleTransition _ -> RULE
  | PredicateTransition _ -> PREDICATE
  | AtomTransition _ -> ATOM
  | ActionTransition _ -> ACTION
  | SetTransition _ -> SET
  | NotSetTransition _ -> NOT_SET
  | WildcardTransition _ -> WILDCARD
  | PrecedencePredicateTransition _ -> PRECEDENCE

let serialization_type_string e = match e with
    EpsilonTransition _ -> "EPSILON"
  | RangeTransition _ -> "RANGE"
  | RuleTransition _ -> "RULE"
  | PredicateTransition _ -> "PREDICATE"
  | AtomTransition _ -> "ATOM"
  | ActionTransition _ -> "ACTION"
  | SetTransition _ -> "SET"
  | NotSetTransition _ -> "NOT_SET"
  | WildcardTransition _ -> "WILDCARD"
  | PrecedencePredicateTransition _ -> "PRECEDENCE"

let dump pps e = match e with
    EpsilonTransition { _target ; outermostPrecedenceReturn } ->
     ()
    ; Fmt.(pf pps {|    target: %a@.|} dump_state_id _target)
    ; Fmt.(pf pps {|    isEpsilon: %a@.|} dump_pybool (isEpsilon e))
    ; Fmt.(pf pps {|    label: None@.|})
    ; Fmt.(pf pps {|    serializationType: EPSILON@.|})
    ; Fmt.(pf pps {|    outermostPrecedenceReturn: %d@.|} outermostPrecedenceReturn)

| RangeTransition { _target ; label ; start ; stop } ->
   ()
  ; Fmt.(pf pps {|    target: %a@.|} dump_state_id _target)
  ; Fmt.(pf pps {|    isEpsilon: %a@.|} dump_pybool (isEpsilon e))
  ; Fmt.(pf pps {|    label: %a@.|} IntervalSet.dump label)
  ; Fmt.(pf pps {|    serializationType: RANGE@.|})
  ; Fmt.(pf pps {|    start: %d@.|} start)
  ; Fmt.(pf pps {|    stop: %d@.|} stop)


| RuleTransition { ruleStart ; ruleIndex ; precedence ; followState } ->
     ()
    ; Fmt.(pf pps {|    target: %a@.|} dump_state_id ruleStart)
    ; Fmt.(pf pps {|    isEpsilon: %a@.|} dump_pybool (isEpsilon e))
    ; Fmt.(pf pps {|    label: None@.|})
    ; Fmt.(pf pps {|    serializationType: RULE@.|})
    ; Fmt.(pf pps {|    ruleIndex: %d@.|} ruleIndex)
    ; Fmt.(pf pps {|    precedence: %d@.|} precedence)
    ; Fmt.(pf pps {|    followState: %a@.|} dump_state_id followState)

| PredicateTransition { _target ; ruleIndex ; predIndex ; isCtxDependent } ->
     ()
    ; Fmt.(pf pps {|    target: %a@.|} dump_state_id _target)
    ; Fmt.(pf pps {|    isEpsilon: %a@.|} dump_pybool (isEpsilon e))
    ; Fmt.(pf pps {|    label: None@.|})
    ; Fmt.(pf pps {|    serializationType: PREDICATE@.|})
    ; Fmt.(pf pps {|    ruleIndex: %d@.|} ruleIndex)
    ; Fmt.(pf pps {|    predIndex: %d@.|} predIndex)
  ; Fmt.(pf pps {|    isCtxDependent: %a@.|} dump_pybool isCtxDependent)


| AtomTransition { _target ; label ; label_ } ->
   ()
  ; Fmt.(pf pps {|    target: %a@.|} dump_state_id _target)
  ; Fmt.(pf pps {|    isEpsilon: %a@.|} dump_pybool (isEpsilon e))
  ; Fmt.(pf pps {|    label: %a@.|} IntervalSet.dump label)
  ; Fmt.(pf pps {|    serializationType: ATOM@.|})
  ; Fmt.(pf pps {|    label_: %d@.|} label_)
   
| ActionTransition { _target ; ruleIndex ; actionIndex ; isCtxDependent } ->
   ()
  ; Fmt.(pf pps {|    target: %a@.|} dump_state_id _target)
  ; Fmt.(pf pps {|    isEpsilon: %a@.|} dump_pybool (isEpsilon e))
  ; Fmt.(pf pps {|    label: None@.|})
  ; Fmt.(pf pps {|    serializationType: ACTION@.|})
  ; Fmt.(pf pps {|    ruleIndex: %d@.|} ruleIndex)
  ; Fmt.(pf pps {|    actionIndex: %d@.|} actionIndex)
  ; Fmt.(pf pps {|    isCtxDependent: %a@.|} dump_pybool isCtxDependent)

| SetTransition { _target ; set } ->
   ()
  ; Fmt.(pf pps {|    target: %a@.|} dump_state_id _target)
  ; Fmt.(pf pps {|    isEpsilon: %a@.|} dump_pybool (isEpsilon e))
  ; Fmt.(pf pps {|    label: %a@.|} IntervalSet.dump set)
  ; Fmt.(pf pps {|    serializationType: SET@.|})

| NotSetTransition { _target ; set } ->
   ()
  ; Fmt.(pf pps {|    target: %a@.|} dump_state_id _target)
  ; Fmt.(pf pps {|    isEpsilon: %a@.|} dump_pybool (isEpsilon e))
  ; Fmt.(pf pps {|    label: %a@.|} IntervalSet.dump set)
  ; Fmt.(pf pps {|    serializationType: NOT_SET@.|})

| WildcardTransition { _target ; label } ->
   ()
  ; Fmt.(pf pps {|    target: %a@.|} dump_state_id _target)
  ; Fmt.(pf pps {|    isEpsilon: %a@.|} dump_pybool (isEpsilon e))
  ; Fmt.(pf pps {|    label: None@.|})
  ; Fmt.(pf pps {|    serializationType: WILDCARD@.|})

| PrecedencePredicateTransition { _target ; precedence } ->
   ()
  ; Fmt.(pf pps {|    target: %a@.|} dump_state_id _target)
  ; Fmt.(pf pps {|    isEpsilon: %a@.|} dump_pybool (isEpsilon e))
  ; Fmt.(pf pps {|    label: None@.|})
  ; Fmt.(pf pps {|    serializationType: PRECEDENCE@.|})
  ; Fmt.(pf pps {|    precedence: %d@.|} precedence)

| x ->
     Fmt.(pf pps {|    #<unhandled< %a >>@.|} pp x)


let mkEpsilonTransition ~target ?label ?(outermostPrecedenceReturn = -1) () =
  let serializationType = EPSILON in
  EpsilonTransition { _target=target ; outermostPrecedenceReturn ; label ; serializationType }

let mkRangeTransition ~target ~start ~stop () =
  let serializationType = RANGE in
  let labelSet = IntervalSet.( () |> mk |> add (Range.mk ~start (stop+1)) ) in
  RangeTransition { _target=target ; start ; stop ; label=labelSet ; serializationType }

let mkRuleTransition ~ruleStart ~ruleIndex ~precedence ~followState ?label () =
  let serializationType = RULE in
  RuleTransition { ruleStart ; ruleIndex ; precedence ; followState ; label ; serializationType }

let mkPredicateTransition ~target ~ruleIndex ~predIndex ~isCtxDependent ?label () =
  let serializationType = PREDICATE in
  PredicateTransition { _target=target ; ruleIndex ; predIndex ; isCtxDependent ; serializationType ; label }

let mkAtomTransition ~target ~label () =
  let labelSet = IntervalSet.( () |> mk |> addOne label ) in
  let serializationType = ATOM in
  AtomTransition { _target=target ; label=labelSet ; label_=label ; serializationType }

let mkActionTransition ~target ~ruleIndex ~actionIndex ~isCtxDependent ?label () =
  let serializationType = ACTION in
  ActionTransition { _target=target ; ruleIndex ; actionIndex ; isCtxDependent ; label ; serializationType }

let mkSetTransition ~target ~set () =
  let serializationType = SET in
  SetTransition { _target=target ; set ; serializationType }

let mkNotSetTransition ~target ~set () =
  let serializationType = NOT_SET in
  NotSetTransition { _target=target ; set ; serializationType }

let mkWildcardTransition ~target ?label () =
  let serializationType = WILDCARD in
  WildcardTransition { _target=target ; label ; serializationType }

let mkPrecedencePredicateTransition ~target ~precedence ?label () =
  let serializationType = PRECEDENCE in
  PrecedencePredicateTransition { _target=target ; precedence ; label ; serializationType }

let target = function
  EpsilonTransition { _target } -> _target
| RangeTransition { _target } -> _target
| RuleTransition { ruleStart=target } -> target
| PredicateTransition { _target } -> _target
| AtomTransition { _target } -> _target
| ActionTransition { _target } -> _target
| SetTransition { _target } -> _target
| NotSetTransition { _target } -> _target
| WildcardTransition {_target} -> _target
| PrecedencePredicateTransition { _target } -> _target

end

module State = struct
  let mk_id n = Types.STID n
  let int_of_id (Types.STID n) = n
  type t = [%import: Types.state_t
            [@with node_t := Node.t]
            [@with edge_t := Edge.t]
           ]
and atn_state_type_t = [%import: Types.atn_state_type_t]
[@@deriving yojson,located_yojson, show]

let isDecisionState = Types.isDecisionState

  let dump pps st =
    Fmt.(pf pps {|  stateNumber: %a@.|} dump_state_id st.stateNumber)
    ; Fmt.(pf pps {|  stateType: %a@.|} pp_atn_state_type_t Node.(serialization_name st.node))
    ; Fmt.(pf pps {|  ruleIndex: %d@.|} st.ruleIndex)
    ; Fmt.(pf pps {|  epsilonOnlyTransitions: %a@.|}
             dump_pybool st.epsilonOnlyTransitions)
    ; Node.dump pps st.node
    ; Fmt.(pf pps {|  #transitions: %d@.|} (List.length st.transitions))
    ; st.transitions
      |> List.iteri
           (fun i e ->
             Fmt.(pf pps "  Edge %d@." i)
            ; Edge.dump pps e)
           
  let mk ?(nonGreedy=false) ?(transitions=[]) stateNumber (node, ruleIndex) =
    let stateType = Node.serialization_name node in
    let epsilonOnlyTransitions = transitions <> [] && List.for_all Edge.isEpsilon transitions in
    { stateNumber ; stateType ; node ; ruleIndex ; transitions ; epsilonOnlyTransitions }

  let mkRuleStartState ?stopState ?(isPrecedenceRule = false) () =
    Node.RuleStartState { stopState ; isPrecedenceRule }

  let mkBasicBlockStartState ?(decision = -1) ?(nonGreedy = false) ?endState () =
    Node.BasicBlockStartState { decision ; nonGreedy ; endState }

  let mkPlusBlockStartState ?(decision = -1) ?(nonGreedy = false) ?endState ?loopBackState () =
    Node.PlusBlockStartState { decision ; nonGreedy ; endState ; loopBackState }

  let mkStarBlockStartState ?(decision = -1) ?(nonGreedy = false) ?endState () =
    Node.StarBlockStartState { decision ; nonGreedy ; endState }

  let mkStarLoopEntryState ?(decision = -1) ?(nonGreedy = false) ?loopBackState ?isPrecedenceDecision () =
    Node.StarLoopEntryState { decision ; nonGreedy ; loopBackState ; isPrecedenceDecision }

  let mkPlusLoopbackState ?(decision = -1) ?(nonGreedy = false) () =
    Node.PlusLoopbackState { decision ; nonGreedy }

  let mkBlockEndState ?startState () =
    Node.BlockEndState { startState }

  let mkLoopEndState ?loopBackState () =
    Node.LoopEndState { loopBackState }

  let mkTokensStartState ?(decision = -1) ?(nonGreedy = false) () =
    Node.TokensStartState { decision ; nonGreedy }

  let addTransition st ?(index= -1) edge =
    st.transitions <- st.transitions @ [edge] ;
    
    st.epsilonOnlyTransitions <- List.for_all Edge.isEpsilon st.transitions

  type states_t = STATES of t array
[@@deriving yojson,located_yojson, show]
  let nstates (STATES l) = Array.length l
  let mk_states l = STATES (Array.of_list (List.mapi (fun i x -> mk (mk_id i) x) l))
  let get_state t i =
    match (t,i) with
      (STATES t, Types.STID i) -> t.(i)

  let states_to_list (STATES t) = Array.to_list t
  let iter f (STATES t) =
    Array.iter f t

  let for_all f (STATES t) =
    Array.for_all f t
end

module LexerAction = struct
  type t = [%import: Types.lexer_action_t
            [@with lexer_action_t := t]
           ]
[@@deriving yojson,located_yojson, show]

let dump pps = function
    LexerChannelAction { isPositionDependent ; channel } ->
   ()
  ; Fmt.(pf pps "  actionType: <LexerActionType. CHANNEL: 0>@.")
  ; Fmt.(pf pps "  isPositionDependent: %a@." dump_pybool isPositionDependent)
     
| LexerCustomAction { isPositionDependent ; ruleIndex ; actionIndex } ->
   ()
  ; Fmt.(pf pps "  actionType: <LexerActionType.CUSTOM: 1>@.")
  ; Fmt.(pf pps "  isPositionDependent: %a@." dump_pybool isPositionDependent)
  ; Fmt.(pf pps "  ruleIndex: %d@." ruleIndex)
  ; Fmt.(pf pps "  actionIndex: %d@." actionIndex)


| LexerModeAction { isPositionDependent ; mode } ->
   ()
  ; Fmt.(pf pps "  actionType: <LexerActionType.MODE: 2>@.")
  ; Fmt.(pf pps "  isPositionDependent: %a@." dump_pybool isPositionDependent)
  ; Fmt.(pf pps "  mode: %d@." mode)

| LexerMoreAction { isPositionDependent } ->
   ()
  ; Fmt.(pf pps "  actionType: <LexerActionType.MORE: 3>@.")
  ; Fmt.(pf pps "  isPositionDependent: %a@." dump_pybool isPositionDependent)

| LexerPopModeAction { isPositionDependent } ->
   ()
  ; Fmt.(pf pps "  actionType: <LexerActionType.POP_MODE: 4>@.")
  ; Fmt.(pf pps "  isPositionDependent: %a@." dump_pybool isPositionDependent)

| LexerPushModeAction { isPositionDependent ; mode } ->
   ()
  ; Fmt.(pf pps "  actionType: <LexerActionType.PUSH_MODE: 5>@.")
  ; Fmt.(pf pps "  isPositionDependent: %a@." dump_pybool isPositionDependent)
  ; Fmt.(pf pps "  mode: %d@." mode)

| LexerSkipAction { isPositionDependent } ->
   ()
  ; Fmt.(pf pps "  actionType: <LexerActionType.SKIP: 6>@.")
  ; Fmt.(pf pps "  isPositionDependent: %a@." dump_pybool isPositionDependent)

| LexerTypeAction { isPositionDependent ; type_ } ->
   ()
  ; Fmt.(pf pps "  actionType: <LexerActionType.TYPE: 7>@.")
  ; Fmt.(pf pps "  isPositionDependent: %a@." dump_pybool isPositionDependent)
  ; Fmt.(pf pps "  type: %d@." type_)

| x -> Fmt.(pf pps "#<unhandled< %a >>" pp x)

let rec toString = function
  LexerChannelAction { channel } -> Fmt.(str "channel(%d)" channel)
| LexerCustomAction { ruleIndex ; actionIndex } -> Fmt.(str "custom(%d:%d)" ruleIndex actionIndex)
| LexerModeAction { mode } -> Fmt.(str "mode(%d)" mode)
| LexerMoreAction _ -> "more"
| LexerPopModeAction _ -> "popMode"
| LexerPushModeAction { mode } -> Fmt.(str "pushMode(%d)" mode)
| LexerSkipAction _ -> "skip"
| LexerTypeAction { type_ } -> Fmt.(str "type(%d)" type_)
| LexerIndexedCustomAction { action ; offset } -> Fmt.(str "indexedcustom(%s:%d)" (toString action) offset)
| x -> Fmt.(failwithf "LexerModeAction.toString: #<unhandled< %a >>" pp x)

module LexerActionType = struct
  let _CHANNEL = 0    (* #The type of a {@link LexerChannelAction} action.*)
  let _CUSTOM = 1     (* #The type of a {@link LexerCustomAction} action. *)
  let _MODE = 2       (* #The type of a {@link LexerModeAction} action. *)
  let _MORE = 3       (* #The type of a {@link LexerMoreAction} action. *)
  let _POP_MODE = 4   (* #The type of a {@link LexerPopModeAction} action. *)
  let _PUSH_MODE = 5  (* #The type of a {@link LexerPushModeAction} action. *)
  let _SKIP = 6       (* #The type of a {@link LexerSkipAction} action. *)
  let _TYPE = 7       (* #The type of a {@link LexerTypeAction} action. *)
end

let mkLexerChannelAction ?(actionType = LexerActionType._CHANNEL) ?(isPositionDependent = false) ~channel () =
  LexerChannelAction { actionType ; isPositionDependent ; channel }

let mkLexerCustomAction ?(actionType = LexerActionType._CUSTOM) ~ruleIndex ~actionIndex () =
  LexerCustomAction { actionType ; isPositionDependent = true ; ruleIndex ; actionIndex  }

let mkLexerModeAction ?(actionType = LexerActionType._MODE) ?(isPositionDependent = false) ~mode () =
  LexerModeAction { actionType ; isPositionDependent ; mode  }

let mkLexerMoreAction ?(actionType = LexerActionType._MORE) ?(isPositionDependent = false) () =
  LexerMoreAction { actionType ; isPositionDependent  }

let mkLexerPopModeAction ?(actionType = LexerActionType._POP_MODE) ?(isPositionDependent = false) () =
  LexerPopModeAction { actionType ; isPositionDependent  }

let mkLexerPushModeAction ?(actionType = LexerActionType._PUSH_MODE) ?(isPositionDependent = false) ~mode () =
  LexerPushModeAction { actionType ; isPositionDependent ; mode  }

let mkLexerSkipAction ?(actionType = LexerActionType._SKIP) ?(isPositionDependent = false) () =
  LexerSkipAction { actionType ; isPositionDependent  }

let mkLexerTypeAction ?(actionType = LexerActionType._TYPE) ?(isPositionDependent = false) ~type_ () =
  LexerTypeAction { actionType ; isPositionDependent ; type_  }

end

type atn_type_t = [%import: Types.atn_type_t]
[@@deriving yojson,located_yojson, show { with_path = false }, eq]

let dump_atn_type_t pps t =
  let n = match t with LEXER -> 0 | PARSER -> 1 in
  Fmt.(pf pps "<ATNType.%a: %d>" pp_atn_type_t t n)

type t = {
    grammarType : atn_type_t
  ; maxTokenType : int
  ; states : State.states_t
  ; ruleToStartState : state_id array
  ; ruleToTokenType : int array option
  ; ruleToStopState : state_id array
  ; modeToStartState : state_id array
  ; sets : IntervalSet.t array
  ; decisionToState : state_id array
  ; lexerActions : LexerAction.t array option
  }
[@@deriving yojson,located_yojson, show]

let dump pps atn =
  Fmt.(pf pps {|grammarType: %a@.|} dump_atn_type_t atn.grammarType)
  ; Fmt.(pf pps {|maxTokenType: %d@.|} atn.maxTokenType)
  ; Fmt.(pf pps {|#states: %d@.|} (State.nstates atn.states))
  ; atn.states
    |> State.iter
         (fun state ->
           Fmt.(pf pps {|State %a@.%a@.|}
                  dump_state_id state.stateNumber
                  State.dump state
           )
         )
  ; Fmt.(pf pps {|#sets: %d@.|} (Array.length atn.sets))
  ; atn.sets
    |> Array.iteri
         (fun i s ->
           Fmt.(pf pps {|Set %d: %a@.|} i IntervalSet.dump atn.sets.(i)))
  ; (match atn.lexerActions with
       None -> Fmt.(pf pps "No lexer actions")
     | Some x ->
        Fmt.(pf pps {|#lexerActions: %d@.|} (Array.length x))
       ; x |> Array.iteri
                (fun i a ->
                  Fmt.(pf pps {|LexerAction %d@.|} i)
                 ; LexerAction.dump pps a)
    )

let check_version = parser
  [< 'n >] ->
    if n <> _SERIALIZED_VERSION then
      Fmt.(failwithf "Wrong version %d (should be %d)" n _SERIALIZED_VERSION)
    else ()

let pa_ATNType = parser
    [< '0 >] -> LEXER
  | [< '1 >]-> PARSER
  | [< 'n >] -> Fmt.(failwithf "unrecognized ATN Type %d" n)

let readATN = parser
  [< ty = pa_ATNType ; 'maxTokenType >] -> (ty, maxTokenType)
    
let readSTID = parser [< 'n >] -> State.mk_id n

let readNode strm =
  if !debug then
    Fmt.(pf stderr "readState: pos=%d@." (Stream.count strm)) ;
  let open Node in
  (parser
  bp [< 'stype ;
   node = (match deser_state_type bp stype with
           INVALID_TYPE ->
            Fmt.(failwithf "pos %d: Invalid state found in deserialization" bp)
         | BASIC ->
            (parser [< 'ruleIndex >] ->
             let st = BasicState in
             (st, ruleIndex)
            )
         | RULE_START ->
            (parser [< 'ruleIndex >] ->
             let st = State.mkRuleStartState () in
             (st, ruleIndex)
            )
         | BLOCK_START ->
            (parser [< 'ruleIndex ; endStateNumber=readSTID >] ->
             let st = State.mkBasicBlockStartState ~endState:endStateNumber () in
             (st, ruleIndex)
            )
         | PLUS_BLOCK_START ->
            (parser [< 'ruleIndex ; endStateNumber=readSTID >] ->
             let st = State.mkPlusBlockStartState ~endState:endStateNumber () in
             (st, ruleIndex)
            )
         | STAR_BLOCK_START ->
            (parser [< 'ruleIndex ; endStateNumber=readSTID >] ->
             let st = State.mkStarBlockStartState ~endState:endStateNumber () in
             (st, ruleIndex)
            )
         | TOKEN_START ->
            (parser [< 'ruleIndex >] ->
             let st = State.mkTokensStartState () in
             (st, ruleIndex)
            )
         | RULE_STOP ->
            (parser [< 'ruleIndex >] ->
             let st = RuleStopState in
             (st, ruleIndex)
            )
         | BLOCK_END ->
            (parser [< 'ruleIndex >] ->
             let st = State.mkBlockEndState () in
             (st, ruleIndex)
            )
         | STAR_LOOP_BACK ->
            (parser [< 'ruleIndex >] ->
             let st = StarLoopbackState in
             (st, ruleIndex)
            )
         | STAR_LOOP_ENTRY ->
            (parser [< 'ruleIndex >] ->
             let st = State.mkStarLoopEntryState () in
             (st, ruleIndex)
            )
         | PLUS_LOOP_BACK ->
            (parser [< 'ruleIndex >] ->
             let st = State.mkPlusLoopbackState () in
             (st, ruleIndex)
            )
         | LOOP_END ->
            (parser [< 'ruleIndex ; loopbackStateNumber=readSTID >] ->
             let st = State.mkLoopEndState ~loopBackState:loopbackStateNumber () in
             (st, ruleIndex)
            )

        ) >] -> node) strm

let set_nonGreedy states stid newv =
  let st = State.get_state states stid in
  match st.node with
    (BasicState
     | RuleStartState _
    | RuleStopState
    | BlockEndState _
    | StarLoopbackState
    | LoopEndState _) ->
    Fmt.(failwithf "set_nonGreedy: state is not a DecisionState@ %a@."
         State.pp st)
| BasicBlockStartState ({ nonGreedy=_ } as x) -> x.nonGreedy <- newv
| PlusBlockStartState ({ nonGreedy=_ } as x) -> x.nonGreedy <- newv
| StarBlockStartState ({ nonGreedy=_ } as x) -> x.nonGreedy <- newv
| TokensStartState ({ nonGreedy=_ } as x) -> x.nonGreedy <- newv
| StarLoopEntryState ({ nonGreedy=_ } as x) -> x.nonGreedy <- newv
| PlusLoopbackState ({ nonGreedy=_ } as x) -> x.nonGreedy <- newv

let readStates strm =
  let loopEndStates = ref [] in
  let loopbackStateNumber = ref [] in
  if !debug then
    Fmt.(pf stderr "readStates: pos=%d@." (Stream.count strm)) ;
  let nstates = readInt strm in
  let nodes = plistn readNode nstates strm in
  let states = State.mk_states nodes in
  let numNonGreedyStates = readInt strm in
  for i = 0 to numNonGreedyStates-1 do
    let stateNumber = readSTID strm in
    set_nonGreedy states stateNumber true
  done ;
  let numPrecedenceStates = readInt strm in
  for i = 0 to numPrecedenceStates-1 do
    let stateNumber = readSTID strm in
    (match (State.get_state states stateNumber).node with
       RuleStartState n ->
       n.isPrecedenceRule <- true
     | _ -> Fmt.(failwithf "Error in readStates: stateNumber=%a was not RuleStartState"
                 pp_state_id stateNumber))
  done ;
  states

let readRules (grammarType, (states : State.states_t)) strm =
  if !debug then
    Fmt.(pf stderr "readRules: pos=%d@." (Stream.count strm)) ;
  let open State in
  let nrules = readInt strm in
  if !debug then
    Fmt.(pf stderr "readRules: nrules=%d@." nrules) ;
  let (ruleToStartState, ruleToTokenType_opt) =
    match grammarType with
    | PARSER ->
       let ruleToStartState = plistn readSTID nrules strm in
       (Array.of_list ruleToStartState, None)
    | LEXER ->
       let pl = plistn (pa_pair readSTID readInt) nrules strm in
       let (ruleToStartState, ruleToTokenType) = split pl  in
       (Array.of_list ruleToStartState, Some (Array.of_list ruleToTokenType))
  in
  let ruleToStopState = Array.make nrules (State.mk_id 0) in
    states
    |> State.iter
         (fun st ->
           match st.node with
             RuleStopState ->
             ruleToStopState.(st.ruleIndex) <- st.stateNumber ;
             (match (State.get_state states (ruleToStartState.(st.ruleIndex))) with
                {node=RuleStartState n} ->
                 n.stopState <- Some st.stateNumber
              | st' ->
                 Fmt.(failwithf "readRules: state should have been RuleStartState, was@ %a@."
                      State.pp st'))
           | _ -> ()
         ) ;
    (ruleToStartState, ruleToTokenType_opt, ruleToStopState)

let readModes strm =
  if !debug then
    Fmt.(pf stderr "readModes: pos=%d@." (Stream.count strm)) ;
  let nmodes = readInt strm in
  let modeToStartState = plistn readSTID nmodes strm in
  Array.of_list modeToStartState

let readSet strm =
  if !debug then
    Fmt.(pf stderr "readSet: pos=%d@." (Stream.count strm)) ;
  (parser
    [< n=readInt ; containsEof=readBool ;
     ranges=plistn (pa_pair readInt readInt) n >] ->
     let ranges = List.map (fun (a,b) -> (a,b+1)) ranges in
     let ranges =
       if containsEof then (-1,0)::ranges
       else ranges in
     let ranges = List.map (fun (start,stop) -> Range.mk ~start stop) ranges in
     let iset =
       IntervalSet.(List.fold_right IntervalSet.add ranges (mk())) in
     if !debug then
       Fmt.(pf stderr "readSet -> %a@." IntervalSet.dump iset) ;
     iset) strm

let readSets strm =
  if !debug then
    Fmt.(pf stderr "readSets: pos=%d@." (Stream.count strm)) ;
  let m = readInt strm in
  let l = plistn readSet m strm in
  Array.of_list l


let Token._EOF = -1

let edgeFactory ~bp ty src trg arg1 arg2 arg3 sets : Edge.t option =
  let target = trg in
  if ty = 0 then begin
      Fmt.(pf stderr "pos %d: edgeFactory: edge type = 0!" bp) ;
      None
    end
  else Some
  (match ty with
    1 -> Edge.mkEpsilonTransition ~target ()
  | 2 -> if arg3 <> 0 then
              Edge.mkRangeTransition ~target ~start:Token._EOF ~stop:arg2 ()
            else Edge.mkRangeTransition ~target  ~start:arg1  ~stop:arg2 ()
  | 3 -> Edge.mkRuleTransition ~ruleStart:(State.mk_id arg1) ~ruleIndex:arg2 ~precedence:arg3 ~followState:target ()
  | 4 -> Edge.mkPredicateTransition ~target ~ruleIndex:arg1 ~predIndex:arg2 ~isCtxDependent:(arg3 <> 0) ()
  | 5 -> if arg3 <> 0 then
           Edge.mkAtomTransition ~target ~label:Token._EOF ()
         else Edge.mkAtomTransition ~target ~label:arg1 ()
  | 6 -> Edge.mkActionTransition ~target ~ruleIndex:arg1 ~actionIndex:arg2 ~isCtxDependent:(arg3 <> 0) ()
  | 7 ->  Edge.mkSetTransition ~target ~set:sets.(arg1) ()
  | 8 -> Edge.mkNotSetTransition ~target ~set:sets.(arg1) ()
  | 9 -> Edge.mkWildcardTransition ~target ()
  | 10 ->  Edge.mkPrecedencePredicateTransition ~target ~precedence:arg1 ()
  )

let readEdges (states,ruleToStartState,ruleToStopState) sets strm =
  let nedges = readInt strm in
  let l = plistn (parser bp
   [< src = readSTID ;
     trg = readSTID ;
     ttype = readInt ;
     arg1 = readInt ;
     arg2 = readInt ;
     arg3 = readInt >] ->
                  (src, edgeFactory ~bp ttype src trg arg1 arg2 arg3 sets)) nedges strm in
  l |> List.iter (fun (src, edge) ->
           match edge with
             None -> ()
           | Some e ->
              State.addTransition (State.get_state states src) e
         ) ;
  states
  |> State.iter
       (fun st ->
         st.transitions
         |> List.iter
              (function
                 (Edge.RuleTransition rt) as e ->
                  let outermostPrecedenceReturn = -1 in
                  let outermostPrecedenceReturn =
                    if (match (State.get_state states ruleToStartState.((State.get_state states (Edge.target e)).ruleIndex)) with
                          {node=RuleStartState n} -> n.isPrecedenceRule
                        | st' -> Fmt.(failwithf "readeEdges: state should have been RuleStartState, was@ %a@."
                                        State.pp st')) &&
                         rt.precedence = 0 then
                      (State.get_state states (Edge.target e)).ruleIndex
                    else outermostPrecedenceReturn in
                  let trans = Edge.mkEpsilonTransition ~target:rt.followState ~outermostPrecedenceReturn () in
                  State.addTransition (State.get_state states ruleToStopState.((State.get_state states (Edge.target e)).ruleIndex)) trans

               | _ -> ()
              )
       ) ;

  states
  |> State.iter
       (fun state ->
         match state.node with
           (Node.BasicBlockStartState _
            | Node.PlusBlockStartState _
           | Node.StarBlockStartState _) ->
           let endState_id_opt =
             match state.node with
               Node.BasicBlockStartState n -> n.endState
             | Node.PlusBlockStartState n -> n.endState
             | Node.StarBlockStartState n -> n.endState
             | _ -> assert false in
           let endState_id = match endState_id_opt with
               None ->
                Fmt.(failwithf "state=%a: endState = None: %a"
                       pp_state_id state.stateNumber
                       State.pp state)
             | Some n -> n in
           let endState = State.get_state states endState_id in
           (match endState.node with
              Node.BlockEndState n ->
               if n.startState <> None then
                 Fmt.(failwithf "state=%a: startState <> None: %a"
                        pp_state_id endState.stateNumber
                        State.pp endState) ;
               n.startState <- Some state.stateNumber
              | _ ->
                 Fmt.(failwithf "state=%a: endState should have been BlockEndState, was =%a"
                        pp_state_id endState.stateNumber
                        State.pp endState)
           )

         | Node.PlusLoopbackState n ->
            state.transitions
            |> List.iter
                 (fun t ->
                   let target_id = Edge.target t in
                   let target = State.get_state states target_id in
                   match target.node with
                     Node.PlusBlockStartState t ->
                     t.loopBackState <- Some state.stateNumber
                   | _ -> ()
                 )

         | Node.StarLoopbackState ->
            state.transitions
            |> List.iter
                 (fun t ->
                   let target_id = Edge.target t in
                   let target = State.get_state states target_id in
                   match target.node with
                     Node.StarLoopEntryState t ->
                     t.loopBackState <- Some state.stateNumber
                   | _ -> ()
                 )

         | _ -> ()

       )

let readDecisions states strm =
  let ndecisions = readInt strm in
  let l = plistn readSTID ndecisions strm in
  let decisionToState = Array.of_list l in
  decisionToState
  |> Array.iteri
       (fun i stid ->
         let st = State.get_state states stid in
         match st.node with
           BasicBlockStartState t -> t.decision <- i
         | PlusBlockStartState t -> t.decision <- i
         | StarBlockStartState t -> t.decision <- i
         | StarLoopEntryState t -> t.decision <- i
         | PlusLoopbackState t -> t.decision <- i
         | TokensStartState t -> t.decision <- i

         | (BasicState
            | RuleStartState _
           | RuleStopState
           | BlockEndState _
           | StarLoopbackState
           | LoopEndState _) ->
            Fmt.(failwithf "decision %d names state %a, but it's %a"
                   i pp_state_id stid State.pp st)
       ) ;
  decisionToState

let lexerActionFactory actionType data1 data2 =
  let open LexerAction in
  match actionType with
    0 -> mkLexerChannelAction ~channel:data1 ()
   | 1 -> mkLexerCustomAction ~ruleIndex:data1 ~actionIndex:data2 ()
   | 2 -> mkLexerModeAction ~mode:data1 ()
   | 3 -> mkLexerMoreAction ()
   | 4 -> mkLexerPopModeAction ()
   | 5 -> mkLexerPushModeAction ~mode:data1 ()
   | 6 -> mkLexerSkipAction ()
   | 7 -> mkLexerTypeAction ~type_:data1 ()
   | _ -> Fmt.(failwithf "The specified lexer action type %d is not valid." actionType)

let readLexerActions grammarType strm =
  if grammarType = LEXER then
    let read1 = parser
      [< actionType = readInt ;
       data1 = readInt ;
       data2 = readInt >] ->
                lexerActionFactory actionType data1 data2 in
    let count = readInt strm in
    let l = plistn read1 count strm in
    Some (Array.of_list l)
  else None

let markPrecedenceDecisions (states,ruleToStartState) =
  states
  |> State.iter
       (fun state ->
         match state.node with
           StarLoopEntryState n ->
            if (match (State.get_state states ruleToStartState.(state.ruleIndex)) with
                  {node=RuleStartState n} -> n.isPrecedenceRule
                | st' -> Fmt.(failwithf "markPrecedenceDecisions: state should be RuleStartState but is@ %a@."
                              State.pp st')) then
              let maybeLoopEndState_id = Edge.target (last state.transitions) in
              let maybeLoopEndState = State.get_state states maybeLoopEndState_id in
              (match maybeLoopEndState.node with
                 LoopEndState _ when maybeLoopEndState.epsilonOnlyTransitions ->
                  (match (State.get_state states (Edge.target (List.hd maybeLoopEndState.transitions))).node with
                     RuleStopState _ ->
                      n.isPrecedenceDecision <- Some true
                   | _ -> ())
               | _ -> ())
           | _ -> ()
       )

let deser1 = parser
  [< () = check_version ;
   (grammarType, maxTokenType) = readATN ;
   states = readStates ;
   (ruleToStartState, ruleToTokenType, ruleToStopState) = readRules (grammarType, states) ;
   modeToStartState = readModes ;
   sets = readSets ;
   () = readEdges (states,ruleToStartState,ruleToStopState) sets ;
   decisionToState = readDecisions states ;
   lexerActions = readLexerActions grammarType ;
   () = (fun _ -> markPrecedenceDecisions (states,ruleToStartState))
   >] ->
    {
      grammarType
    ; maxTokenType
    ; states
    ; ruleToStartState
    ; ruleToTokenType
    ; ruleToStopState
    ; modeToStartState
    ; sets
    ; decisionToState
    ; lexerActions
    }

let verifyATN atn =
  atn.states
  |> State.iter
       (fun state ->
         if not (state.epsilonOnlyTransitions || List.length state.transitions <= 1) then
           Fmt.(failwithf "state %a: epsilonOnlyTransition check: %a"
                  pp_state_id state.stateNumber State.pp state) ;
         (match state.node with
            PlusBlockStartState n ->
             if None = n.loopBackState then
               Fmt.(failwithf "state %a: loopBackState was None: %a"
                      pp_state_id state.stateNumber State.pp state)
             else ()

          | StarLoopEntryState n ->
             if None = n.loopBackState then
               Fmt.(failwithf "state %a: loopBackState was None: %a"
                      pp_state_id state.stateNumber State.pp state) ;
             if 2 <> List.length state.transitions then
               Fmt.(failwithf "state %a: len(transitions) = %d <> 2: %a"
                      pp_state_id state.stateNumber
                      (List.length state.transitions) 
                      State.pp state) ;
             let [e1; e2] = state.transitions in
             let st1' = State.get_state atn.states (Edge.target e1) in
             let st2' = State.get_state atn.states (Edge.target e2) in
             (match (st1', st2') with
                {node=StarBlockStartState _},{node=LoopEndState _} when not n.nonGreedy -> ()
              | {node=LoopEndState _},{node=StarBlockStartState _} when n.nonGreedy -> ()
              | _ ->
                 Fmt.(failwithf "state %a: @[(two) transitions from@ %a do not lead to appropriate state:@ %a,@ %a@]"
                        pp_state_id state.stateNumber
                        State.pp state
                        State.pp st1'
                        State.pp st2'))

          | StarLoopbackState ->
             if 1 <> List.length state.transitions then
               Fmt.(failwithf "state %a: StarLoopbackState #transitions <> 1: %a"
                      pp_state_id state.stateNumber
                      State.pp state) ;
             let e = List.hd state.transitions in
             let stid' = Edge.target e in
             let st' = State.get_state atn.states stid' in
             (match st'.node with
                StarLoopEntryState _ -> ()
              | _ ->
                 Fmt.(failwithf "state %a: transition from StarLoopbackState should be to StarLoopEntryState: %a -> %a"
                        pp_state_id state.stateNumber
                        State.pp state
                        State.pp st')
             )

          | LoopEndState n ->
             if None = n.loopBackState then
               Fmt.(failwithf "state %a: LoopEndState with loopBackState = None: %a"
                      pp_state_id state.stateNumber
                      State.pp state)

          | RuleStartState n  ->
             if None = n.stopState then
               Fmt.(failwithf "state %a: RuleStartState with stopState = None: %a"
                      pp_state_id state.stateNumber
                      State.pp state)

          | (BasicBlockStartState {endState}
             | PlusBlockStartState {endState}
            | StarBlockStartState {endState}) ->
             if None = endState then
               Fmt.(failwithf "state %a: *BlockStartState with endState = None: %a"
                      pp_state_id state.stateNumber
                      State.pp state)

          | BlockEndState n ->
             if None = n.startState then
               Fmt.(failwithf "state %a: BlockEndState with startState = None: %a"
                      pp_state_id state.stateNumber
                      State.pp state)

          | (BasicBlockStartState {decision}
             | PlusBlockStartState {decision}
            | StarBlockStartState {decision}
            | PlusLoopbackState {decision}
            | StarLoopEntryState {decision}
            | TokensStartState {decision}) ->
             if not (List.length state.transitions <= 1 || decision >= 0) then
               Fmt.(failwithf "state %a: *DecisionState with #transitions  > 1 || decision < 0: %a"
                      pp_state_id state.stateNumber
                      State.pp state)

          | _ ->
             if not (List.length state.transitions <= 1 ||
                       (match state.node with RuleStopState -> true | _ -> false)) then
               Fmt.(failwithf "state %a: catch-all failed: %a"
                      pp_state_id state.stateNumber
                      State.pp state)

         )
       )

let deser ?(verify=true) interp =
  let strm = Stream.of_list interp.Raw.atn in
  let atn = deser1 strm in
  if verify then verifyATN atn ;
  atn
