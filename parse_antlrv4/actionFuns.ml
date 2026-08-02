open Antlr
open Exec

open L_constants.Channels
open L_constants.Modes
open L_constants.Tokens

let _PREQUEL_CONSTRUCT = -10
let _OPTIONS_CONSTRUCT = -11

let _currentRuleType = ref C._INVALID_TYPE

let getCurrentRuleType self = !_currentRuleType

let setCurrentRuleType self ruleType =
  _currentRuleType := ruleType

let inLexerRule self =
  getCurrentRuleType self = _TOKEN_REF

let inParserRule self =
  getCurrentRuleType self = _RULE_REF

let handleBeginArgument self cu =
  if inLexerRule self then begin
      R.pushMode self 2 ;
      R.more self
    end
  else
    R.pushMode self 1

let handleEndArgument self cu =
  R.popMode self ;
  if (List.length self.R._modeStack) > 0 then
    self._type <- _ARGUMENT_CONTENT

let after_nextToken self t =
  let t = ref t in
  let open Lexer in
  if (self.recog.R._type = _OPTIONS
         || self.recog.R._type = _TOKENS
         || self.recog.R._type = _CHANNELS)
         && getCurrentRuleType self = C._INVALID_TYPE then
        setCurrentRuleType self _PREQUEL_CONSTRUCT

      else if self.recog.R._type = _OPTIONS
              && getCurrentRuleType self = _TOKEN_REF then
        setCurrentRuleType self _OPTIONS_CONSTRUCT

      else if self.recog.R._type = _RBRACE
              && getCurrentRuleType self = _PREQUEL_CONSTRUCT then
        setCurrentRuleType self C._INVALID_TYPE

      else if self.recog.R._type = _RBRACE
              && getCurrentRuleType self = _OPTIONS_CONSTRUCT then
        setCurrentRuleType self _TOKEN_REF

      else if self.recog.R._type = _AT
              && getCurrentRuleType self = C._INVALID_TYPE then
            setCurrentRuleType self _AT

      else if self.recog.R._type = _SEMI
              && getCurrentRuleType self = _OPTIONS_CONSTRUCT then
        ()

      else if self.recog.R._type = _ACTION
              && getCurrentRuleType self = _AT then
        setCurrentRuleType self C._INVALID_TYPE

      else if self.recog.R._type = _ID then begin
          let firstChar = IS.getText self.recog.R._input self.recog.R._tokenStartCharIndex self.recog.R._tokenStartCharIndex in
            if Char.Ascii.is_upper firstChar.[0] then begin
                self.recog.R._type <- _TOKEN_REF ;
              end
            else begin
                self.recog.R._type <- _RULE_REF ;
              end ;
            t := { (!t) with T.type_ = Some self.recog.R._type } ;
            if getCurrentRuleType self = C._INVALID_TYPE then
              setCurrentRuleType self self.recog.R._type
        end
      else if self.recog.R._type = _SEMI then
        setCurrentRuleType self C._INVALID_TYPE ;

      !t
