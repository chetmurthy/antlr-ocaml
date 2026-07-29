(**pp -syntax camlp5o *)

open Pa_ppx_base
open Ppxutil
open Pa_ppx_utils

open Grammar_types

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

let load_imports g =
  let rec loadrec g =
    let toimport =
      g.prequels
      |> List.concat_map (function PQ_DELEGATE_GRAMMARS l -> l | _ -> []) in
    if List.exists (function (_, Some _) -> true | _ -> false) toimport then
      Fmt.(failwithf "grammar %s has a two-part import -- don't know how to do that"
             g.name) ;
    let gl =
      toimport
      |> List.map (fun (n, _) ->
             let file = n^".g4" in
             loadfile ~file n) in
    let gl_rules = gl |> List.concat_map (fun g -> g.rules) in
    let gl_modes = gl |> List.concat_map (fun g -> g.modes) in
    { (g) with
      rules = g.rules @ gl_rules
    ; modes = g.modes @ gl_modes
    }
  and loadfile ~file name =
    let g = Pa.Grammar.load ~file in
    assert (g.type_ = LEXER) ;
    if g.name <> name then
      Fmt.(failwithf "slaveGrammar %s (file %s) was named %s"
             name file g.name) ;
    if not (List.for_all (function PQ_DELEGATE_GRAMMARS _ -> true | _ -> false) g.prequels) then
      Fmt.(failwithf "slaveGrammar %s (file %s) should only have imports, not other prequels"
             name file) ;
    loadrec g
  in
  g |> loadrec |> group_modes
