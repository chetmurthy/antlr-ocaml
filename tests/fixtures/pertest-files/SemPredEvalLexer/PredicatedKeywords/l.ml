open Pa_ppx_base
open Ppxutil
open Antlr
open Exec

let atns = Atns.load ~lexer_atn:"Lexer.interp" ~parser_atn:None ;;
let atn = atns.Atns.lexer ;;

let _ENUM_sempred (self : R.recognizer_t) (cu : LASC.t) localCtx predIndex =
  if predIndex = 0 then
    (R.text self cu) = "enum"
  else Fmt.(failwithf "ENUM_sempred: bad predIndex %d" predIndex)

let _ENUM_action (self : R.recognizer_t) (cu : LASC.t) localCtx actionIndex =
  if actionIndex = 0 then
      output_string stdout "enum!\n"

let _ID_action (self : R.recognizer_t) (cu : LASC.t) localCtx actionIndex =
  if actionIndex = 1 then
      output_string stdout ("ID "^(R.text self cu)^"\n")


let actions = [(0, _ENUM_action); (1, _ID_action)]
let sempreds = [(0, _ENUM_sempred)]

let init ~input ~output =
  let decisionToDFA : DFA.t array =
    atn.Atn.decisionToState
    |> Array.mapi (fun i stid ->
           DFA.init atn Atn.LEXER stid i
         ) in
  let recog = R.init input ~output ~actions ~sempreds () in
  let interp : LAS.t =
    Tracelog.with_disabled (fun () ->
        LAS.init atn decisionToDFA [] ~recog ()
      ) ()
  in
  Tracelog.with_disabled (fun () ->
      Lexer.init ~recog ~interp ()
    ) ()
