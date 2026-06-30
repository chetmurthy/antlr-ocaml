(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.utils,pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.yojson,pa_ppx.deriving_plugins.located_yojson,pa_ppx.import *)

open Pa_ppx_utils
open Util
open Atn

module M = Mimick

module PC = struct

type t =
  EMPTY
| SINGLETON of t option * int
| ARRAY of t option array * int list

let mergeSingletons a b rootIsWildcard mergeCache =
  a

let mergeArrays a b rootIsWildcard mergeCache =
  a

let merge  a b rootIsWildcard mergeCache =
  if a == b then
    a
  else match (a,b) with
         (SINGLETON _, SINGLETON _) ->
         mergeSingletons a b rootIsWildcard mergeCache
       | (EMPTY, _) when rootIsWildcard -> a
       | (_, EMPTY) when rootIsWildcard -> b
       | _ ->
          let a = match a with
              SINGLETON (parentCtx, returnState) ->
              ARRAY ([|parentCtx|], [returnState])
            | _ -> a in
          let b = match a with
              SINGLETON (parentCtx, returnState) ->
              ARRAY ([|parentCtx|], [returnState])
            | _ -> b in
          mergeArrays a b rootIsWildcard mergeCache

end
module PredictionContextunit = PC

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

