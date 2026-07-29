open Antlr
open Exec

let atns = Atns.load ~lexer_atn:"Lexer.interp" ~parser_atn:None ;;
let atn = snd atns.Atns.lexer ;;

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
let sempreds = []

let init ~input ~output =
  LexerBase.init ~atn ~actions ~sempreds ~input ~output
