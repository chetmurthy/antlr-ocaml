open Antlr
open Exec

let inLexerRule self = true

let handleBeginArgument self cu =
  if inLexerRule self then begin
      R.pushMode self 2 ;
      R.more self
    end
  else
    R.pushMode self 1

let handleEndArgument self cu =
  ignore (R.popMode self : int) ;
  assert (List.length self.R._modeStack = 0)
