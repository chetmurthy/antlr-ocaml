(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.utils,pa_ppx.deriving_plugins.std,pa_ppx.import *)

open Pa_ppx_base
open Ppxutil
open Pa_ppx_utils.Std
open Interp
open Util

let readInt = parser [< 'n >] -> n

let readBool = parser [< 'n >] -> n<>0

let _SERIALIZED_VERSION = 4

type state_id = [%import: Types.state_id]
[@@deriving show]


module Node = struct
type t = [%import: Types.node_t]
[@@deriving show]

let rule_index_of_node = function
  | RuleStartState -> 1
  | BasicBlockStartState _ -> 2
  | PlusBlockStartState _ -> 3
  | StarBlockStartState _ -> 4
  | TokensStartState _ -> 5
  | RuleStopState -> 6
  | BlockEndState _ -> 7
  | StarLoopbackState -> 8
  | StarLoopEntryState _ -> 9
  | PlusLoopbackState _ -> 10
  | LoopEndState _ -> 11


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

let deser_state_type bp = function
  0 -> INVALID_TYPE
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
end

module Edge = struct
  type t = [%import: Types.edge_t]
  [@@deriving show]

let mkEpsilonTransition ~target ?(outermostPrecedenceReturn = -1) () =
  EpsilonTransition { _target=target ; outermostPrecedenceReturn }

let mkRangeTransition ~target ~start ~stop () =
  RangeTransition { _target=target ; start ; stop }

let mkRuleTransition ~ruleStart ~ruleIndex ~precedence ~followState () =
  RuleTransition { ruleStart ; ruleIndex ; precedence ; followState }

let mkPredicateTransition ~target ~ruleIndex ~predIndex ~isCtxDependent () =
  PredicateTransition { _target=target ; ruleIndex ; predIndex ; isCtxDependent }

let mkAtomTransition ~target ~label () =
  AtomTransition { _target=target ; label }

let mkActionTransition ~target ~ruleIndex ~actionIndex ~isCtxDependent () =
  ActionTransition { _target=target ; ruleIndex ; actionIndex ; isCtxDependent }

let mkSetTransition ~target ~set () =
  SetTransition { _target=target ; set }

let mkNotSetTransition ~target ~set () =
  NotSetTransition { _target=target ; set }

let mkWildcardTransition ~target () =
  WildcardTransition target

let mkPrecedencePredicateTransition ~target ~precedence () =
  PrecedencePredicateTransition { _target=target ; precedence }

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

let target = function
  EpsilonTransition { _target } -> _target
| RangeTransition { _target } -> _target
| RuleTransition { ruleStart=target } -> target
| PredicateTransition { _target } -> _target
| AtomTransition { _target } -> _target
| ActionTransition { _target } -> _target
| SetTransition { _target } -> _target
| NotSetTransition { _target } -> _target
| WildcardTransition target -> target
| PrecedencePredicateTransition { _target } -> _target

end

module State = struct
  let mk_id n = Types.STID n

  type t = [%import: Types.state_t
            [@with node_t := Node.t]
            [@with edge_t := Edge.t]
           ]
  [@@deriving show]

  let mk ?(isPrecedenceRule=false) ?(nonGreedy=false) ?stopState ?(transitions=[]) stateNumber (node, ruleIndex) =
    let epsilonOnlyTransitions = List.for_all Edge.isEpsilon transitions in
    { stateNumber ; node ; ruleIndex ; nonGreedy ; isPrecedenceRule ; stopState ; transitions ; epsilonOnlyTransitions }

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
  let nstates (STATES l) = Array.length l
  let mk_states l = STATES (Array.of_list (List.mapi (fun i x -> mk (mk_id i) x) l))
  let get_state t i =
    match (t,i) with
      (STATES t, Types.STID i) -> t.(i)

  let iter f (STATES t) =
    Array.iter f t

end

module LexerAction = struct
  type t = [%import: Types.lexer_action_t]
  [@@deriving show]


let mkLexerChannelAction ?(isPositionDependent = false) ~channel () =
  LexerChannelAction { isPositionDependent ; channel }

let mkLexerCustomAction ~ruleIndex ~actionIndex () =
  LexerCustomAction { isPositionDependent = true ; ruleIndex ; actionIndex  }

let mkLexerModeAction ?(isPositionDependent = false) ~mode () =
  LexerModeAction { isPositionDependent ; mode  }

let mkLexerMoreAction ?(isPositionDependent = false) () =
  LexerMoreAction { isPositionDependent  }

let mkLexerPopModeAction ?(isPositionDependent = false) () =
  LexerPopModeAction { isPositionDependent  }

let mkLexerPushModeAction ?(isPositionDependent = false) ~mode () =
  LexerPushModeAction { isPositionDependent ; mode  }

let mkLexerSkipAction ?(isPositionDependent = false) () =
  LexerSkipAction { isPositionDependent  }

let mkLexerTypeAction ?(isPositionDependent = false) ~type_ () =
  LexerTypeAction { isPositionDependent ; type_  }

end

type atn_type_t =
    LEXER
  | PARSER
[@@deriving show { with_path = false }]

let dump_atn_type_t pps t =
  let n = match t with LEXER -> 0 | PARSER -> 1 in
  Fmt.(pf pps "<ATNType.%a: %d>" pp_atn_type_t t n)

type t = {
    grammarType : atn_type_t
  ; maxTokenType : int
  ; states : State.states_t
  ; ruleToStartState : state_id array
  ; ruleToTokenType_opt : int array option
  ; ruleToStopState : state_id array
  ; modeToStartState : state_id array
  ; sets : IntervalSet.t array
  ; decisionToState : state_id array
  ; lexerActions : LexerAction.t array option
  }

let dump pps atn =
  Fmt.(pf pps {|grammarType: %a@.|} dump_atn_type_t atn.grammarType)
  ; Fmt.(pf pps {|maxTokenType: %d@.|} atn.maxTokenType)
  ; Fmt.(pf pps {|#states: %d@.|} (State.nstates atn.states))
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

let readNode =
  let open Node in
  parser
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
             let st = RuleStartState in
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

        ) >] -> node

let readStates strm =
  let loopEndStates = ref [] in
  let loopbackStateNumber = ref [] in
  let nstates = readInt strm in
  let nodes = plistn readNode nstates strm in
  let states = State.mk_states nodes in
  let numNonGreedyStates = readInt strm in
  for i = 0 to numNonGreedyStates-1 do
    (State.get_state states (State.mk_id i)).nonGreedy <- true
  done ;
  let numPrecedenceStates = readInt strm in
  for i = 0 to numPrecedenceStates-1 do
    (State.get_state states (State.mk_id i)).isPrecedenceRule <- true
  done ;
  states

let readRules (grammarType, (states : State.states_t)) strm =
  let open State in
  let nrules = readInt strm in
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
             (State.get_state states (ruleToStartState.(st.ruleIndex))).stopState <- Some st.stateNumber
           | _ -> ()
         ) ;
    (ruleToStartState, ruleToTokenType_opt, ruleToStopState)

let readModes strm =
  let nmodes = readInt strm in
  let modeToStartState = plistn readSTID nmodes strm in
  Array.of_list modeToStartState

let readSets strm =
  let m = readInt strm in
  let l = plistn (parser
    [< n=readInt ; containsEof=readBool ;
     ranges=plistn (pa_pair readInt readInt) n >] ->
     let ranges = List.map (fun (a,b) -> (a,b+1)) ranges in
     let ranges =
       if containsEof then (-1,-1)::ranges
       else ranges in
     let ranges = List.map (fun (start,stop) -> Range.mk ~start stop) ranges in
     let iset =
       IntervalSet.(List.fold_right IntervalSet.add ranges (mk())) in
     iset) m strm in
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
                    if (State.get_state states ruleToStartState.((State.get_state states (Edge.target e)).ruleIndex)).isPrecedenceRule &&
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
            | RuleStartState
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
            if (State.get_state states ruleToStartState.(state.ruleIndex)).isPrecedenceRule then
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
   (ruleToStartState, ruleToTokenType_opt, ruleToStopState) = readRules (grammarType, states) ;
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
    ; ruleToTokenType_opt
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
                 Fmt.(failwithf "state %a: (two) transitions from %a do not lead to appropriate state: %a, %a"
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

          | RuleStartState ->
             if None = state.stopState then
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

let deser interp =
  let strm = Stream.of_list interp.Raw.atn in
  let atn = deser1 strm in
  verifyATN atn ;
  atn
