open Antlr
open Exec

let atns = Atns.load ~lexer_atn:"Lexer.interp" ~parser_atn:None ;;
let atn = atns.Atns.lexer ;;
let decisionToDFA =
  atn.Atn.decisionToState
  |> Array.mapi (fun i stid ->
         DFA.init atn Atn.LEXER stid i
       ) ;;

let _I_action (self : R.recognizer_t) localCtx ruleIndex actionIndex =
  output_string stdout "I\n" ;;

let init ~input ~output =
  let recog = R.init input ~output ~actions:[(0,_I_action)] () in
  let interp : LAS.t = LAS.init atn decisionToDFA [] ~recog () in
  Lexer.init ~recog ~interp ()

(*
let atn  = Atns.for_grammar atns Atn.LEXER in
         let decisionToDFA = Array.map (DFA.of_mimick ~dfa_cache:(Some caches.dfa)  ~dfast_cache:(Some caches.dfast) ~acs_cache:(Some caches.acs) ~ac_cache:(Some caches.ac) atns) decisionToDFA in
         let sharedContextCache = List.map PC.of_mimick sharedContextCache in
         let recog = match !(caches.lexer) with
             None -> failwith "internal error in simulation: exer not initialized"
           | Some l -> l.recog in
let is = IS.of_mimick ~is_cache:(Some caches.is) is in
         let rv : LAS.t = LAS.init ~predicted_id atn decisionToDFA sharedContextCache ~recog () in

 *)
