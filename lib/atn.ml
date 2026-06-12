(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.utils,pa_ppx.deriving_plugins.std,pa_ppx.import *)

open Pa_ppx_base
open Ppxutil
open Pa_ppx_utils.Std
open Interp

let plisti elem i = 
  let rec plist_rec accum i = parser
     [< e = elem i; strm >] -> plist_rec (e::accum) (i+1) strm
   | [< >]                         -> (List.rev accum)
  in plist_rec [] i

let plistn elem i = 
  let rec plist_rec accum i strm =
    if i = 0 then List.rev accum
    else plist_rec2 accum (i-1) strm
    and plist_rec2 accum i = parser
     [< e = elem; strm >] -> plist_rec (e::accum) i strm
  in plist_rec [] i

let _SERIALIZED_VERSION = 4

module Node = struct
type t = [%import: Types.node_t]
[@@deriving show]

let rule_index_of_node = function
  | RuleStartState -> 1
  | BasicBlockStartState _ -> 2
  | PlusBlockStartState _ -> 3
  | StarBlockStartState _ -> 4
  | TokensStartState -> 5
  | RuleStopState -> 6
  | BlockEndState -> 7
  | StarLoopbackState -> 8
  | StarLoopEntryState -> 9
  | PlusLoopbackState -> 10
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
  module RuleTransition = Types.RuleTransition
  module PredicateTransition = Types.PredicateTransition
  module ActionTransition = Types.ActionTransition

  type t = [%import: Types.edge_t
           ]
  and raw_edge_t = [%import: Types.raw_edge_t]

let mkEpsilonTransition ?(outermostPrecedenceReturn= -1) (target) =
  { target ; it = EpsilonTransition outermostPrecedenceReturn }

let mkRangeTransition target start stop =
  { target ; it = RangeTransition (Range.mk ~start stop) }

let mkRuleTransition ruleStart ruleIndex precedence followState =
  { target = followState ; it = RuleTransition (RuleTransition.mk ~ruleStart ~ruleIndex ~precedence) }
end

module State = struct
  type t = [%import: Types.state_t
            [@with node_t := Node.t]
           ]
  [@@deriving show]

  let mk ?(isPrecedenceRule=false) ?(nonGreedy=false) ?stopState num node =
    { num ; node ; nonGreedy ; isPrecedenceRule ; stopState }

end

type atn_type_t =
    LEXER
  | PARSER

type t = {
    grammarType : atn_type_t
  ; maxTokenType : int
  ; states : State.t array
  ; ruleToStartState : int array
  ; ruleToTokenType_opt : int array option
  ; ruleToStopState : int array
  ; modeToStartState : int array
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

let pa_pair pa1 pa2 =
  parser [< p1 = pa1 ; p2 = pa2 >] -> (p1, p2)

let readInt = parser [< 'n >] -> n

let readBool = parser [< 'n >] -> n<>0

let readATN = parser
  [< ty = pa_ATNType ; 'maxTokenType >] -> (ty, maxTokenType)
    
let readNode states =
  let open Node in
  parser
  bp [< 'stype ;
   node = (match deser_state_type bp stype with
           INVALID_TYPE -> (parser [< >] -> None)
         | BASIC ->
            (parser [< 'ruleIndex >] ->
             let st = BasicState in
             Some (st, ruleIndex)
            )
         | RULE_START ->
            (parser [< 'ruleIndex >] ->
             let st = RuleStartState in
             Some (st, ruleIndex)
            )
         | BLOCK_START ->
            (parser [< 'ruleIndex ; 'endStateNumber >] ->
             let st = BasicBlockStartState endStateNumber in
             Some (st, ruleIndex)
            )
         | PLUS_BLOCK_START ->
            (parser [< 'ruleIndex ; 'endStateNumber >] ->
             let st = PlusBlockStartState endStateNumber in
             Some (st, ruleIndex)
            )
         | STAR_BLOCK_START ->
            (parser [< 'ruleIndex ; 'endStateNumber >] ->
             let st = StarBlockStartState endStateNumber in
             Some (st, ruleIndex)
            )
         | TOKEN_START ->
            (parser [< 'ruleIndex >] ->
             let st = TokensStartState in
             Some (st, ruleIndex)
            )
         | RULE_STOP ->
            (parser [< 'ruleIndex >] ->
             let st = RuleStopState in
             Some (st, ruleIndex)
            )
         | BLOCK_END ->
            (parser [< 'ruleIndex >] ->
             let st = BlockEndState in
             Some (st, ruleIndex)
            )
         | STAR_LOOP_BACK ->
            (parser [< 'ruleIndex >] ->
             let st = StarLoopbackState in
             Some (st, ruleIndex)
            )
         | STAR_LOOP_ENTRY ->
            (parser [< 'ruleIndex >] ->
             let st = StarLoopEntryState in
             Some (st, ruleIndex)
            )
         | PLUS_LOOP_BACK ->
            (parser [< 'ruleIndex >] ->
             let st = PlusLoopbackState in
             Some (st, ruleIndex)
            )
         | LOOP_END ->
            (parser [< 'ruleIndex ; 'loopbackStateNumber >] ->
             let st = LoopEndState loopbackStateNumber in
             Some (st, ruleIndex)
            )

        ) >] -> node

let readStates strm =
  let loopEndStates = ref [] in
  let loopbackStateNumber = ref [] in
  let nstates = readInt strm in
  let states = Array.init nstates (fun i -> State.mk i None) in
  let nodes = plistn (readNode states) nstates strm in
  nodes |> List.iteri (fun i node -> states.(i).node <- node) ;
  let numNonGreedyStates = readInt strm in
  for i = 0 to numNonGreedyStates-1 do
    states.(i).nonGreedy <- true
  done ;
  let numPrecedenceStates = readInt strm in
  for i = 0 to numPrecedenceStates-1 do
    states.(i).isPrecedenceRule <- true
  done ;
  states

let readRules (grammarType, states) strm =
  let open State in
  let nrules = readInt strm in
  let (ruleToStartState, ruleToTokenType_opt) =
    match grammarType with
    | PARSER ->
       let ruleToStartState = plistn readInt nrules strm in
       (Array.of_list ruleToStartState, None)
    | LEXER ->
       let pl = plistn (pa_pair readInt readInt) nrules strm in
       let (ruleToStartState, ruleToTokenType) = split pl  in
       (Array.of_list ruleToStartState, Some (Array.of_list ruleToTokenType))
  in
  let ruleToStopState = Array.make nrules 0 in
    states
    |> Array.iter
         (fun st ->
           match st.node with
             Some (RuleStopState, _) | None -> ()
             | Some (n, ruleIndex) ->
                ruleToStopState.(ruleIndex) <- st.num ;
                states.(ruleToStartState.(ruleIndex)).stopState <- Some st.num
         ) ;
    (ruleToStartState, ruleToTokenType_opt, ruleToStopState)

let readModes strm =
  let nmodes = readInt strm in
  let modeToStartState = plistn readInt nmodes strm in
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
       List.fold_left IntervalSet.add (IntervalSet.mk()) ranges in
     iset) m strm in
  Array.of_list l


let _Token_EOF = -1

let edgeFactory states ty src trg arg1 arg2 arg3 sets =
  let target = trg in
  let target_state = states.(trg) in
  if ty = 0 then None
  else Some
  (match ty with
    1 -> Edge.mkEpsilonTransition (target)
  | 2 -> if arg3 <> 0 then
              Edge.mkRangeTransition target _Token_EOF arg2
            else Edge.mkRangeTransition target  arg1  arg2
  | 3 -> Edge.mkRuleTransition arg1 arg2 arg3 target
(*
  | 4 -> PredicateTransition(target, arg1, arg2, arg3 <> 0)
  | 5 -> if arg3 <> 0 then
           AtomTransition(target, Token.EOF)
         else AtomTransition(target, arg1)
  | 6 -> ActionTransition(target, arg1, arg2, arg3 <> 0)
  | 7 ->  SetTransition(target, sets.(arg1))
  | 8 -> NotSetTransition(target, sets.(arg1))
  | 9 -> WildcardTransition(target)
  | 10 ->  PrecedencePredicateTransition(target, arg1)
 *)
  )
(*
let readEdges strm =
  let nedges = readInt strm in
  let l = plistn (parser
    [< src = readInt ;
     trg = readInt ;
     ttype = readInt ;
     arg1 = readInt ;
     arg2 = readInt ;
     arg3 = readInt >] -> (src, trg, ttype, arg1, arg2, arg3)) nedges strm in
 *)


let deser1 = parser
  [< () = check_version ;
   (grammarType, maxTokenType) = readATN ;
   states = readStates ;
   (ruleToStartState, ruleToTokenType_opt, ruleToStopState) = readRules (grammarType, states) ;
   modeToStartState = readModes ;
   sets = readSets
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
