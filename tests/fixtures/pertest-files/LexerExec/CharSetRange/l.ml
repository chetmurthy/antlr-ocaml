open Antlr
open Exec

let atns = Atns.load ~lexer_atn:"Lexer.interp" ~parser_atn:None ;;
let atn = atns.Atns.lexer ;;

let _I_action (self : R.recognizer_t) localCtx ruleIndex actionIndex =
  output_string stdout "I\n" ;;
let _ID_action (self : R.recognizer_t) localCtx ruleIndex actionIndex =
  output_string stdout "ID\n" ;;

let init ~input ~output =
  let decisionToDFA : DFA.t array =
    atn.Atn.decisionToState
    |> Array.mapi (fun i stid ->
           DFA.init atn Atn.LEXER stid i
         ) in
  let recog = R.init input ~output ~actions:[(0,_I_action); (1,_ID_action)] () in
  let interp : LAS.t =
    Tracelog.with_disabled (fun () ->
        LAS.init atn decisionToDFA [] ~recog ()
      ) ()
  in
  Tracelog.with_disabled (fun () ->
      Lexer.init ~recog ~interp ()
    ) ()
