open Antlr
open Exec

let _OFF_CHANNEL = 2
let _COMMENT = 3

let _Argument = 1
let _LexerCharSet = 2

let _ACTION = 1
let _ARG_ACTION = 2
let _ARG_OR_CHARSET = 3
let _ASSIGN = 4
let _LEXER_CHAR_SET = 5
let _RULE_REF = 6
let _SEMPRED = 7
let _STRING_LITERAL = 8
let _TOKEN_REF = 9
let _UNICODE_ESC = 10
let _UNICODE_EXTENDED_ESC = 11
let _WS = 12
let _ALT = 13
let _BLOCK = 14
let _CLOSURE = 15
let _ELEMENT_OPTIONS = 16
let _EPSILON = 17
let _LEXER_ACTION_CALL = 18
let _LEXER_ALT_ACTION = 19
let _OPTIONAL = 20
let _POSITIVE_CLOSURE = 21
let _RULE = 22
let _RULEMODIFIERS = 23
let _RULES = 24
let _SET = 25
let _WILDCARD = 26
let _DOC_COMMENT = 27
let _BLOCK_COMMENT = 28
let _LINE_COMMENT = 29
let _INT = 30
let _UNTERMINATED_STRING_LITERAL = 31
let _BEGIN_ARGUMENT = 32
let _OPTIONS = 33
let _TOKENS = 34
let _CHANNELS = 35
let _IMPORT = 36
let _FRAGMENT = 37
let _LEXER = 38
let _PARSER = 39
let _GRAMMAR = 40
let _PROTECTED = 41
let _PUBLIC = 42
let _PRIVATE = 43
let _RETURNS = 44
let _LOCALS = 45
let _THROWS = 46
let _CATCH = 47
let _FINALLY = 48
let _MODE = 49
let _COLON = 50
let _COLONCOLON = 51
let _COMMA = 52
let _SEMI = 53
let _LPAREN = 54
let _RPAREN = 55
let _RBRACE = 56
let _RARROW = 57
let _LT = 58
let _GT = 59
let _QUESTION = 60
let _STAR = 61
let _PLUS_ASSIGN = 62
let _PLUS = 63
let _OR = 64
let _DOLLAR = 65
let _RANGE = 66
let _DOT = 67
let _AT = 68
let _POUND = 69
let _NOT = 70
let _ID = 71
let _END_ARGUMENT = 72
let _UNTERMINATED_ARGUMENT = 73
let _ARGUMENT_CONTENT = 74
let _UNTERMINATED_CHAR_SET = 75

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
