open Pa_ppx_base
open Ppxutil
open Antlr
open Exec

let atns = Atns.load ~lexer_atn:"Lexer.interp" ~parser_atn:None ;;
let atn = snd atns.Atns.lexer ;;

let _ID1_sempred (self : R.recognizer_t) (cu : LASC.t) localCtx predIndex =
  if predIndex = 0 then
    cu.LASC.column < 2
  else Fmt.(failwithf "ID1_sempred: bad predIndex %d" predIndex)

let _ID2_sempred (self : R.recognizer_t) (cu : LASC.t) localCtx predIndex =
  if predIndex = 1 then
    cu.LASC.column >= 2
  else Fmt.(failwithf "ID2_sempred: bad predIndex %d" predIndex)

let _WORD1_action (self : R.recognizer_t) (cu : LASC.t) localCtx actionIndex =
  if actionIndex = 0 then begin
      output_string stdout (R.text self cu) ;
      output_string stdout "\n"
    end ;;

let _WORD2_action (self : R.recognizer_t) (cu : LASC.t) localCtx actionIndex =
  if actionIndex = 1 then begin
      output_string stdout (R.text self cu) ;
      output_string stdout "\n"
    end ;;

let actions = [(0, _WORD1_action); (1, _WORD2_action)]
let sempreds = [(2, _ID1_sempred);(3, _ID2_sempred)]

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
