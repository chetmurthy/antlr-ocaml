(**pp -syntax camlp5o -package pa_ppx_tracelog,pa_ppx_regexp *)

open Pa_ppx_utils

module Full = struct
open Antlr
include L.Full
open Exec

let resetAcceptPosition self index line column =
    IS.seek self.recog.R._input index ;
    self._interp.LAS.cursor.LASC.line <- line ;
    self._interp.LAS.cursor.LASC.column <- column ;
    LAS.consume self._interp self.recog.R._input

let handleAcceptPositionForKeyword self keyword t =
  let keywordlen = String.length keyword in
  if IS.index self.recog.R._input > self.recog.R._tokenStartCharIndex + keywordlen then begin
      let offset = keywordlen - 1 in
      resetAcceptPosition self
        (self.recog.R._tokenStartCharIndex + offset)
        self.recog.R._tokenStartLine
        (self.recog.R._tokenStartColumn + offset) ;
      let txt = T.text t in
      let gap = (String.length txt) - keywordlen in
      { (t) with stop = Some ((Std.outSome t.stop) - gap) }
    end
  else t

let handleAcceptPositionForIdentifier self t =
  let txt = T.text t in
  let id = [%match {|(^[a-zA-Z0-9_]+)|} / pcre2 strings !1 exc] txt in
  let idlen = String.length id in
  if self.recog.R._input._index > self.recog.R._tokenStartCharIndex + idlen then begin
      let offset = idlen - 1 in
      resetAcceptPosition self
        (self.recog.R._tokenStartCharIndex + offset)
        self.recog.R._tokenStartLine
        (self.recog.R._tokenStartColumn + offset) ;
      let gap = (String.length txt) - idlen in
      { (t) with stop = Some ((Std.outSome t.stop) - gap) }
    end
  else t

let token_symbolic_name (raw_atn, _) ty =
  if ty < 0 then None
  else if ty >= Array.length raw_atn.Interp.Raw.token_symbolic_names then None
  else raw_atn.Interp.Raw.token_symbolic_names.(ty)

let _nextToken self =
  let rv = Lexer.nextToken self in

  let rv = 
    if token_symbolic_name full_atn (Std.outSome rv.T.type_) = Some "TOKENS" then
      handleAcceptPositionForKeyword self "tokens" rv
    else if token_symbolic_name full_atn (Std.outSome rv.T.type_) = Some "LABEL" then
      handleAcceptPositionForIdentifier self rv
    else rv in
  Lexer.emitToken self rv ;
  rv

let nextToken self =
  [%trace (PAL_ENTER_nextToken (to_mimick self))] ;
  let rv = Tracelog.with_disabled (fun () -> _nextToken self) () in
  [%trace (PAL_EXIT_nextToken (to_mimick self, Token.to_mimick rv))] ;
  rv

let full_init ~input ~output =
  LexerBase.init ~atn ~actions ~sempreds ~input ~output
end
