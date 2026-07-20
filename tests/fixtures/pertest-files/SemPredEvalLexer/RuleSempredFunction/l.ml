open Pa_ppx_base
open Ppxutil
open Antlr
open Exec

let atns = Atns.load ~lexer_atn:"Lexer.interp" ~parser_atn:None ;;
let atn = atns.Atns.lexer ;;

let _T_sempred (self : R.recognizer_t) (cu : LASC.t) localCtx predIndex =
  if predIndex = 0 then
    true
  else Fmt.(failwithf "T_sempred: bad predIndex %d" predIndex)

let actions = []
let sempreds = [(0, _T_sempred)]

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
