open Pa_ppx_base
open Ppxutil
open Antlr
open Exec

let atns = Atns.load ~lexer_atn:"Lexer.interp" ~parser_atn:None ;;
let atn = snd atns.Atns.lexer ;;

let _UID_sempred (self : R.recognizer_t) (cu : LASC.t) localCtx predIndex =
  if predIndex = 0 then
    Char.Ascii.is_upper (R.text self cu).[0]
  else Fmt.(failwithf "UID_sempred: bad predIndex %d" predIndex)

let _LID_sempred (self : R.recognizer_t) (cu : LASC.t) localCtx predIndex =
  if predIndex = 1 then
    Char.Ascii.is_lower (R.text self cu).[0]
  else Fmt.(failwithf "LID_sempred: bad predIndex %d" predIndex)

let _UID_action (self : R.recognizer_t) (cu : LASC.t) localCtx actionIndex =
  if actionIndex = 0 then
      output_string stdout ("UID "^(R.text self cu)^"\n")

let _LID_action (self : R.recognizer_t) (cu : LASC.t) localCtx actionIndex =
  if actionIndex = 1 then
      output_string stdout ("LID "^(R.text self cu)^"\n")


let actions = [(0, _UID_action); (1, _LID_action)]
let sempreds = [(0, _UID_sempred);(1, _LID_sempred)]

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
