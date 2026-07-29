open Antlr
open Exec

let atns = Atns.load ~lexer_atn:"Lexer.interp" ~parser_atn:None ;;
let atn = snd atns.Atns.lexer ;;

let actions = []
let sempreds = []

let init ~input ~output =
  LexerBase.init ~atn ~actions ~sempreds ~input ~output
