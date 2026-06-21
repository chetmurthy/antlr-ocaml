# Generated from /tmp/Python3Runner-ForkJoinPool-1-worker-17-1782003716079/L.g4 by ANTLR 4.13.2
from antlr4 import *
from io import StringIO
import sys
if sys.version_info[1] > 5:
    from typing import TextIO
else:
    from typing.io import TextIO


def serializedATN():
    return [
        4,0,2,16,6,-1,2,0,7,0,2,1,7,1,1,0,4,0,7,8,0,11,0,12,0,8,1,0,1,0,
        1,1,1,1,1,1,1,1,0,0,2,1,1,3,2,1,0,1,3,0,10,10,13,13,32,32,16,0,1,
        1,0,0,0,0,3,1,0,0,0,1,6,1,0,0,0,3,12,1,0,0,0,5,7,2,48,57,0,6,5,1,
        0,0,0,7,8,1,0,0,0,8,6,1,0,0,0,8,9,1,0,0,0,9,10,1,0,0,0,10,11,6,0,
        0,0,11,2,1,0,0,0,12,13,7,0,0,0,13,14,1,0,0,0,14,15,6,1,1,0,15,4,
        1,0,0,0,2,0,8,2,1,0,0,6,0,0
    ]

class L(Lexer):

    atn = ATNDeserializer().deserialize(serializedATN())

    decisionsToDFA = [ DFA(ds, i) for i, ds in enumerate(atn.decisionToState) ]

    I = 1
    WS = 2

    channelNames = [ u"DEFAULT_TOKEN_CHANNEL", u"HIDDEN" ]

    modeNames = [ "DEFAULT_MODE" ]

    literalNames = [ "<INVALID>",
 ]

    symbolicNames = [ "<INVALID>",
            "I", "WS" ]

    ruleNames = [ "I", "WS" ]

    grammarFileName = "L.g4"

    def __init__(self, input=None, output:TextIO = sys.stdout):
        super().__init__(input, output)
        self.checkVersion("4.13.2")
        self._interp = LexerATNSimulator(self, self.atn, self.decisionsToDFA, PredictionContextCache())
        self._actions = None
        self._predicates = None


    def action(self, localctx:RuleContext, ruleIndex:int, actionIndex:int):
        if self._actions is None:
            actions = dict()
            actions[0] = self.I_action 
            self._actions = actions
        action = self._actions.get(ruleIndex, None)
        if action is not None:
            action(localctx, actionIndex)
        else:
            raise Exception("No registered action for:" + str(ruleIndex))


    def I_action(self, localctx:RuleContext , actionIndex:int):
        if actionIndex == 0:
            print("I", file=self._output)
     


