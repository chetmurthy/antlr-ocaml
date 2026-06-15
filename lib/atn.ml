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
[%%typedecls
type t = [%import: Types.node_t]
type 'a block_start_node_t = [%import: 'a Types.block_start_node_t]
type plus_block_start_node_t = [%import: Types.plus_block_start_node_t]
]
[@@deriving show]

let rule_index_of_node = function
  | RuleStartState -> 1
  | BasicBlockStartState _ -> 2
  | PlusBlockStartState _ -> 3
  | StarBlockStartState _ -> 4
  | TokensStartState -> 5
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
    Node.BasicBlockStartState { decision ; nonGreedy ; endState ; extra = () }

  let mkPlusBlockStartState ?(decision = -1) ?(nonGreedy = false) ?endState ?loopBackState () =
    Node.PlusBlockStartState { decision ; nonGreedy ; endState ; extra = { loopBackState } }

  let mkStarBlockStartState ?(decision = -1) ?(nonGreedy = false) ?endState () =
    Node.StarBlockStartState { decision ; nonGreedy ; endState ; extra = () }

  let mkStarLoopEntryState ?(decision = -1) ?(nonGreedy = false) ?loopBackState ?isPrecedenceDecision () =
    Node.StarLoopEntryState { decision ; nonGreedy ; loopBackState ; isPrecedenceDecision }

  let mkPlusLoopbackState ?(decision = -1) ?(nonGreedy = false) () =
    Node.PlusLoopbackState { decision ; nonGreedy }

  let mkBlockEndState ?startState () =
    Node.BlockEndState { startState }

  let addTransition st ?(index= -1) edge =
    st.transitions <- st.transitions @ [edge] ;
    
    st.epsilonOnlyTransitions <- List.for_all Edge.isEpsilon st.transitions

  type states_t = STATES of t array
  let mk_states l = STATES (Array.of_list (List.mapi (fun i x -> mk (mk_id i) x) l))
  let get_state t i =
    match (t,i) with
      (STATES t, Types.STID i) -> t.(i)

  let iter f (STATES t) =
    Array.iter f t

end

type atn_type_t =
    LEXER
  | PARSER

type t = {
    grammarType : atn_type_t
  ; maxTokenType : int
  ; states : State.states_t
  ; ruleToStartState : state_id array
  ; ruleToTokenType_opt : int array option
  ; ruleToStopState : state_id array
  ; modeToStartState : state_id array
  ; sets : IntervalSet.t array
  }
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
             let st = TokensStartState in
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
             let st = LoopEndState loopbackStateNumber in
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
                     t.extra.loopBackState <- Some state.stateNumber
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


let deser1 = parser
  [< () = check_version ;
   (grammarType, maxTokenType) = readATN ;
   states = readStates ;
   (ruleToStartState, ruleToTokenType_opt, ruleToStopState) = readRules (grammarType, states) ;
   modeToStartState = readModes ;
   sets = readSets ;
   () = readEdges (states,ruleToStartState,ruleToStopState) sets
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
    }

let deser interp =
  let strm = Stream.of_list interp.Raw.atn in
  deser1 strm
