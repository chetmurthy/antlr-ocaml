open Antlr
open Exec

let atns = Atns.load ~lexer_atn:"Lexer.interp" ~parser_atn:None ;;
let atn = snd atns.Atns.lexer ;;

let _I_action (self : R.recognizer_t) (cu : LASC.t) localCtx actionIndex =
  if actionIndex = 0 then
    output_string stdout "I\n" ;;

let actions = [(0,_I_action)]
let sempreds = []

let init ~input ~output =
  LexerBase.init ~atn ~actions ~sempreds ~input ~output
