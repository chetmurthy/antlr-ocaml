lexer grammar M;

@lexer::members {

def handleBeginArgument(self):
    if self.inLexerRule():
        self.pushMode(2)
        self.more()
    else:
        self.pushMode(1)

def handleEndArgument(self):
    self.popMode()
    assert(len(self._modeStack) == 0)

def inLexerRule(self):
    return True
}

import ANTLRv4Lexer;