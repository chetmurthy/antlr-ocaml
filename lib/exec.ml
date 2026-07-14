(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.utils,pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.yojson,pa_ppx.deriving_plugins.located_yojson,pa_ppx.import *)

open Pa_ppx_base
open Ppxutil
open Pa_ppx_utils
open Util
open Atn


module Token = struct
  let _INVALID_TYPE = 0
  let  _EPSILON = -2
  let _MIN_USER_TOKEN_TYPE = 1
  let _EOF = -1
  let _DEFAULT_CHANNEL = 0
  let _HIDDEN_CHANNEL = 1
end


module Counter(M: sig val name : string end) = struct
  let it = ref 0
  let check predicted =
    match predicted with
      None -> ()
    | Some n ->
     if n <> !it then
       Fmt.(failwithf "%s: predicted/actual id mismatch: %d <> %d@."
              M.name n !it)

  let get () = !it
  let get_incr () =
    let n = !it in
    incr it ;
    n
end

open Coll
module type CACHEABLE = sig
  type t
  val id : t -> int
  val equal : t -> t -> bool
  val pp : t Fmt.t
  val name : string
end
module type CACHE = sig
  module C : CACHEABLE
  type t
  val mk : ?do_recache:bool -> unit -> t
  val recache : t -> C.t -> C.t
  val remap : t -> C.t -> unit
  val add : t -> C.t -> unit
  val upsert : t -> C.t -> C.t
  val get : t -> int -> C.t
end
module Cacher(C : CACHEABLE): (CACHE with module C = C) = struct
module C = C
type t = {
    do_recache : bool
  ; cache : (int, C.t) MHM.t
  }
let mk ?(do_recache = true) () =
  {
    do_recache
  ; cache = MHM.mk 23
  }

let add cache t =
  let tid = C.id t in
  if MHM.in_dom cache.cache tid then
    Fmt.(failwithf "%s: value already exists for id=%d" C.name tid) ;
  MHM.add cache.cache (tid, t)

let remap cache t =
  let id = C.id t in
  MHM.remap cache.cache id t

let get cache id = MHM.map cache.cache id

let recache cache t =
  let tid = C.id t in
  if MHM.in_dom cache.cache tid then
    let t' = MHM.map cache.cache tid in
    if not (C.equal t t') then begin
      Fmt.(pf stderr "%s: id=%d: cached value was different from demarshalled one.@.cached:@.%a@.demarshalled:@.%a@."
           C.name
             tid
             C.pp t'
             C.pp t) ;
      Fmt.(failwithf "%s: cached value was different from demarshalled one" C.name)
      end ;
    t'
    else if cache.do_recache then
      begin
        Fmt.(pf stderr "%s: no cached value for id=%d; demarshalled value was@.%a@."
               C.name tid C.pp t) ;
        Fmt.(failwithf "%s: no cached value for demarshalled value with id=%d" C.name tid)
      end
    else t

let upsert cache t =
  let tid = C.id t in
  if MHM.in_dom cache.cache tid then
    recache cache t
  else
    (MHM.add cache.cache (tid, t) ; t)

end

module M = Mimick

module Atns = struct
type t = { lexer : Atn.t ; _parser : Atn.t option }

let read_atn ~grammarType file =
  let atn = 
    file
    |> Fpath.v
    |>  Bos.OS.File.read
    |> Result.get_ok
    |> Interp_syntax.read_raw
    |> Atn.deser ~verify:true in
  if atn.Atn.grammarType <> grammarType then
    Fmt.(failwithf "%s: ATN was supposed to be %a but was %a@."
           file Atn.pp_atn_type_t atn.Atn.grammarType Atn.pp_atn_type_t grammarType) ;
  Fmt.(pf stderr "ATN %s: 0x%08x@." file (Hashtbl.hash atn)) ;
  atn

let load ~lexer_atn ~parser_atn =
  { lexer = read_atn ~grammarType:Atn.LEXER lexer_atn
  ; _parser = Option.map (read_atn ~grammarType:Atn.PARSER) parser_atn
  }

let for_grammar atns grammarType =
  match (grammarType, atns) with
    (LEXER, { lexer }) -> lexer
  | (PARSER, { _parser = Some atn }) -> atn
  | _ -> failwith "must supply parser ATN for a parser DFA"
end
module PC = struct
let _EMPTY_RETURN_STATE = 0x7FFFFFFF

open Coll

type pc_t =
  EMPTY
| SINGLETON of (pc_t option * int)
| ARRAY of (pc_t option * int) list
[@@deriving show, eq]
type t = pc_t
[@@deriving show, eq]

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
  type list_t = ((pc_t * pc_t) * pc_t) list
[@@deriving show]

  type t = ((pc_t * pc_t), pc_t) MHM.t

  let pp pps t =
    let l = MHM.toList t in
    pp_list_t pps l

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
[@@deriving show]

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
[@@deriving show, eq]

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

let toString sc =
  let rec pprec pps = function
    EMPTY -> Fmt.(pf pps "{empty}")
  | PREDICATE { ruleIndex ; predIndex ; isCtxDependent } ->
     Fmt.(pf pps "{%d:%d}?" ruleIndex predIndex)
  | PRECEDENCE n -> Fmt.(pf pps "{%d>=prec}?" n)
  | AND l -> Fmt.(pf pps "%a" (list ~sep:(const string "&&") pprec) l)
  | OR l -> Fmt.(pf pps "%a" (list ~sep:(const string "||") pprec) l)
  in Fmt.(str "%a" pprec sc)

end
module SemanticContext = SC

module LA = struct
  type t = [%import: Types.lexer_action_t
            [@with lexer_action_t := t]
           ]
[@@deriving yojson,located_yojson, show, eq]

let pp_hum pps t = Fmt.(pf pps "%s" (Atn.LexerAction.toString t))
end
module LexerAction = LA

module LAE = struct
  type t = [%import: Mimick.lexer_action_executor_t
            [@with Atn.LexerAction.t := LA.t]
           ]
[@@deriving yojson,located_yojson, show, eq]

let pp_hum pps t = Fmt.(pf pps "%a" (list ~sep:(const string ":") LA.pp_hum) t.lexerActions)
let toString t = Fmt.(str "%a" pp_hum t)
end
module LexerActionExecutor = LAE

module AC = struct
let disable_builtin_equality (x: int) = x
type ac_t = {
    disable_builtin_equality : int -> int
    [@printer (fun pps _ -> Fmt.(pf pps "_"))]
    [@equal fun x y -> true]
  ; atn : Atn.t
    [@printer (fun pps x -> Fmt.(pf pps "<atn 0x%08x>" (Hashtbl.hash x)))]
    [@equal (fun x y -> x==y)]
  ; id : int
  ; state : M.deser_state_id
  ; alt : int
  ; mutable context : PC.t option
  ; semanticContext : SC.t
  ; mutable reachesIntoOuterContext : int
  ; mutable precedenceFilterSuppressed : bool
  ; lexer_ext : lexer_ext_t option
  }
and lexer_ext_t = {
    lexerActionExecutor : LAE.t option
  ; passedThroughNonGreedyDecision : bool
  }
[@@deriving show, eq]
type t = ac_t
[@@deriving show, eq]

let hashkey c =
  match c.lexer_ext with
    None ->
    Fmt.(str "%a/%d/%s"
           Atn.dump_state_id c.state
           c.alt
           (SC.toString c.semanticContext))
  | Some ext ->
    Fmt.(str "%a/%d/%s/%s/%s/%s"
           Atn.dump_state_id c.state
           c.alt
           (Option.fold ~none:"None" ~some:PC.toString c.context)
           (SC.toString c.semanticContext)
           (if ext.passedThroughNonGreedyDecision then "True" else "False")
           (Option.fold ~none:"None" ~some:LAE.toString ext.lexerActionExecutor)
           

)

let strkey c =
  match c.lexer_ext with
    None ->
    Fmt.(str "%s/%s"
           (hashkey c)
           (Option.fold ~none:"None" ~some:PC.toString c.context))
  | Some _ -> hashkey c

let to_mimick t =
  match t.lexer_ext with
    None ->
    M.ATNConfig {
        state = t.state
      ; id = t.id
      ; alt = t.alt
      ; context = Option.map PC.to_mimick t.context
      ; semanticContext = SC.to_mimick t.semanticContext
      ; reachesIntoOuterContext = t.reachesIntoOuterContext
      ; precedenceFilterSuppressed = t.precedenceFilterSuppressed
      }
  | Some x ->
     M.LexerATNConfig {
        state = t.state
      ; id = t.id
      ; alt = t.alt
      ; context = Option.map PC.to_mimick t.context
      ; semanticContext = SC.to_mimick t.semanticContext
      ; reachesIntoOuterContext = t.reachesIntoOuterContext
      ; precedenceFilterSuppressed = t.precedenceFilterSuppressed
      ; lexerActionExecutor = x.lexerActionExecutor
      ; passedThroughNonGreedyDecision = x.passedThroughNonGreedyDecision
      }

let _of_mimick atns t = match (atns,t) with
    (Atns.{_parser=Some atn}, M.ATNConfig t) ->
     {
       disable_builtin_equality
     ; atn
     ; id = t.id
     ; state = t.state
     ; alt = t.alt
     ; context = Option.map PC.of_mimick t.context
     ; semanticContext = SC.of_mimick t.semanticContext
     ; reachesIntoOuterContext = t.reachesIntoOuterContext
     ; precedenceFilterSuppressed = t.precedenceFilterSuppressed
     ; lexer_ext = None
     }
  | ({lexer=atn}, M.LexerATNConfig t) ->
     {
       disable_builtin_equality
     ; atn
     ; id = t.id
     ; state = t.state
     ; alt = t.alt
     ; context = Option.map PC.of_mimick t.context
     ; semanticContext = SC.of_mimick t.semanticContext
     ; reachesIntoOuterContext = t.reachesIntoOuterContext
     ; precedenceFilterSuppressed = t.precedenceFilterSuppressed
     ; lexer_ext =
         Some {
             lexerActionExecutor = t.lexerActionExecutor
           ; passedThroughNonGreedyDecision = t.passedThroughNonGreedyDecision
           }
     }

open Coll
module Cache = Cacher(struct
                   type t  = ac_t
                   let id t = t.id
                   let equal = equal_ac_t
                   let pp = pp_ac_t
                   let name = "ATNConfig"
                 end)

let of_mimick ~ac_cache atns t =
  let t = _of_mimick atns t in
  match ac_cache with
    None -> t
  | Some ac_cache -> Cache.recache ac_cache t

let hash t =
  Hashtbl.hash (t.state, t.alt, t.context, t.semanticContext, t.lexer_ext)

let rec real_eq t1 t2 =
  match (t1,t2) with
    ({ lexer_ext = None }, { lexer_ext = None }) ->
  t1 == t2 ||
    (t1.state = t2.state
     && t1.alt = t2.alt
     && t1.context = t2.context
     && t1.semanticContext = t2.semanticContext
     && t1.precedenceFilterSuppressed = t2.precedenceFilterSuppressed
     && t1.lexer_ext = t2.lexer_ext
    )
  | ({ lexer_ext = Some ext1 }, { lexer_ext = Some ext2 }) ->
     ext1 = ext2 && real_eq {(t1) with lexer_ext=None} {(t2) with lexer_ext=None}

  | _ -> assert false

let __eq__ t1 t2 =
  (match t1.lexer_ext with
     None ->
     Tracelog.write (ATNConfig_ENTER_eq (to_mimick t1, to_mimick t2))
   | Some _ ->
     Tracelog.write (LexerATNConfig_ENTER_eq (to_mimick t1, to_mimick t2))) ;
  let rv = real_eq t1 t2 in
  (match t1.lexer_ext with
     None ->
     Tracelog.write (ATNConfig_EXIT_eq (rv))
   | Some _ ->
     Tracelog.write (LexerATNConfig_EXIT_eq (rv))) ;
  rv

let hash_for_config_set t =
(*
  Hashtbl.hash (t.state, t.alt, t.semanticContext)
*)
  hashkey t

let _eq_for_config_set t1 t2 =
  match (t1, t2) with
    ({ lexer_ext = None }, { lexer_ext = None }) ->
  t1 == t2 ||
    (t1.state = t2.state
     && t1.alt = t2.alt
     && t1.semanticContext = t2.semanticContext)
  | ({ lexer_ext = Some _ }, { lexer_ext = Some _ }) ->
     __eq__ t1 t2
  | _ -> assert false

let eq_for_config_set t1 t2 =
  let rv = _eq_for_config_set t1 t2 in
(*
  Tracelog.write (ATNConfig_equalsForConfigSet(to_mimick t1, to_mimick t2, rv)) ;
 *)
  rv

module ConfigCounter = Counter(struct let name = "ATNConfig" end)

let _ATNConfig_init ?predicted_id atn state_opt alt_opt context_opt semantic_opt config_opt =
  ConfigCounter.check predicted_id;
  let id = ConfigCounter.get_incr() in
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
    disable_builtin_equality
  ; atn
  ; id
  ; state
  ; alt
  ; context
  ; semanticContext = semantic
  ; reachesIntoOuterContext = (match config_opt with None -> 0 | Some c -> c.reachesIntoOuterContext)
  ; precedenceFilterSuppressed = (match config_opt with None -> false | Some c -> c.precedenceFilterSuppressed)
  ; lexer_ext = None
  }

let checkNonGreedyDecision atn lexer_ext target =
      lexer_ext.passedThroughNonGreedyDecision
    || (match Atn.State.isDecisionState Atn.(State.get_state atn.states target) with
          None -> false
        | Some (_, nonGreedy) -> nonGreedy)


let init_ATNConfig ?predicted_id atn state_opt alt_opt context_opt semantic_opt config_opt : t =
  ConfigCounter.check predicted_id ;
  Tracelog.write
    (ATNConfig_ENTER_init (ConfigCounter.get(), state_opt, alt_opt, (Option.map PC.to_mimick context_opt), (Option.map SC.to_mimick semantic_opt), (Option.map to_mimick config_opt))) ;
  let rv = _ATNConfig_init atn state_opt alt_opt context_opt semantic_opt config_opt in
  Tracelog.write (ATNConfig_EXIT_init (to_mimick rv)) ;
  rv

let _LexerATNConfig_init atn state_opt alt_opt context_opt semantic_opt config_opt lexerActionExecutor_opt =
  let t = init_ATNConfig atn state_opt alt_opt context_opt semantic_opt config_opt in
  let config_lexer_ext = match config_opt with
      None -> None
    | Some { lexer_ext = Some e } -> Some e
    | Some _ -> failwith "internal error: _LexerATNConfig_init: config_opt wasn't a LexerATNConfig" in
  let lexerActionExecutor =
    match (config_lexer_ext, lexerActionExecutor_opt) with
      (Some ext, None) -> ext.lexerActionExecutor
    | (_, x) -> x in
  { (t) with
    lexer_ext =
      Some {
          lexerActionExecutor
        ; passedThroughNonGreedyDecision =
            match config_lexer_ext with
              None -> false
            | Some ext -> checkNonGreedyDecision atn ext t.state
        }
  }

let init_LexerATNConfig atn state_opt alt_opt context_opt semantic_opt config_opt lexerActionExecutor_opt : t =
  Tracelog.write
    (LexerATNConfig_ENTER_init (state_opt, alt_opt, (Option.map PC.to_mimick context_opt), (Option.map SC.to_mimick semantic_opt), lexerActionExecutor_opt, (Option.map to_mimick config_opt))) ;
  let rv = _LexerATNConfig_init atn state_opt alt_opt context_opt semantic_opt config_opt lexerActionExecutor_opt in
  Tracelog.write (LexerATNConfig_EXIT_init (to_mimick rv)) ;
  rv

let recache ~ac_cache c =
  Cache.upsert ac_cache c

end
module ATNConfig = AC


module ACS = struct
open Coll

let configHT_equal ht1 ht2 =
  match (ht1, ht2) with
    (None, None) -> true
  | ((Some _, None)|(None, Some _)) -> false
  | (Some ht1, Some ht2) ->
     let l1 = List.stable_sort Stdlib.compare (MHM.toList ht1) in
     let l2 = List.stable_sort Stdlib.compare (MHM.toList ht2) in
     List.length l1 = List.length l2 &&
     List.for_all2 [%eq: string * (AC.t list ref)] l1 l2

type acs_t = {
    fullCtx : bool
  ; mutable configHT : (string, AC.t list ref) MHM.t option
    [@printer (fun pps _ -> Fmt.(pf pps "<configHT>"))]
    [@equal configHT_equal]
  ; configs : AC.t list ref
  ; mutable readonly : bool
  ; mutable uniqueAlt : int
  ; mutable conflictingAlts : int list option
  ; mutable hasSemanticContext : bool
  ; mutable dipsIntoOuterContext : bool
  ; id : int
  }
[@@deriving show, eq]
type t = acs_t
[@@deriving show, eq]

module Cache = Cacher(struct
                   type t  = acs_t
                   let id t = t.id
                   let equal = equal_acs_t
                   let pp = pp_acs_t
                   let name = "ATNConfigSet"
                 end)

let real__eq__ t1 t2 =
  t1==t2 ||
    (List.length !(t1.configs) = List.length !(t2.configs)
     && List.for_all2 AC.__eq__ !(t1.configs) !(t2.configs)
     && t1.fullCtx = t2.fullCtx
     && t1.uniqueAlt = t2.uniqueAlt
     && t1.conflictingAlts = t2.conflictingAlts
     && t1.hasSemanticContext = t2.hasSemanticContext
     && t1.dipsIntoOuterContext = t2.dipsIntoOuterContext)

let hash t =
  List.fold_left (fun n c -> Hashtbl.hash((n, AC.hash c))) 0 !(t.configs)

let _of_mimick ~ac_cache atns t =
  {
    fullCtx = t.M.fullCtx
  ; configHT =
      t.M.configHT
      |> Option.map (fun ht ->
             (MHM.ofList 23 (List.map (fun (h,l) ->
                                      let l = List.map snd l in
                                      let l = (List.map (AC.of_mimick ~ac_cache atns) l) in
                                      (h, ref l)) ht)))
  ; configs = ref (List.map (fun (_, c) -> AC.of_mimick ~ac_cache atns c) t.M.configs)
  ; readonly = t.readonly
  ; uniqueAlt = t.uniqueAlt
  ; conflictingAlts = t.conflictingAlts
  ; hasSemanticContext = t.hasSemanticContext
  ; dipsIntoOuterContext = t.dipsIntoOuterContext
  ; id = t.id
  }

let of_mimick ~acs_cache ~ac_cache atns t =
  let t = _of_mimick ~ac_cache atns t in
  match acs_cache with
    None -> t
  | Some acs_cache -> Cache.recache acs_cache t

let to_mimick t =
  {
    M.fullCtx = t.fullCtx
  ; configs = List.map (fun c -> (AC.strkey c, AC.to_mimick c)) !(t.configs)
  ; configHT =
      t.configHT
      |> Option.map (fun ht ->
 List.stable_sort Stdlib.compare (List.map (fun (h,l) -> (h,List.map (fun c -> (AC.strkey c, AC.to_mimick c)) !l)) (MHM.toList ht)))
  ; readonly = t.readonly
  ; uniqueAlt = t.uniqueAlt
  ; conflictingAlts = t.conflictingAlts
  ; hasSemanticContext = t.hasSemanticContext
  ; dipsIntoOuterContext = t.dipsIntoOuterContext
  ; id = t.id
  }

let __eq__ t1 t2 =
  Tracelog.write(ATNConfigSet_ENTER_eq(to_mimick t1, to_mimick t2)) ;
  let rv = real__eq__ t1 t2 in
  Tracelog.write(ATNConfigSet_EXIT_eq rv) ;
  rv

module ConfigSetCounter = Counter(struct let name = "ATNConfigSet" end)

let _init ?id fullCtx =
  ConfigSetCounter.check id ;
  let id = ConfigSetCounter.get_incr () in
  {
    id
  ; configs = ref []
  ; configHT = Some (MHM.mk 23)
  ; fullCtx
  ; readonly = false
  ; uniqueAlt = 0
  ; conflictingAlts = None
  ; hasSemanticContext = false
  ; dipsIntoOuterContext = false
  }

let init ?id ?(fullCtx = true) () =
  ConfigSetCounter.check id ;
  Tracelog.write (ATNConfigSet_ENTER_init (ConfigSetCounter.get (), fullCtx));
  let rv = _init ?id fullCtx in
  Tracelog.write (ATNConfigSet_EXIT_init (to_mimick rv));
  rv

let in_configs t c =
  List.exists (fun c' -> c' == c) !(t.configs)

let in_configs' t c =
  List.exists (fun c' -> c'.AC.id == c.AC.id) !(t.configs)

let _get_or_add t c =
  assert (not t.readonly) ;
  assert (Std.isSome t.configHT) ;
  let configHT = Std.outSome t.configHT in
  let h = AC.hash_for_config_set c in
  let l = match MHM.map configHT h  with
    l -> l
  | exception Not_found ->
     let l = ref [] in
     MHM.add configHT (h, l) ;
     l in
  match List.find_opt (fun c' -> AC.eq_for_config_set c c') !l with
    Some c -> c
  | None ->
     l := !l @ [c] ;
     c

let get_or_add t c =
  Tracelog.write
    (ATNConfigSet_ENTER_getOrAdd(to_mimick t,AC.to_mimick c)) ;
  let rv = _get_or_add t c in
  Tracelog.write
    (ATNConfigSet_EXIT_getOrAdd(to_mimick t,AC.to_mimick rv)) ;
  assert (rv.id == c.id || in_configs' t rv) ;
  rv

let _add ?mergeCache t c =
  if t.readonly then
    failwith "ATNConfigSet.add: This set is readonly" ;
  if c.AC.semanticContext <> SC.EMPTY then
    t.hasSemanticContext <- true ;
  if c.AC.reachesIntoOuterContext > 0 then
    t.dipsIntoOuterContext <- true ;
  let existing = get_or_add t c in
  if existing == c then begin
      t.configs := !(t.configs) @ [c] ;
      true
    end
  else begin
      let rootIsWildcard = not t.fullCtx in
      assert (in_configs' t existing) ;
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

let recache ~acs_cache ~ac_cache cs =
  !(cs.configs) |> List.iter (fun c -> AC.recache ~ac_cache c ; ()) ;
  Cache.upsert acs_cache cs

let update_HSC cs v =
  Tracelog.write (ATNConfigSet_ENTER_update_HSC (to_mimick cs, v)) ;
  cs.hasSemanticContext <- v ;
  Tracelog.write (ATNConfigSet_EXIT_update_HSC (to_mimick cs))

end
module ATNConfigSet = ACS

module ACSMap =
  Hashtbl.Make(
      struct
        type t = ACS.t
        let equal = ACS.__eq__
        let hash = ACS.hash
      end
    )



module PP = struct
type t = (int * SC.t)
[@@deriving show, eq]

let to_mimick (alt, sc) =
  M.PredPrediction {alt;pred=SC.to_mimick sc}

let of_mimick = function
    M.PredPrediction{alt;pred} -> (alt, SC.of_mimick pred)

end
module PredPrediction = PP

module DFASt = struct

type dfa_state_t = {
    id : int
  ; mutable stateNumber : int
  ; mutable configset : ACS.t
  ; mutable edges : int array
  ; mutable isAcceptState : bool
  ; mutable prediction : int
  ; mutable lexerActionExecutor : LAE.t option
  ; mutable requiresFullContext : bool
  ; mutable predicates : PP.t list option
  }
[@@deriving show, eq]
type t = dfa_state_t
[@@deriving show, eq]

module Cache = Cacher(struct
                   type t  = dfa_state_t
                   let id t = t.id
                   let equal = equal_dfa_state_t
                   let pp = pp_dfa_state_t
                   let name = "DFAState"
                 end)


let to_mimick t =
  {
      M.id = t.id
    ; stateNumber = t.stateNumber
    ; configset = ACS.to_mimick t.configset
    ; edges = Array.map (fun n -> if n = Int.min_int then None else Some n) t.edges
    ; isAcceptState = t.isAcceptState
    ; prediction = t.prediction
    ; lexerActionExecutor = t.lexerActionExecutor
    ; requiresFullContext = t.requiresFullContext
    ; predicates = Option.map (List.map PP.to_mimick) t.predicates
  }

let _of_mimick ~acs_cache ~ac_cache atns t =
  {
    id = t.M.id
  ; stateNumber =
      t.M.stateNumber
  ; configset = ACS.of_mimick ~acs_cache ~ac_cache atns t.M.configset
  ; edges = Array.map (function None -> Int.min_int | Some n -> n) t.M.edges
  ; isAcceptState = t.M.isAcceptState
  ; prediction = t.prediction
  ; lexerActionExecutor = t.lexerActionExecutor
  ; requiresFullContext = t.requiresFullContext
  ; predicates = t.predicates |> Option.map (List.map PP.of_mimick)
  }

let of_mimick ~dfast_cache ~acs_cache ~ac_cache atns t =
  let t = _of_mimick ~acs_cache ~ac_cache atns t in
  match dfast_cache with
    None -> t
  | Some dfast_cache -> Cache.recache dfast_cache t

module DFAStCounter = Counter(struct let name = "DFAState" end)

let _init ?predicted_id stateNumber configs =
  DFAStCounter.check predicted_id ;
  let id = DFAStCounter.get_incr () in
  {
    id
  ; stateNumber
  ; configset = configs
  ; edges = [||]
  ; isAcceptState = false
  ; prediction = 0
  ; lexerActionExecutor = None
  ; requiresFullContext = false
  ; predicates = None
  }

let init ?predicted_id ?(stateNumber = -1) ?(configs = ACS.init()) () =
  DFAStCounter.check predicted_id ;
  Tracelog.write
    (DFAState_ENTER_init (DFAStCounter.get(), stateNumber, ACS.to_mimick configs)) ;
  let rv = _init ?predicted_id stateNumber configs in
  Tracelog.write(DFAState_EXIT_init (to_mimick rv)) ;
  rv

let _set_stateNumber st n =
  st.stateNumber <- n

let set_stateNumber st n =
  Tracelog.write(DFAState_ENTER_set_stateNumber (to_mimick st, n)) ;
  _set_stateNumber st n ;
  Tracelog.write(DFAState_EXIT_set_stateNumber (to_mimick st))

let _set_configs st n =
  st.configset <- n

let set_configs st n =
  Tracelog.write(DFAState_ENTER_set_configs (to_mimick st, ACS.to_mimick n)) ;
  _set_configs st n ;
  Tracelog.write(DFAState_EXIT_set_configs (to_mimick st))

let _set_isAcceptState st n =
  st.isAcceptState <- n

let set_isAcceptState st n =
  Tracelog.write(DFAState_ENTER_set_isAcceptState (to_mimick st, n)) ;
  _set_isAcceptState st n ;
  Tracelog.write(DFAState_EXIT_set_isAcceptState (to_mimick st))

let _set_requiresFullContext st n =
  st.requiresFullContext <- n

let set_requiresFullContext st n =
  Tracelog.write(DFAState_ENTER_set_requiresFullContext (to_mimick st, n)) ;
  _set_requiresFullContext st n ;
  Tracelog.write(DFAState_EXIT_set_requiresFullContext (to_mimick st))

let _set_prediction st n =
  st.prediction <- n

let set_prediction st n =
  Tracelog.write(DFAState_ENTER_set_prediction (to_mimick st, n)) ;
  _set_prediction st n ;
  Tracelog.write(DFAState_EXIT_set_prediction (to_mimick st))

let _set_predicates st n =
  st.predicates <- n

let set_predicates st n =
  Tracelog.write(DFAState_ENTER_set_predicates (to_mimick st, Option.map (List.map PP.to_mimick) n)) ;
  _set_predicates st n ;
  Tracelog.write(DFAState_EXIT_set_predicates (to_mimick st))

let _set_lexerActionExecutor st n =
  st.lexerActionExecutor <- n

let set_lexerActionExecutor st n =
  Tracelog.write(DFAState_ENTER_set_lexerActionExecutor (to_mimick st, n)) ;
  _set_lexerActionExecutor st n ;
  Tracelog.write(DFAState_EXIT_set_lexerActionExecutor (to_mimick st))

let _makeEdges st n =
  st.edges <- n

let makeEdges st n =
  Tracelog.write(DFAState_ENTER_makeEdges (to_mimick st, n)) ;
  let n = Array.map (function None -> Int.min_int | Some n -> n) n in
  _makeEdges st n ;
  Tracelog.write(DFAState_EXIT_makeEdges (to_mimick st))

let _setEdge st n v =
  st.edges.(n) <- v.stateNumber

let setEdge st n v =
  Tracelog.write(DFAState_ENTER_setEdge (to_mimick st, n, to_mimick v)) ;
  _setEdge st n v ;
  Tracelog.write(DFAState_EXIT_setEdge (to_mimick st))

let recache ~dfast_cache ~acs_cache ~ac_cache st =
  ACS.recache ~acs_cache ~ac_cache st.configset ;
  Cache.upsert dfast_cache st

end


module DFA = struct
let disable_builtin_equality (x: int) = x

  let acsmap_for_all pred ht =
    ACSMap.fold (fun k v sofar -> sofar && pred k v) ht true

  let acsmap_values ht =
    ACSMap.fold (fun _ v acc -> v::acc) ht []

  let acsmap_oflist l =
    let ht = ACSMap.create 23 in
    List.iter (fun (cs, st) ->
        ACSMap.add ht cs st) l ;
    ht

  let states_equal ht1 ht2 =
    let open DFASt in
    ht1
    |> acsmap_for_all
         (fun cs1 st1 ->
           match ACSMap.find_opt ht2 cs1 with
             Some st2 -> ACS.real__eq__ st1.configset st2.configset
           | None -> false)
    && ht2
    |> acsmap_for_all
         (fun cs2 st2 ->
           match ACSMap.find_opt ht1 cs2 with
             Some st1 -> ACS.real__eq__ st1.configset st2.configset
           | None -> false)

type dfa_t = {
    disable_builtin_equality : int -> int
    [@printer (fun pps _ -> Fmt.(pf pps "_"))]
    [@equal fun x y -> true]
  ; atn : Atn.t
    [@printer (fun pps x -> Fmt.(pf pps "<atn 0x%08x>" (Hashtbl.hash x)))]
    [@equal (fun x y -> x==y)]
  ; grammarType : Atn.atn_type_t
  ; id : int
  ; atnStartState : M.deser_state_id
  ; decision : int
  ; _states : DFASt.t ACSMap.t
    [@printer (fun pps _ -> Fmt.(pf pps "<_states>"))]
    [@equal states_equal]

  ; num2state : (int, DFASt.t) MHM.t
    [@printer (fun pps _ -> Fmt.(pf pps "<num2state>"))]
    [@equal (fun _ _ -> true)]

  ; mutable precedenceDfa : bool
  ; mutable s0 : DFASt.t option
  }
[@@deriving show, eq]
type t = dfa_t
[@@deriving show, eq]

module Cache = Cacher(struct
                   type t  = dfa_t
                   let id t = t.id
                   let equal = equal_dfa_t
                   let pp = pp_dfa_t
                   let name = "DFA"
                 end)

let to_mimick t =
  {
    M.grammarType = t.grammarType
  ; id = t.id
  ; atnStartState = t.atnStartState
  ; decision = t.decision
  ; _states =
      t._states
      |> acsmap_values
      |> List.stable_sort (fun a b -> Stdlib.compare a.DFASt.stateNumber b.DFASt.stateNumber)
      |> List.map (fun st -> (string_of_int st.DFASt.stateNumber, DFASt.to_mimick st))
  ; precedenceDfa = t.precedenceDfa
  ; s0 = Option.map DFASt.to_mimick t.s0
  }

let _of_mimick ~dfast_cache ~acs_cache ~ac_cache atns t =
  let atn = Atns.for_grammar atns t.M.grammarType in
  let _states =
    t._states
    |> List.map (fun (stnum, st) ->
           let st = DFASt.of_mimick ~dfast_cache ~acs_cache ~ac_cache atns st in
           assert (stnum = string_of_int st.stateNumber) ;
           (st.configset, st))
    |> acsmap_oflist in
  let num2state = MHM.mk 23 in
  let () = ACSMap.iter (fun _ v -> MHM.add num2state (v.DFASt.stateNumber, v)) _states in
  {
    disable_builtin_equality
  ; atn
  ; grammarType = t.M.grammarType
  ; id = t.id
  ; atnStartState = t.atnStartState
  ; decision = t.decision
  ; _states
  ; num2state
  ; precedenceDfa = t.precedenceDfa
  ; s0 = Option.map (DFASt.of_mimick ~dfast_cache ~acs_cache ~ac_cache atns) t.s0
  }

let of_mimick ~dfa_cache ~dfast_cache ~acs_cache ~ac_cache atns t =
  let t = _of_mimick ~dfast_cache ~acs_cache ~ac_cache atns t in
  match dfa_cache with
    None -> t
  | Some dfa_cache -> Cache.recache dfa_cache t

module DFACounter = Counter(struct let name = "DFA" end)

let _init ?predicted_id atn grammarType atnStartState decision =
  DFACounter.check predicted_id ;
  let id = DFACounter.get_incr () in
  let rv = {
      disable_builtin_equality
    ; id
    ; atn
    ; grammarType
    ; atnStartState
    ; decision
    ; _states = ACSMap.create 23
    ; num2state = MHM.mk 23
    ; s0 = None
    ; precedenceDfa = false
    } in
  let st = Atn.State.get_state atn.states atnStartState in begin
      match st.node with
        Node.StarLoopEntryState {isPrecedenceDecision=Some true} ->
        rv.precedenceDfa <- true ;
        let precedenceState = DFASt.init ~configs:(ACS.init()) () in
        precedenceState.edges <- [||] ;
        precedenceState.isAcceptState <- false ;
        precedenceState.requiresFullContext <- false ;
        rv.s0 <- Some precedenceState
      | _ -> ()
    end ;
  rv

let init ?predicted_id atn grammarType atnStartState decision =
  DFACounter.check predicted_id ;
  Tracelog.write
    (DFA_ENTER_init (DFACounter.get(), grammarType, atnStartState, decision)) ;
  let rv = _init  ?predicted_id atn grammarType atnStartState decision in
  Tracelog.write
    (DFA_EXIT_init (rv.id, to_mimick rv)) ;
  rv

let _states_get dfa st =
Tracelog.with_disabled
  (fun () -> ACSMap.find_opt dfa._states st.DFASt.configset) ()

let states_get dfa st =
  Tracelog.write(DFA_ENTER_states_get(to_mimick dfa, DFASt.to_mimick st)) ;
  let rv = _states_get dfa st in
  Tracelog.write(DFA_EXIT_states_get(dfa.id, Option.map DFASt.to_mimick rv)) ;
  rv

let _states_len dfa = ACSMap.length dfa._states

let states_len dfa =
  Tracelog.write(DFA_ENTER_states_len(to_mimick dfa)) ;
  let rv = _states_len dfa in
  Tracelog.write(DFA_EXIT_states_len(rv)) ;
  rv

let _states_add dfa st =
  ACSMap.add dfa._states st.DFASt.configset st ;
  MHM.add dfa.num2state (st.stateNumber, st)

let states_add dfa st =
  Tracelog.write(DFA_ENTER_states_add(to_mimick dfa, DFASt.to_mimick st)) ;
  let rv = _states_add dfa st in
  Tracelog.write(DFA_EXIT_states_add(dfa.id, to_mimick dfa)) ;
  rv

let _set_s0 dfa st =
  dfa.s0 <- Some st

let set_s0 dfa st =
  Tracelog.write(DFA_ENTER_set_s0(to_mimick dfa, DFASt.to_mimick st)) ;
  _set_s0 dfa st ;
  Tracelog.write(DFA_EXIT_set_s0(dfa.id, to_mimick dfa)) ;
  ()

let _setPrecedenceStartState dfa precedence st =
  if not dfa.precedenceDfa then
    failwith "Only precedence DFAs may contain a precedence start state." ;
  if precedence < 0 then ()
  else begin
      match dfa.s0 with
        Some s0 ->
         let edges =
           if precedence >= Array.length s0.edges then begin
               let ext = Array.make (precedence + 1 - (Array.length s0.edges)) Int.min_int in
               let edges = Array.append s0.edges ext in 
               s0.DFASt.edges <- edges ;
               edges
             end
           else s0.edges in
         edges.(precedence) <- st.DFASt.stateNumber

      | None -> assert false
    end


let setPrecedenceStartState dfa precedence st =
  Tracelog.write(DFA_ENTER_setPrecedenceStartState(to_mimick dfa, precedence, DFASt.to_mimick st)) ;
  _setPrecedenceStartState dfa precedence st ;
  Tracelog.write(DFA_EXIT_setPrecedenceStartState(to_mimick dfa)) ;
  ()

let recache ~dfa_cache ~dfast_cache ~acs_cache ~ac_cache dfa =
  ACSMap.iter (fun k v ->
      ACS.recache ~acs_cache ~ac_cache k ;
      DFASt.recache ~dfast_cache ~acs_cache ~ac_cache v ;
      ()
    ) dfa._states
  ; Option.iter (fun st -> DFASt.recache ~dfast_cache ~acs_cache ~ac_cache st ; ()) dfa.s0
  ; Cache.upsert dfa_cache dfa

end

module IS = struct
type is_t = {
      id : int
    ; name : string
    ; strdata : string
    ; mutable _index : int
    ; data : int array
    ; mutable _size : int
  }
[@@deriving show, eq]
type t = is_t
[@@deriving show, eq]

module Cache = Cacher(struct
                   type t  = is_t
                   let id t = t.id
                   let equal = equal_is_t
                   let pp = pp_is_t
                   let name = "InputStream"
                 end)

let to_mimick t =
  M.InputStream {
      id = t.id
    ; name = t.name
    ; strdata = t.strdata
    ; _index = t._index
    ; data = t.data
    ; _size = t._size
    }

let _of_mimick t =
  match t with
    M.InputStream t ->
    {
      id = t.id
    ; name = t.name
    ; strdata = t.strdata
    ; _index = t._index
    ; data = t.data
    ; _size = t._size
    }

let of_mimick ~is_cache t =
  let t = _of_mimick t in
  match is_cache with
    None -> t
  | Some is_cache -> Cache.recache is_cache t

module Counter = Counter(struct let name = "InputStream" end)

let _init ?predicted_id strdata () =
  Counter.check predicted_id ;
  let id = Counter.get_incr () in
  let data = Util.array_of_string Ploc.dummy strdata in
  {
    id
  ; name = "<empty>"
  ; strdata
  ; data
  ; _index = 0
  ; _size = Array.length data
  }

let init ?predicted_id strdata () =
  Counter.check predicted_id ;
  Tracelog.write
    (InputStream_ENTER_init (Counter.get(), strdata)) ;
  let rv = _init  ?predicted_id strdata () in
  Tracelog.write
    (InputStream_EXIT_init (to_mimick rv)) ;
  rv

let recache ~is_cache is =
  Cache.upsert is_cache is

let _reset is =
  is._index <- 0

let reset is =
  Tracelog.write
    (InputStream_ENTER_reset (to_mimick is)) ;
  _reset is ;
  Tracelog.write
    (InputStream_EXIT_reset (to_mimick is))

let _la is offset =
  if offset = 0 then
    0
  else
    let offset = if offset < 0 then offset+1 else offset in begin
        let pos = is._index + offset - 1 in
        if pos < 0 || pos >= is._size then
          Token._EOF
        else
          is.data.(pos)
      end

let la is offset =
  Tracelog.write
    (InputStream_ENTER_LA (to_mimick is, offset)) ;
  let rv = _la is offset in
  Tracelog.write
    (InputStream_EXIT_LA (to_mimick is, rv)) ;
  rv

let _consume is =
  if is._index >= is._size then begin
    assert (la is 1 = Token._EOF) ;
    failwith "cannot consume EOF"
    end ;
  is._index <- 1 + is._index

let consume is =
  Tracelog.write
    (InputStream_ENTER_consume (to_mimick is)) ;
  _consume is ;
  Tracelog.write
    (InputStream_EXIT_consume (to_mimick is))

let _seek is _index =
  if _index <= is._index then
    is._index <- _index
  else
    is._index <- min _index is._size

let seek is _index =
  Tracelog.write
    (InputStream_ENTER_seek (to_mimick is, _index)) ;
  _seek is _index ;
  Tracelog.write
    (InputStream_EXIT_seek (to_mimick is))

let _getText is start stop =
  let stop = if stop >= is._size then is._size-1 else stop in
  if start >= is._size then
    ""
  else Util.string_of_uchars (List.map Uchar.of_int (Array.to_list (Array.sub is.data start (stop+1 - start))))

let getText is start stop =
  Tracelog.write
    (InputStream_ENTER_getText (to_mimick is, start, stop)) ;
  let rv = _getText is start stop in
  Tracelog.write
    (InputStream_EXIT_getText (to_mimick is, rv)) ;
  rv

let index (is : t) = is._index
let mark (is : t) = -1
let release (is : t) (marker : int) = ()
end
module InputStream = IS

module SS = struct
  type ss_t = {
      mutable index : int
    ; mutable line : int
    ; mutable column : int
    ; mutable dfaState : DFASt.t option
    }
[@@deriving show, eq]
  type t = ss_t
[@@deriving show, eq]

  let init () =
    {
      index = -1
    ; line = 0
    ; column = -1
    ; dfaState = None
    }

  let of_mimick ~dfast_cache ~acs_cache ~ac_cache atns t =
    match t with
      M.SimState t ->
          {
            index = t.index
          ; line = t.line
          ; column = t.column
          ; dfaState = Option.map (DFASt.of_mimick ~dfast_cache ~acs_cache ~ac_cache atns) t.dfaState
          }

  let to_mimick t =
    M.SimState {
      index = t.index
    ; line = t.line
    ; column = t.column
    ; dfaState = Option.map DFASt.to_mimick t.dfaState
    }

  let reset self =
    self.index <- -1
    ; self.line <- 0
    ; self.column <- -1
    ; self.dfaState <- None

let recache ~dfast_cache ~acs_cache ~ac_cache ss =
  Option.map (fun st -> DFASt.recache ~dfast_cache ~acs_cache ~ac_cache st ; ()) ss.dfaState ;
  ss

end
module SimState = SS

module L = struct
  let _DEFAULT_MODE = 0
  let _MORE = -2
  let _SKIP = -3
  let _DEFAULT_TOKEN_CHANNEL = Token._DEFAULT_CHANNEL
  let _HIDDEN = Token._HIDDEN_CHANNEL
  let _MIN_CHAR_VALUE = 0x0000
  let _MAX_CHAR_VALUE = 0x10FFFF

end
module Lexer = L

module AS = struct
module Counter = Counter(struct let name = "ATNSimulator" end)
end
module ATNSimulator = AS

module LAS = struct
  let mhs_equal x y =
    let x = x |> MHS.toList |> List.stable_sort Stdlib.compare in
    let y = y |> MHS.toList |> List.stable_sort Stdlib.compare in
    List.length x = List.length y
    && List.for_all2 PC.equal x y

type las_t = {
    id : int
  ; atn : Atn.t
    [@printer (fun pps x -> Fmt.(pf pps "<atn 0x%08x>" (Hashtbl.hash x)))]
    [@equal (fun x y -> x==y)]
  ; sharedContextCache : (PC.t MHS.t
                           [@equal mhs_equal]
                                 [@printer (fun pps _ -> Fmt.(pf pps "_"))])
  ; decisionToDFA : DFA.t array
  ; column : int
  ; line : int
  ; mutable mode : int
  ; prevAccept : SS.t
  ; mutable startIndex : int
  }
[@@deriving show, eq]
type t = las_t
[@@deriving show, eq]

let _init ?predicted_id atn decisionToDFA sharedContextCache () =
  AS.Counter.check predicted_id ;
  let id = AS.Counter.get_incr () in
  {
    id
  ; atn
  ; sharedContextCache = MHS.ofList sharedContextCache 23
  ; decisionToDFA
  ; startIndex = -1
  ; line = 1
  ; column = 0
  ; mode = Lexer._DEFAULT_MODE
  ; prevAccept = SS.init ()
  }

let to_mimick t =
  M.LexerATNSimulator {
    id = t.id
  ; sharedContextCache = t.sharedContextCache |> MHS.toList |> List.map PC.to_mimick
  ; decisionToDFA = t.decisionToDFA |> Array.map DFA.to_mimick
  ; startIndex = t.startIndex
  ; line = t.line
  ; column = t.column
  ; mode = t.mode
  ; prevAccept = t.prevAccept |> SS.to_mimick
  }

let init ?predicted_id atn decisionToDFA sharedContextCache () =
  AS.Counter.check predicted_id ;
  Tracelog.write
    (LexerATNSimulator_ENTER_init (AS.Counter.get(), Array.map DFA.to_mimick decisionToDFA, List.map PC.to_mimick sharedContextCache)) ;
  let rv = _init ?predicted_id atn decisionToDFA sharedContextCache () in
  Tracelog.write
    (LexerATNSimulator_EXIT_init (to_mimick rv)) ;
  rv

let _of_mimick ~dfa_cache ~dfast_cache ~acs_cache ~ac_cache atns t =
  let atn  = Atns.for_grammar atns Atn.LEXER in
  match t with
    M.LexerATNSimulator t ->
    {
      id = t.id
      ; atn
      ; sharedContextCache =
          t.sharedContextCache
          |> List.map PC.of_mimick
          |> (fun l -> MHS.ofList l 23)
      ; decisionToDFA = t.decisionToDFA |> Array.map (DFA.of_mimick ~dfa_cache ~dfast_cache ~acs_cache ~ac_cache atns)
      ; startIndex = t.startIndex
      ; line = t.line
      ; column = t.column
      ; mode = t.mode
      ; prevAccept = SS.of_mimick ~dfast_cache ~acs_cache ~ac_cache atns t.prevAccept
    }

module Cache = Cacher(struct
                   type t  = las_t
                   let id t = t.id
                   let equal = equal_las_t
                   let pp = pp_las_t
                   let name = "LexerATNSimulator"
                 end)


let of_mimick ~las_cache ~dfa_cache ~dfast_cache ~acs_cache ~ac_cache atns t =
  let t = _of_mimick ~dfa_cache ~dfast_cache ~acs_cache ~ac_cache atns t in
  match las_cache with
    None -> t
  | Some las_cache -> Cache.recache las_cache t

let recache ~las_cache ~dfa_cache ~dfast_cache ~acs_cache ~ac_cache las =
  Array.iter (fun dfa -> DFA.recache ~dfa_cache ~dfast_cache ~acs_cache ~ac_cache dfa ; ()) las.decisionToDFA
  ; SS.recache ~dfast_cache ~acs_cache ~ac_cache las.prevAccept
  ; Cache.upsert las_cache las

let execATN self input dfaSt = assert false

let _closure self input config configs ~currentAltReachedAcceptState
      ~speculative ~treatEofAsEpsilon =
  assert false

let closure self is config configs ~currentAltReachedAcceptState
      ~speculative ~treatEofAsEpsilon =
  Tracelog.write
    (LexerATNSimulator_ENTER_closure (to_mimick self, IS.to_mimick is,
                                      AC.to_mimick config, ACS.to_mimick configs,
                                      currentAltReachedAcceptState, speculative, treatEofAsEpsilon
    )) ;
  let rv = _closure self is config configs ~currentAltReachedAcceptState
      ~speculative ~treatEofAsEpsilon in
  Tracelog.write
    (LexerATNSimulator_EXIT_closure (to_mimick self, rv, ACS.to_mimick configs)) ;
  rv

let _computeStartState self is p =
  let p_state = Atn.State.get_state self.atn.Atn.states p in
  let initialContext = PC.EMPTY in
  let configs = ACS.init() in
  p_state.Atn.State.transitions
  |> List.iteri (fun i t ->
         let target = Edge.target t in
         let c = AC.init_LexerATNConfig self.atn (Some target) (Some (i+1)) (Some initialContext) None None None in
         closure self is c configs ~currentAltReachedAcceptState:false ~speculative:false ~treatEofAsEpsilon:false) ;
  configs

let computeStartState self is p =
  Tracelog.write
    (LexerATNSimulator_ENTER_computeStartState (to_mimick self, IS.to_mimick is, p)) ;
  let rv = _computeStartState self is p in
  Tracelog.write
    (LexerATNSimulator_EXIT_computeStartState (ACS.to_mimick rv)) ;
  rv

let _addDFAEdge self from_ tk to_ cs = assert false

let addDFAEdge self from_ tk to_ cs =
  Tracelog.write
    (LexerATNSimulator_ENTER_addDFAEdge (to_mimick self, Option.map DFASt.to_mimick from_,
                                         tk,
                                         Option.map DFASt.to_mimick to_,
                                         Option.map ACS.to_mimick cs)) ;
  let rv = _addDFAEdge self from_ tk to_ cs in
  Tracelog.write
    (LexerATNSimulator_EXIT_addDFAEdge (to_mimick self, DFASt.to_mimick rv)) ;
  rv

let _addDFAState self cs = assert false

let addDFAState self cs =
  Tracelog.write
    (LexerATNSimulator_ENTER_addDFAState (to_mimick self, ACS.to_mimick cs)) ;
  let rv = _addDFAState self cs in
  Tracelog.write
    (LexerATNSimulator_EXIT_addDFAState (to_mimick self, DFASt.to_mimick rv)) ;
  rv

let _matchATN self is =
  let startState = self.atn.Atn.modeToStartState.(self.mode) in
  let old_mode = self.mode in
  let s0_closure = computeStartState self is startState in
  let suppressEdge = s0_closure.ACS.hasSemanticContext in
  ACS.update_HSC s0_closure false ;
  let next = addDFAState self s0_closure in
  if not suppressEdge then
    DFA.set_s0 self.decisionToDFA.(self.mode) next ;
  let predict = execATN self is next in
  predict


let matchATN self is =
  Tracelog.write
    (LexerATNSimulator_ENTER_matchATN (to_mimick self, IS.to_mimick is)) ;
  let rv = _matchATN self is in
  Tracelog.write
    (LexerATNSimulator_EXIT_matchATN (to_mimick self, rv)) ;
  rv

let __match self is mode =
  self. mode <- mode
  ; let mark = IS.mark is in
    Util.finally (fun () -> 
        self.startIndex <- IS.index is
      ; SS.reset self.prevAccept
      ; let dfa = self.decisionToDFA.(mode) in
        match dfa.s0 with
          None -> matchATN self is
        | Some s0 -> execATN self is s0
      )
      ()
      (fun _ _ -> IS.release is mark)


let _match self is mode =
  Tracelog.write
    (LexerATNSimulator_ENTER_match (to_mimick self, IS.to_mimick is, mode)) ;
  let rv = __match self is mode in
  Tracelog.write
    (LexerATNSimulator_EXIT_match (to_mimick self, rv)) ;
  rv

end
module LexerATNSimulator = LAS

