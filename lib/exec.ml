(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.utils,pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.yojson,pa_ppx.deriving_plugins.located_yojson,pa_ppx.import *)

open Pa_ppx_utils
open Util
open Atn

module M = Mimick

module PC = struct
let _EMPTY_RETURN_STATE = 0x7FFFFFFF

open Coll

type pc_t =
  EMPTY
| SINGLETON of (pc_t option * int)
| ARRAY of (pc_t option * int) list
type t = pc_t

let rec toString = function
    EMPTY -> "$"
  | ARRAY[(_,rs)] when rs = _EMPTY_RETURN_STATE -> "[]"
  | SINGLETON(p, rs) -> 
     let up = match p with None -> "" | Some x -> toString x in
     if up = "" then
       if rs = _EMPTY_RETURN_STATE then "$"
       else string_of_int rs
     else Fmt.(str "%d %s" rs up)
  | ARRAY [] -> "[]"
  | ARRAY l ->
     Fmt.(str "[%a]" (list ~sep:(const string ", ") pair_as_singleton) l)

and pair_as_singleton pps (popt,n) =
  let s = toString (SINGLETON (popt, n)) in
  Fmt.(pf pps "%s" s)

let rec to_mimick = function
    EMPTY -> M.PC_EMPTY
  | SINGLETON (pcopt, rs) ->
     M.PC_SINGLETON { parentCtx = Option.map to_mimick pcopt ; returnState = rs }
  | ARRAY l ->
     let (parents, returnStates) = Std.split l in
     let parents = List.map (Option.map to_mimick) parents in
     M.PC_ARRAY { parents ; returnStates }

let rec of_mimick = function
    M.PC_EMPTY -> EMPTY
  | PC_SINGLETON { parentCtx ; returnState } ->
     SINGLETON (Option.map of_mimick parentCtx, returnState)
  | PC_ARRAY { parents ; returnStates } ->
     assert (List.length parents = List.length returnStates) ;
     ARRAY (Std.combine (List.map (Option.map of_mimick) parents) returnStates)

module MC = struct
  open Coll
  type t = ((pc_t * pc_t), pc_t) MHM.t

  let mk () = MHM.mk 23
  let get_opt t (a,b) =
    match MHM.map t (a,b) with
      v -> Some v
    | exception Not_found -> None
  let _add t (a,b) v =
    MHM.add t ((a,b), v)

  let toList t = MHM.toList t
  let ofList l = MHM.ofList 23 l

  let mc_to_mimick mc =
    let l = toList mc in
    let l = l |> List.map (fun ((a,b),c) ->
                     let txt = Fmt.(str "(%s)+(%s)->%s" (toString a) (toString b) (toString c)) in
                     (txt, { M.k = (to_mimick a, to_mimick b) ; v = to_mimick c })) in
    let l = List.stable_sort Stdlib.compare l in
    M.MergeCache l

  let mc_of_mimick mc : t =
    match mc with
      M.MergeCache l ->
      let l = List.map (fun (_, {M.k=(a,b); v=c}) ->
                  ((of_mimick a, of_mimick b), of_mimick c)) l in
      ofList l

  let add t (a,b) v =
    Tracelog.write (MergeCache_ENTER_add (mc_to_mimick t, to_mimick a, to_mimick b, to_mimick v)) ;
    _add t (a,b) v ;
    Tracelog.write (MergeCache_EXIT_add (mc_to_mimick t))

  let maybe_cache mc_opt a b merged =
    match mc_opt with
      None -> ()
    | Some mc -> add mc (a,b) merged

  let maybe_get mc_opt a b : pc_t option =
    match mc_opt with
      None -> None
    | Some mc ->
       match get_opt mc (a,b) with
         Some v -> Some v
       | None ->
          match get_opt mc (b,a) with
            Some v -> Some v
          | None -> None

let to_mimick = mc_to_mimick
let of_mimick = mc_of_mimick

end
module MergeCache = MC

type interim_t =
  CacheHit of pc_t
| Computed of pc_t
| Nothing

let _mergeRoot a b rootIsWildcard =
  if rootIsWildcard then
    match (a,b) with
      ((EMPTY, _)|(_, EMPTY)) -> Some EMPTY
    | _ -> None
  else
    match (a,b) with
      (EMPTY, EMPTY) -> Some EMPTY
    | (EMPTY,SINGLETON(pc_opt, rs)) ->
       Some (ARRAY [(pc_opt,rs); (None, _EMPTY_RETURN_STATE)])
    | (SINGLETON(pc_opt, rs),EMPTY) ->
       Some (ARRAY [(pc_opt,rs); (None, _EMPTY_RETURN_STATE)])
    | ((ARRAY _,_)|(_,ARRAY _)) -> assert false       
    | _ -> None

let mergeRoot a b rootIsWildcard =
  Tracelog.write
    (PredictionContext_ENTER_mergeRoot
       (to_mimick a,
        to_mimick b,
        rootIsWildcard)) ;
  let rv = _mergeRoot a b rootIsWildcard in
  Tracelog.write
    (PredictionContext_EXIT_mergeRoot (Option.map to_mimick rv)) ;
  rv

let unpack_SINGLETON = function
    SINGLETON(a,b) -> Some (a,b)
  | EMPTY -> Some(None, _EMPTY_RETURN_STATE)
  | _ -> None

let rec _mergeSingletons a b rootIsWildcard mergeCache =
  match (unpack_SINGLETON a,unpack_SINGLETON b) with
    Some (a_pc, a_returnState), Some (b_pc, b_returnState) -> begin
      let rv = match MC.maybe_get mergeCache a b with
          Some v -> CacheHit v
        | None ->
           (match mergeRoot a b rootIsWildcard with
              Some v -> Computed v
            | None -> Nothing)
      in
      match rv with
        (CacheHit pc) -> pc
      | (Computed pc) ->
         MC.maybe_cache mergeCache a b pc ; pc
      | Nothing ->
         if a_returnState = b_returnState then
           let parent = merge_opt a_pc b_pc rootIsWildcard mergeCache in
           if parent = a_pc then
             a
           else if parent = b_pc then
             b
           else
             let merged = SINGLETON(parent, a_returnState) in
             MC.maybe_cache mergeCache a b merged ;
             merged
         else
           let singleParent =
             if a = b || (a_pc <> None && a_pc = b_pc) then
               a_pc
             else None in
           match singleParent with
             Some _ ->
              let payloads =
                if a_returnState > b_returnState then
                  [ b_returnState; a_returnState ]
                else
                  [ a_returnState; b_returnState ] in
              let parents = [ singleParent ; singleParent ] in
              let merged = ARRAY (Std.combine parents payloads) in
              MC.maybe_cache mergeCache a b merged ;
              merged
           | None ->
              let (payloads,parents) =
                if a_returnState > b_returnState then
                  ([ b_returnState; a_returnState ],
                   [ b_pc ; a_pc ])
                else
                  ([ a_returnState; b_returnState ],
                   [ a_pc ; b_pc ]) in
              let merged = ARRAY(Std.combine parents payloads) in
              MC.maybe_cache mergeCache a b merged ;
              merged
    end
  | _ -> assert false

and mergeSingletons a b rootIsWildcard mergeCache =
  Tracelog.write
    (PredictionContext_ENTER_mergeSingletons
       (to_mimick a,
        to_mimick b,
        rootIsWildcard,
        Option.map MC.to_mimick mergeCache)) ;
  let rv = _mergeSingletons a b rootIsWildcard mergeCache in
  Tracelog.write
    (PredictionContext_EXIT_mergeSingletons (to_mimick rv, Option.map MC.to_mimick mergeCache)) ;
  rv

and do_mergeArrays al bl rootIsWildcard mergeCache =
  let merged_p_rs =
    let rec mrec acc al bl =
      match (al, bl) with
        [], [] -> List.rev acc
      | (ah::al), [] -> mrec (ah::acc) al []
      | [], (bh::bl) -> mrec (bh::acc) [] bl
      | (ah::al),(bh::bl) ->
         let (a_parent, a_returnState) = ah in
         let (b_parent, b_returnState) = bh in
         if a_returnState = b_returnState then
           let payload = a_returnState in
           let bothDollars =
             payload = _EMPTY_RETURN_STATE &&
               a_parent = None && b_parent = None in
           let ax_ax = a_parent <> None && b_parent <> None && a_parent = b_parent in
           if bothDollars || ax_ax then
             mrec ((a_parent, payload)::acc) al bl
           else
             let mergedParent = merge_opt a_parent b_parent rootIsWildcard mergeCache in
             mrec ((mergedParent, payload)::acc) al bl
         else if a_returnState < b_returnState then
           mrec (ah::acc) al (bh::bl)
         else
           mrec (bh::acc) (ah::al) bl in
    mrec [] al bl in
  if List.length merged_p_rs = 1 then
    SINGLETON (List.hd merged_p_rs)
  else ARRAY (combineCommonParents merged_p_rs)

and combineCommonParents p_rs =
  let ht = MHM.mk 23 in
  p_rs
  |> List.map
       (fun (p_opt, rs) ->
         match p_opt with
           None -> (None, rs)
         | Some p ->
            let p = match MHM.map ht p with
                p -> p
              | exception Not_found ->
                 MHM.add ht (p,p) ; p in
            (Some p, rs))

and _mergeArrays a b rootIsWildcard mergeCache =
  match (a,b) with
    ARRAY al, ARRAY bl -> begin
      let rv = MC.maybe_get mergeCache a b in
      match rv with
        Some v -> v
      | None ->
         let merged = do_mergeArrays al bl rootIsWildcard mergeCache in
         let merged =
           if merged = a then a
           else if merged = b then b
           else merged in
         MC.maybe_cache mergeCache a b merged ;
         merged
    end
  | _ -> assert false

and mergeArrays a b rootIsWildcard mergeCache =
  Tracelog.write
    (PredictionContext_ENTER_mergeArrays
       (to_mimick a,
        to_mimick b,
        rootIsWildcard,
        Option.map MC.to_mimick mergeCache)) ;
  let rv = _mergeArrays a b rootIsWildcard mergeCache in
  Tracelog.write
    (PredictionContext_EXIT_mergeArrays (to_mimick rv)) ;
  rv

and merge_opt a_opt b_opt rootIsWildcard mergeCache =
  let a = match a_opt with
      Some x -> x
    | None -> assert false in
  let b = match b_opt with
      Some x -> x
    | None -> assert false in
  Some (merge a b rootIsWildcard mergeCache)

and merge a b rootIsWildcard mergeCache =
  Tracelog.write
    (PredictionContext_ENTER_merge
       (to_mimick a,
        to_mimick b,
        rootIsWildcard,
        Option.map MC.to_mimick mergeCache)) ;
  let rv = _merge a b rootIsWildcard mergeCache in
  Tracelog.write
    (PredictionContext_EXIT_merge (to_mimick rv)) ;
  rv

and _merge a b rootIsWildcard mergeCache =
  if a = b then
    a
  else match (a,b) with
         ((SINGLETON _|EMPTY), (SINGLETON _|EMPTY)) ->
         mergeSingletons a b rootIsWildcard mergeCache
       | (EMPTY, _) when rootIsWildcard -> a
       | (_, EMPTY) when rootIsWildcard -> b
       | _ ->
          let a = match unpack_SINGLETON a with
              Some (parentCtx, returnState) ->
              ARRAY ([parentCtx, returnState])
            | _ -> a in
          let b = match unpack_SINGLETON b with
              Some (parentCtx, returnState) ->
              ARRAY ([parentCtx, returnState])
            | _ -> b in
          mergeArrays a b rootIsWildcard mergeCache

end
module PredictionContext = PC

module SC = struct
type t =
  EMPTY
| PREDICATE of {
    ruleIndex : int
  ; predIndex : int
  ; isCtxDependent : bool
  }
| PRECEDENCE of int
| AND of t list
| OR of t list

let mkPredicate ?(ruleIndex= -1) ?(predIndex= -1) ?(isCtxDependent = false) () =
  PREDICATE { ruleIndex ; predIndex ; isCtxDependent }

let mkPrecedence ?(precedence = 0) () = PRECEDENCE precedence

let rec or_operands = function
    OR l -> List.concat_map or_operands l
  | x -> [x]

let mkOR a b =
  match (a,b) with
    (None, None) -> failwith "SC.mkOR: both are None"
  | (None, Some b) -> b
  | (Some a, None) -> a
  | (Some a, Some b) ->
     match (a,b) with
       (EMPTY, _)|(_, EMPTY) -> EMPTY
       | _ ->
          let operands = (or_operands a)@(or_operands b) in
          let precedencePredicates = List.filter_map (function (PRECEDENCE _) as x -> Some x | _ -> None) operands in
          let operands =
            if [] <> precedencePredicates then
              operands @ [Std.last (List.stable_sort Stdlib.compare precedencePredicates)]
            else operands in
          OR operands

let rec and_operands = function
    AND l -> List.concat_map and_operands l
  | x -> [x]

let mkAND a b =
  match (a,b) with
    (None, None) -> failwith "SC.mkAND: both are None"
  | (None, Some b) -> b
  | (Some a, None) -> a
  | (Some a, Some b) ->
     match (a,b) with
       (EMPTY, _)|(_, EMPTY) -> EMPTY
       | _ ->
          let operands = (and_operands a)@(and_operands b) in
          let precedencePredicates = List.filter_map (function (PRECEDENCE _) as x -> Some x | _ -> None) operands in
          let operands =
            if [] <> precedencePredicates then
              operands @ [List.hd (List.stable_sort Stdlib.compare precedencePredicates)]
            else operands in
          AND operands

let rec to_mimick = function
    EMPTY -> M.SC_EMPTY
  | PREDICATE { ruleIndex ; predIndex ; isCtxDependent } ->
     SC_PREDICATE { ruleIndex ; predIndex ; isCtxDependent }
  | PRECEDENCE precedence -> SC_PRECEDENCE { precedence }
  | AND l -> SC_AND { opnds = List.map to_mimick l }
  | OR l -> SC_OR { opnds = List.map to_mimick l }

let rec of_mimick = function
    M.SC_EMPTY -> EMPTY
  | SC_PREDICATE { ruleIndex ; predIndex ; isCtxDependent } ->
     PREDICATE { ruleIndex ; predIndex ; isCtxDependent }
  | SC_PRECEDENCE { precedence } -> PRECEDENCE precedence
  | SC_AND { opnds } -> AND (List.map of_mimick opnds)
  | SC_OR { opnds } -> OR (List.map of_mimick opnds)

end
module SemanticContext = SC

module AC = struct
type t = {
    state : M.deser_state_id
  ; alt : int
  ; mutable context : PC.t option
  ; semanticContext : SC.t
  ; mutable reachesIntoOuterContext : int
  ; mutable precedenceFilterSuppressed : bool
  }

let hash t =
  Hashtbl.hash (t.state, t.alt, t.context, t.semanticContext)

let real_eq t1 t2 =
  t1 == t2 ||
    (t1.state = t2.state
     && t1.alt = t2.alt
     && t1.context = t2.context
     && t1.semanticContext = t2.semanticContext
    && t1.precedenceFilterSuppressed = t2.precedenceFilterSuppressed)

let hash_for_config_set t =
  Hashtbl.hash (t.state, t.alt, t.semanticContext)

let eq_for_config_set t1 t2 =
  t1 == t2 ||
    (t1.state = t2.state
     && t1.alt = t2.alt
     && t1.semanticContext = t2.semanticContext)

let _init state_opt alt_opt context_opt semantic_opt config_opt =
  let state = match (state_opt, config_opt) with
      (Some st, _) -> st
    | (None, Some c) -> c.state
    | _ -> failwith "AC.init: no state specified" in
  let alt = match (alt_opt, config_opt) with
      (Some alt,  _) -> alt
    | (None, Some c) -> c.alt
    | _ -> failwith "AC.init: no alt specified" in
  let context = match (context_opt, config_opt) with
      (Some _, _) -> context_opt
    | (None, Some c) -> c.context
    | _ -> None in
  let semantic = match (semantic_opt, config_opt) with
      (Some sc, _) -> sc
    | (None, Some c) -> c.semanticContext
    | _ -> SC.EMPTY in
  {
    state
  ; alt
  ; context
  ; semanticContext = semantic
  ; reachesIntoOuterContext = (match config_opt with None -> 0 | Some c -> c.reachesIntoOuterContext)
  ; precedenceFilterSuppressed = (match config_opt with None -> false | Some c -> c.precedenceFilterSuppressed)
  }

let to_mimick t =
  M.ATNConfig {
      state = t.state
    ; alt = t.alt
    ; context = Option.map PC.to_mimick t.context
    ; semanticContext = SC.to_mimick t.semanticContext
    ; reachesIntoOuterContext = t.reachesIntoOuterContext
    ; precedenceFilterSuppressed = t.precedenceFilterSuppressed
  }

let of_mimick t = match t with
    M.ATNConfig t ->
  {
    state = t.state
  ; alt = t.alt
  ; context = Option.map PC.of_mimick t.context
  ; semanticContext = SC.of_mimick t.semanticContext
  ; reachesIntoOuterContext = t.reachesIntoOuterContext
  ; precedenceFilterSuppressed = t.precedenceFilterSuppressed
  }

let init state_opt alt_opt context_opt semantic_opt config_opt =
  Tracelog.write
    (ATNConfig_ENTER_init (state_opt, alt_opt, (Option.map PC.to_mimick context_opt), (Option.map SC.to_mimick semantic_opt), (Option.map to_mimick config_opt))) ;
  let rv = _init state_opt alt_opt context_opt semantic_opt config_opt in
  Tracelog.write (ATNConfig_EXIT_init (to_mimick rv)) ;
  rv

end
module ATNConfig = AC


module ACS = struct

module H = struct
  type t = AC.t
  let equal = AC.eq_for_config_set
  let hash = AC.hash_for_config_set
end

module HT = Hashtbl.Make(H)

type t = {
    fullCtx : bool
  ; configHT : AC.t HT.t
  ; configs : AC.t list ref
  ; mutable readonly : bool
  ; uniqueAlt : int
  ; conflictingAlts : int list option
  ; mutable hasSemanticContext : bool
  ; mutable dipsIntoOuterContext : bool
  ; id : int
  }

let ht_toList t =
  HT.fold (fun k v acc -> (k,v)::acc) t []

let ht_ofList l =
  let ht = HT.create 23 in
  l |> List.iter (fun (k,v) -> HT.add ht k v) ;
  ht

let of_mimick t =
  let configs = List.map (fun (_, c) -> AC.of_mimick c) t.M.configs in
  {
    fullCtx = t.M.fullCtx
  ; configHT = ht_ofList (List.map (fun c -> (c,c)) configs)
  ; configs = ref configs
  ; readonly = t.readonly
  ; uniqueAlt = t.uniqueAlt
  ; conflictingAlts = t.conflictingAlts
  ; hasSemanticContext = t.hasSemanticContext
  ; dipsIntoOuterContext = t.dipsIntoOuterContext
  ; id = t.id
  }

let to_mimick t =
  {
    M.fullCtx = t.fullCtx
  ; configs = List.map (fun c -> ("", AC.to_mimick c)) !(t.configs)
  ; readonly = t.readonly
  ; uniqueAlt = 0
  ; conflictingAlts = t.conflictingAlts
  ; hasSemanticContext = t.hasSemanticContext
  ; dipsIntoOuterContext = t.dipsIntoOuterContext
  ; id = t.id
  }

let get_or_add t c =
  match HT.find_opt t.configHT c  with
    Some c' -> c'
  | None ->
     HT.add t.configHT c c ;
     c

let _add ?mergeCache t c =
  if t.readonly then
    failwith "ATNConfigSet.add: This set is readonly" ;
  if c.AC.semanticContext <> SC.EMPTY then
    t.hasSemanticContext <- true ;
  if c.AC.reachesIntoOuterContext > 0 then
    t.dipsIntoOuterContext <- true ;
  let existing = get_or_add t c in
  if existing == c then begin
      Std.push t.configs c ;
      true
    end
  else begin
      let rootIsWildcard = not t.fullCtx in
      assert (existing.context <> None) ;
      assert (c.context <> None) ;
      let merged = PC.merge (Std.outSome existing.context) (Std.outSome c.context) rootIsWildcard mergeCache in
      existing.reachesIntoOuterContext <- max existing.reachesIntoOuterContext c.reachesIntoOuterContext ;
      if c.precedenceFilterSuppressed then
        existing.precedenceFilterSuppressed <- true ;
      existing.context <- Some merged ;
      true
    end

let add ?mergeCache t c =
  Tracelog.write
    (ATNConfigSet_ENTER_add (to_mimick t, AC.to_mimick c, Option.map PC.MC.to_mimick mergeCache)) ;
  let rv = _add ?mergeCache t c in
  Tracelog.write
    (ATNConfigSet_EXIT_add (to_mimick t, rv)) ;
  rv

end
module ATNConfigSet = ACS

