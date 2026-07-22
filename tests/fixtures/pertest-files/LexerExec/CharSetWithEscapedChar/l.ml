open Antlr
open Exec

let atns = Atns.load ~lexer_atn:"Lexer.interp" ~parser_atn:None ;;
let atn = snd atns.Atns.lexer ;;

let _DASHBRACK_action (self : R.recognizer_t) (cu : LASC.t) localCtx actionIndex =
  if actionIndex = 0 then
  output_string stdout "DASHBRACK\n" ;;

let init ~input ~output =
  let decisionToDFA : DFA.t array =
    atn.Atn.decisionToState
    |> Array.mapi (fun i stid ->
           DFA.init atn Atn.LEXER stid i
         ) in
  let recog = R.init input ~output ~actions:[(0,_DASHBRACK_action)] () in
  let interp : LAS.t =
    Tracelog.with_disabled (fun () ->
        LAS.init atn decisionToDFA [] ~recog ()
      ) ()
  in
  Tracelog.with_disabled (fun () ->
      Lexer.init ~recog ~interp ()
    ) ()
