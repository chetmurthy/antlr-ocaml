(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.utils,pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.yojson,pa_ppx.deriving_plugins.located_yojson,pa_ppx.import *)

open Pa_ppx_utils
open Util
open Atn

module M = Mimick

module PC = struct
open Coll

type pc_t =
  EMPTY
| SINGLETON of (pc_t option * int)
| ARRAY of (pc_t option * int) list

type t = pc_t

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
  let add t (a,b) v =
    MHM.add t ((a,b), v)
  let toList t = MHM.toList t

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

end
module MergeCache = MC

let _EMPTY_RETURN_STATE = 0x7FFFFFFF
type interim_t =
  CacheHit of pc_t
| Computed of pc_t
| Nothing

let mergeRoot a b rootIsWildcard =
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

let rec mergeSingletons a b rootIsWildcard mergeCache =
  match (a,b) with
    SINGLETON (a_pc, a_returnState), SINGLETON (b_pc, b_returnState) -> begin
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

and mergeArrays a b rootIsWildcard mergeCache =
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

and merge_opt a_opt b_opt rootIsWildcard mergeCache =
  let a = match a_opt with
      Some x -> x
    | None -> assert false in
  let b = match b_opt with
      Some x -> x
    | None -> assert false in
  Some (merge a b rootIsWildcard mergeCache)

and merge a b rootIsWildcard mergeCache =
  if a = b then
    a
  else match (a,b) with
         (SINGLETON _, SINGLETON _) ->
         mergeSingletons a b rootIsWildcard mergeCache
       | (EMPTY, _) when rootIsWildcard -> a
       | (_, EMPTY) when rootIsWildcard -> b
       | _ ->
          let a = match a with
              SINGLETON (parentCtx, returnState) ->
              ARRAY ([parentCtx, returnState])
            | _ -> a in
          let b = match a with
              SINGLETON (parentCtx, returnState) ->
              ARRAY ([parentCtx, returnState])
            | _ -> b in
          mergeArrays a b rootIsWildcard mergeCache

end
module PredictionContext = PC

module SC = struct
type t = unit
end
module SemanticContext = SC

module AC = struct
type t = {
    state : M.deser_state_id
  ; alt : int
  ; context : PC.t option
  ; semanticContext : SC.t option
  ; reachesIntoOuterContext : int
  ; precedenceFilterSuppressed : bool
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

end
module AtnConfig = AC


module ACS = struct

module H = struct
  type t = AC.t
  let equal = AC.eq_for_config_set
  let hash = AC.hash_for_config_set
end

module HT = Hashtbl.Make(H)

type t = {
    fullCtx : bool
  ;  configHT : AC.t HT.t
  ; configs : AC.t list ref
  ; mutable readonly : bool
  ; conflictingAlts : int list option
  ; mutable hasSemanticContext : bool
  ; mutable dipsIntoOuterContext : bool
  ; id : int
  }

let get_or_add t c =
  match HT.find_opt t.configHT c  with
    Some c' -> c'
  | None ->
     HT.add t.configHT c c ;
     c

let add ?mergeCache t c =
  if t.readonly then
    failwith "AtnConfigSet.add: This set is readonly" ;
  if c.AC.semanticContext <> None then
    t.hasSemanticContext <- true ;
  if c.AC.reachesIntoOuterContext > 0 then
    t.dipsIntoOuterContext <- true ;
  let existing = get_or_add t c in
  if existing == c then
    Std.push t.configs c ;
  


end
module AtnConfigSet = ACS

