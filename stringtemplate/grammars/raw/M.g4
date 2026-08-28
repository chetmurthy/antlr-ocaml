lexer grammar M;

@lexer::members {
    self.mode(self.Group)

def isLDelimNotComment(self):
    return (self._input.LA(-1) == ord('\<') and self._input.LA(1) != ord('!'))

def isRDelim(self):
    return (self._input.LA(-1) == ord('>'))

def isLTmplComment(self):
    return (self._input.LA(-1) == ord('\<') and self._input.LA(1) == ord('!'))

def isRTmplComment(self):
    return (self._input.LA(-2) == ord('!') and self._input.LA(-1) == ord('>'))

def adjText(self):
    c1 = self._input.LA(-1)
    if c1 == ord('\\\\'):
        c2 = self._input.LA(1)
        if c2 == ord('\\\\'):
            self._input.consume()
        elif c2 == ord('\<') or c2 == ord('}'):
            self._input.consume()
    return True

def enterSubTemplate(self):
    if not(hasattr(self,'subtemplateDepth')):
        self.subtemplateDepth = 0
    self.subtemplateDepth += 1

def exitSubTemplate(self):
    if not(hasattr(self,'subtemplateDepth')):
        self.subtemplateDepth = 0
    if self.subtemplateDepth > 0:
        self.subtemplateDepth -= 1
        self.popMode()

def subTemplateHasIDs(self):
    i = 1
    while True:
        c = self._input.LA(i)
        cs = chr(c)
        if c == Token.EOF: return True
        elif cs.isalnum() or cs == ',' or cs == '_' or cs.isspace():
           i += 1
           continue
        elif c == ord('|'): return True
        return False

}

import STG2Lexer;