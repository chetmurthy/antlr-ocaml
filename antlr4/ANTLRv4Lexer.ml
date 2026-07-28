open Pa_ppx_base
open Ppxutil

open Antlr
open Exec

let full_atn = Exec.Atns.read_atn ~grammarType:LEXER ~raw:ANTLRv4Lexer_atn.atn ()
let atn = snd full_atn

let inLexerRule self = true

let handleBeginArguemnt self cu =
  if inLexerRule self then begin
      R.pushMode self 2 ;
      R.more self
    end
  else
    R.pushMode self 1

let handleEndArgument self cu =
  R.popMode self ;
  assert (List.length self.R._modeStack = 0)


let _BEGIN_ARGUMENT_action (self : R.recognizer_t) (cu : LASC.t) localCtx actionIndex =
  if actionIndex = 0 then
    handleBeginArguemnt self cu

let _END_ARGUMENT_action (self : R.recognizer_t) (cu : LASC.t) localCtx actionIndex =
  if actionIndex = 0 then
    handleEndArgument self cu

let actions = [(6,_BEGIN_ARGUMENT_action);(54,_END_ARGUMENT_action)]

let _UID_sempred (self : R.recognizer_t) (cu : LASC.t) localCtx predIndex =
  if predIndex = 0 then
    Char.Ascii.is_upper (R.text self cu).[0]
  else Fmt.(failwithf "UID_sempred: bad predIndex %d" predIndex)

let _LID_sempred (self : R.recognizer_t) (cu : LASC.t) localCtx predIndex =
  if predIndex = 1 then
    Char.Ascii.is_lower (R.text self cu).[0]
  else Fmt.(failwithf "LID_sempred: bad predIndex %d" predIndex)

let sempreds = [(48, _UID_sempred);(49, _LID_sempred)]

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
