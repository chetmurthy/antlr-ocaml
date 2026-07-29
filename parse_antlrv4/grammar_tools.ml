(**pp -syntax camlp5o *)

open Pa_ppx_base
open Ppxutil
open Pa_ppx_utils

open Antlr
open Util
open Grammar_types

let rulespec_name = function
    RULESPEC_LEXER {name} -> name
  | _ -> Fmt.(failwithf "PARSER rule in a Lexer grammar!")

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
    assert (g.type_ = LEXER) ;
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
  let labeled_rulespecs =
    List.mapi (fun i rs ->
        let name = rulespec_name rs in
        ((name,i), rs)) rulespecs in
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
