open Antlr
open Exec

let atns = Atns.load ~lexer_atn:"Lexer.interp" ~parser_atn:None ;;
let atn = snd atns.Atns.lexer ;;

let _I_action (self : R.recognizer_t) (cu : LASC.t) localCtx actionIndex =
  if actionIndex = 0 then
    let text = R.text self cu in
    output_string stdout ("stuff fail: " ^ text) ;
    output_string stdout "\n"
  else if actionIndex = 1 then
    let text = R.text self cu in
    output_string stdout("stuff0:" ^ text) ;
    output_string stdout "\n"
  else if actionIndex = 2 then
    let text = R.text self cu in
    output_string stdout("stuff1: " ^ text) ;
    output_string stdout "\n"
  else if actionIndex = 3 then
    let text = R.text self cu in
    output_string stdout("stuff2: " ^ text) ;
    output_string stdout "\n"
  else if actionIndex = 4 then
    let text = R.text self cu in
    output_string stdout text ;
    output_string stdout "\n"

let init ~input ~output =
  let decisionToDFA : DFA.t array =
    atn.Atn.decisionToState
    |> Array.mapi (fun i stid ->
           DFA.init atn Atn.LEXER stid i
         ) in
  let recog = R.init input ~output ~actions:[(0,_I_action)] () in
  let interp : LAS.t =
    Tracelog.with_disabled (fun () ->
        LAS.init atn decisionToDFA [] ~recog ()
      ) ()
  in
  Tracelog.with_disabled (fun () ->
      Lexer.init ~recog ~interp ()
    ) ()
