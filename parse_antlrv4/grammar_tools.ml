(**pp -syntax camlp5o -package pa_ppx.deriving_plugins.yojson,pa_ppx.deriving_plugins.std *)

open Pa_ppx_base
open Ppxutil
open Pa_ppx_utils

open Antlr
open Util
open Grammar_types

let rulespec_name = function
    RULESPEC_LEXER {name} -> name
  | RULESPEC_PARSER {name} -> name

let isLexerRulespec = function RULESPEC_LEXER _ -> true | _ -> false

let concat_rulespecs rsl1 rsl2 =
  let names1 = List.map rulespec_name rsl1 in
  let rsl2 = List.filter (fun rs -> not (List.mem (rulespec_name rs) names1)) rsl2 in
  rsl1@rsl2

let group_modes g =
  let rec grec = function
      [] -> []
    | ((mode, _)::_ as l) ->
       let thismode_rules =  Std.filter (fun (m, _) -> m = mode) l in
       let remainder =  Std.filter (fun (m, _) -> m <> mode) l in
       let grouped = (mode, List.concat_map snd thismode_rules) in
       grouped::(grec remainder)
  in
  {(g) with modes = grec g.modes}

let load_imports ~path g =
  let path =
    let dir = g.filename |> Fpath.v |> Fpath.parent in
    if not (List.mem dir path) then
      (dir::path)
    else path in
  let rec loadrec g =
    let toimport =
      g.prequels
      |> List.concat_map (function PQ_DELEGATE_GRAMMARS l -> l | _ -> []) in
    let new_prequels =
      g.prequels
    |> List.filter_map (function PQ_DELEGATE_GRAMMARS _ -> None | x -> Some x) in
    if List.exists (function (_, Some _) -> true | _ -> false) toimport then
      Fmt.(failwithf "grammar %s has a two-part import -- don't know how to do that"
             g.name) ;
    let gl =
      toimport
      |> List.map (fun (n, _) ->
             let file = Fpath.v (n^".g4") in
             let file = Path.find ~path file in
             let file = Fpath.to_string file in
             loadfile ~file n) in
    let gl_prequels = gl |> List.concat_map (fun g -> g.prequels) in
    let gl_rules = gl |> List.concat_map (fun g -> g.rules) in
    let gl_modes = gl |> List.concat_map (fun g -> g.modes) in
    { (g) with
      prequels = new_prequels @ gl_prequels
    ; rules = concat_rulespecs g.rules gl_rules
    ; modes = g.modes @ gl_modes
    }
  and loadfile ~file name =
    let g = Pa.Grammar.load ~file in
    if g.name <> name then
      Fmt.(failwithf "slaveGrammar %s (file %s) was named %s"
             name file g.name) ;
    let g = loadrec g in
    let rulenames =
      (g.rules @ (List.concat_map snd g.modes))
      |> List.map rulespec_name in
    let repeats = Std2.hash_list_repeats rulenames in
    if repeats <>  [] then
      Fmt.(failwithf "load_imports: repeated rule-names: %a@." (list ~sep:comma string) repeats) ;
    g
  in
  g |> loadrec |> group_modes

(** generate actions:
    
    To generate actions:

    (1) extract all rule-specs, numbering them.
    (2) for each rulespec, extract all actions, numbering them.

    A similar method for generating sempreds.
 *)

let extract_actions rs =
  let acc = ref [] in
  let open Migrate_grammar in
  let dt = make_dt() in
  let migrate_action_t _ a =
    Std.push acc a ;
    a in
  let dt = { (dt) with migrate_action_t = migrate_action_t } in
  ignore (dt.migrate_rule_spec_t dt rs : rule_spec_t) ;
  List.rev !acc

let extract_sempreds rs =
  let acc = ref [] in
  let open Migrate_grammar in
  let dt = make_dt() in
  let migrate_sempred_t _ a =
    Std.push acc a ;
    a in
  let dt = { (dt) with migrate_sempred_t = migrate_sempred_t } in
  ignore (dt.migrate_rule_spec_t dt rs : rule_spec_t) ;
  List.rev !acc

let grammar_extract1 extractor g =
  let rulespecs = g.rules @ (List.concat_map snd g.modes) in
  let lexer_rulespecs = List.filter isLexerRulespec rulespecs in
  let labeled_rulespecs =
    List.mapi (fun i rs ->
        let name = rulespec_name rs in
        ((name,i), rs)) lexer_rulespecs in
  labeled_rulespecs
  |> List.concat_map
       (fun (lab,rs) ->
         let actions = extractor rs in
         List.map (fun act -> (lab, act)) actions)
  |> List.mapi
       (fun j (lab, act) ->
         (lab, (j, act)))

let grammar_actions g = grammar_extract1 extract_actions g
let grammar_sempreds g = grammar_extract1 extract_sempreds g

let groupby_fst l =
  let eatfst k l =
    let rec eatrec acc = function
        (k',v)::t when k = k' ->
        eatrec (v::acc) t
      | l -> ((k,List.rev acc), l) in
    eatrec [] l in
  let rec grec acc = function
      ((k,_)::_ as l) ->
      let (h,l) = eatfst k l in
      grec (h::acc) l
    | [] -> List.rev acc in
  grec [] l

module TF = struct
open Coll

type _t =
  (string * string) list
    [@@deriving yojson { exn = true }]

type t = (string, string) MHM.t

let load file =
  let j = Yojson.Safe.from_file file in
  let l = j |> _t_of_yojson_exn in
  MHM.ofList 23 l

let map t lhs =
  match MHM.map t lhs with
    rhs -> rhs
  | exception Not_found ->
     Fmt.(failwithf "TranslationFile.map: key %a not found"
            Dump.string lhs)

let map_action t = function
    ACTION s -> map t s

let map_sempred t = function
    SEMPRED s -> map t s

end
module TranslationFile = TF

let generate_lexer ~path ~translation_file gramfile =
  let tf = TF.load (Fpath.to_string translation_file) in
  let g =
    gramfile
    |> Fpath.to_string
    |> (fun file -> Pa.Grammar.load ~file)
    |> (load_imports ~path) in

  let actions = groupby_fst (grammar_actions g) in
  let sempreds = groupby_fst (grammar_sempreds g) in

  let pp_action pps (actionIndex, action) =
    Fmt.(pf pps 
           {| if actionIndex = %d then %s
else |}
           actionIndex
           (TF.map_action tf action)) in

  let pp_action_name pps lab = Fmt.(pf pps "_%s_action" lab) in
  let pp_sempred_name pps lab = Fmt.(pf pps "_%s_sempred" lab) in
  let pp_action_func pps ((lab, ruleIndex), actions)  =
    Fmt.(pf pps 
{|let %a (self : R.recognizer_t) (cu : LASC.t) localCtx actionIndex =
%a
 Fmt.(failwithf "%a: unrecognized actionIndex %%d" actionIndex)
 |}
         pp_action_name lab
         (list pp_action) actions
         pp_action_name lab
    )
  in

  let pp_sempred pps (predIndex, sempred) =
    Fmt.(pf pps 
           {| if predIndex = %d then %s
else |}
           predIndex
           (TF.map_sempred tf sempred)) in

  let pp_sempred_func pps ((lab, ruleIndex), sempreds)  =
    Fmt.(pf pps 
{|let %a (self : R.recognizer_t) (cu : LASC.t) localCtx predIndex =
%a
 Fmt.(failwithf "%a: unrecognized predIndex %%d" predIndex)
 |}
         pp_sempred_name lab
         (list pp_sempred) sempreds
         pp_sempred_name lab
    )
  in

  let pp_action_binding pps (lab, ruleIndex) =
    Fmt.(pf pps "(%d, %a)" ruleIndex pp_action_name lab) in
  let pp_sempred_binding pps (lab, ruleIndex) =
    Fmt.(pf pps "(%d, %a)" ruleIndex pp_sempred_name lab) in

  let pp_action_bindings pps actions =
    Fmt.(pf pps "let actions = [%a]" (list ~sep:(const string "; ") pp_action_binding)
         (List.map fst actions)) in

  let pp_sempred_bindings pps actions =
    Fmt.(pf pps "let sempreds = [%a]" (list ~sep:(const string "; ") pp_sempred_binding)
         (List.map fst actions)) in

  Fmt.(pf stdout 
{|
 open Pa_ppx_utils
 open Pa_ppx_base
 open Ppxutil
 open Antlr
 open Exec
let full_atn = Exec.Atns.read_atn ~grammarType:LEXER ~raw:raw_atn ()
let atn = snd full_atn
%a
%a
%a
%a
module Full = struct
include Exec.Lexer
let full_init ~input ~output =
  LexerBase.init ~atn ~actions ~sempreds ~input ~output
end
|}
         (list pp_action_func) actions
         (list pp_sempred_func) sempreds
         pp_action_bindings actions
         pp_sempred_bindings sempreds
  )
