(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.deriving_plugins.std *)

open Pa_ppx_utils
open Antlr
open Camlp5_adapter

module STRenaming = struct
let renaming = [
    ((Some "AND", None), (Some "AND",Some "&&"))
  ; ((Some "ASSIGN", None), (Some "ASSIGN", Some "="))
  ; ((Some "AT", None), (Some "AT", Some "@"))
  ; ((Some "BANG", None), (Some "BANG",Some "!"))
  ; ((Some "COLON", None), (Some "COLON",Some ":"))
  ; ((Some "COMMA", None), (Some "COMMA",Some ","))
  ; ((Some "DOT", None), (Some "DOT",Some "."))
  ; ((Some "ELLIPSIS", None), (Some "ELLIPSIS", Some "..."))
  ; ((Some "EQUALS", None), (Some "EQUALS", Some "="))
  ; ((Some "FALSE", None), (Some "FALSE", Some "false"))
  ; ((Some "LBRACE", None), (Some "LBRACE",Some "{"))
  ; ((Some "LBRACK", None), (Some "LBRACK",Some "["))
  ; ((Some "LDELIM", None), (Some "LDELIM",Some "<"))
  ; ((Some "LPAREN", None), (Some "LPAREN",Some "("))
  ; ((Some "OR", None), (Some "OR",Some "||"))
  ; ((Some "PIPE", None), (Some "PIPE",Some "|"))
  ; ((Some "RBRACE", None), (Some "RBRACE",Some "}"))
  ; ((Some "RBRACK", None), (Some "RBRACK",Some "]"))
  ; ((Some "RDELIM", None), (Some "RDELIM",Some ">"))
  ; ((Some "RPAREN", None), (Some "RPAREN",Some ")"))
  ; ((Some "SEMI", None), (Some "SEMI",Some ";"))
  ; ((Some "SLASH", None), (Some "SLASH",Some "/"))
  ; ((Some "TMPL_ASSIGN", None), (Some "TMPL_ASSIGN", Some "::="))
  ; ((Some "TRUE", None), (Some "TRUE", Some "true"))
  ]
end

module ST0AfterInit = struct
  module Lex = ST0Lexer.Full
  let after_init lex =
    (*
    Exec.(R.mode lex.L.recog L_st_constants.Modes._Outside) ;
 *)
    ()
end
module ST1AfterInit = struct
  module Lex = ST1Lexer.Full
  let after_init lex =
    (*
    Exec.(R.mode lex.L.recog L_st_constants.Modes._Outside) ;
 *)
    ()
end
module ST2AfterInit = struct
  module Lex = ST2Lexer.Full
  let after_init lex =
    Exec.(R.mode lex.L.recog ST2Lexer_constants.Modes._Outside) ;
    ()
end
module ST0 = Make(ActionFuns_ST0)(STRenaming)(ST0Lexer.Full)(ST0AfterInit)
module ST1 = Make(ActionFuns_ST1)(STRenaming)(ST1Lexer.Full)(ST1AfterInit)
module ST2 = Make(ActionFuns_ST2)(STRenaming)(ST2Lexer.Full)(ST2AfterInit)

module ActionFuns_STG0 = struct
let reset () = ()
end

module STG0AfterInit = struct
  module Lex = STG0Lexer.Full
  let after_init lex = ()
end

module STG0 = Make(ActionFuns_STG0)(STRenaming)(STG0Lexer.Full)(STG0AfterInit)

module STG2_ST_AfterInit = struct
  module Lex = STG2Lexer.Full
  let after_init lex =
    Exec.(R.mode lex.L.recog STG2Lexer_constants.Modes._Outside) ;
    ()
end

module STG2_ST = Make(ActionFuns_STG2)(STRenaming)(STG2Lexer.Full)(STG2_ST_AfterInit)

module STG2_STG_AfterInit = struct
  module Lex = STG2Lexer.Full
  let after_init lex =
    Exec.(R.mode lex.L.recog STG2Lexer_constants.Modes._Group) ;
    ()
end

module STG2_STG = Make(ActionFuns_STG2)(STRenaming)(STG2Lexer.Full)(STG2_STG_AfterInit)
