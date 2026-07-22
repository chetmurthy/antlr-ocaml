open Pa_ppx_base
open Ppxutil
open Antlr
open Exec

let atns = Atns.load ~lexer_atn:"Lexer.interp" ~parser_atn:None ;;
let atn = snd atns.Atns.lexer ;;

let _INDENT_sempred (self : R.recognizer_t) (cu : LASC.t) localCtx predIndex =
  if predIndex = 0 then
    self.R._tokenStartColumn = 0
  else Fmt.(failwithf "INDENT_sempred: bad predIndex %d" predIndex)

let _INDENT_action (self : R.recognizer_t) (cu : LASC.t) localCtx actionIndex =
  if actionIndex = 0 then
    output_string stdout "INDENT\n" ;;

let actions = [(1, _INDENT_action)]
let sempreds = [(1, _INDENT_sempred)]

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
