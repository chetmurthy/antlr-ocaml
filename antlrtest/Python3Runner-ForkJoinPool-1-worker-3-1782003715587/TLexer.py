# Generated from /tmp/Python3Runner-ForkJoinPool-1-worker-3-1782003715587/T.g4 by ANTLR 4.13.2
from antlr4 import *
from io import StringIO
import sys
if sys.version_info[1] > 5:
    from typing import TextIO
else:
    from typing.io import TextIO


def serializedATN():
    return [
        4,0,3,21,6,-1,2,0,7,0,2,1,7,1,2,2,7,2,1,0,4,0,9,8,0,11,0,12,0,10,
        1,1,4,1,14,8,1,11,1,12,1,15,1,2,1,2,1,2,1,2,0,0,3,1,1,3,2,5,3,1,
        0,1,2,0,10,10,32,32,22,0,1,1,0,0,0,0,3,1,0,0,0,0,5,1,0,0,0,1,8,1,
        0,0,0,3,13,1,0,0,0,5,17,1,0,0,0,7,9,2,97,122,0,8,7,1,0,0,0,9,10,
        1,0,0,0,10,8,1,0,0,0,10,11,1,0,0,0,11,2,1,0,0,0,12,14,2,48,57,0,
        13,12,1,0,0,0,14,15,1,0,0,0,15,13,1,0,0,0,15,16,1,0,0,0,16,4,1,0,
        0,0,17,18,7,0,0,0,18,19,1,0,0,0,19,20,6,2,0,0,20,6,1,0,0,0,3,0,10,
        15,1,6,0,0
    ]

class TLexer(Lexer):

    atn = ATNDeserializer().deserialize(serializedATN())

    decisionsToDFA = [ DFA(ds, i) for i, ds in enumerate(atn.decisionToState) ]

    ID = 1
    INT = 2
    WS = 3

    channelNames = [ u"DEFAULT_TOKEN_CHANNEL", u"HIDDEN" ]

    modeNames = [ "DEFAULT_MODE" ]

    literalNames = [ "<INVALID>",
 ]

    symbolicNames = [ "<INVALID>",
            "ID", "INT", "WS" ]

    ruleNames = [ "ID", "INT", "WS" ]

    grammarFileName = "T.g4"

    def __init__(self, input=None, output:TextIO = sys.stdout):
        super().__init__(input, output)
        self.checkVersion("4.13.2")
        self._interp = LexerATNSimulator(self, self.atn, self.decisionsToDFA, PredictionContextCache())
        self._actions = None
        self._predicates = None


