# Generated from /tmp/Python3Runner-ForkJoinPool-1-worker-3-1782003715587/T.g4 by ANTLR 4.13.2
# encoding: utf-8
from antlr4 import *
from io import StringIO
import sys
if sys.version_info[1] > 5:
	from typing import TextIO
else:
	from typing.io import TextIO

def serializedATN():
    return [
        4,1,3,7,2,0,7,0,1,0,1,0,1,0,1,0,1,0,0,0,1,0,0,0,5,0,2,1,0,0,0,2,
        3,5,1,0,0,3,4,5,2,0,0,4,5,6,0,-1,0,5,1,1,0,0,0,0
    ]

class TParser ( Parser ):

    grammarFileName = "T.g4"

    atn = ATNDeserializer().deserialize(serializedATN())

    decisionsToDFA = [ DFA(ds, i) for i, ds in enumerate(atn.decisionToState) ]

    sharedContextCache = PredictionContextCache()

    literalNames = [  ]

    symbolicNames = [ "<INVALID>", "ID", "INT", "WS" ]

    RULE_a = 0

    ruleNames =  [ "a" ]

    EOF = Token.EOF
    ID=1
    INT=2
    WS=3

    def __init__(self, input:TokenStream, output:TextIO = sys.stdout):
        super().__init__(input, output)
        self.checkVersion("4.13.2")
        self._interp = ParserATNSimulator(self, self.atn, self.decisionsToDFA, self.sharedContextCache)
        self._predicates = None




    class AContext(ParserRuleContext):
        __slots__ = 'parser'

        def __init__(self, parser, parent:ParserRuleContext=None, invokingState:int=-1):
            super().__init__(parent, invokingState)
            self.parser = parser

        def ID(self):
            return self.getToken(TParser.ID, 0)

        def INT(self):
            return self.getToken(TParser.INT, 0)

        def getRuleIndex(self):
            return TParser.RULE_a

        def enterRule(self, listener:ParseTreeListener):
            if hasattr( listener, "enterA" ):
                listener.enterA(self)

        def exitRule(self, listener:ParseTreeListener):
            if hasattr( listener, "exitA" ):
                listener.exitA(self)

        def accept(self, visitor:ParseTreeVisitor):
            if hasattr( visitor, "visitA" ):
                return visitor.visitA(self)
            else:
                return visitor.visitChildren(self)




    def a(self):

        localctx = TParser.AContext(self, self._ctx, self.state)
        self.enterRule(localctx, 0, self.RULE_a)
        try:
            self.enterOuterAlt(localctx, 1)
            self.state = 2
            self.match(TParser.ID)
            self.state = 3
            self.match(TParser.INT)

            print(self._input.getText(localctx.start, self._input.LT(-1)), file=self._output)

        except RecognitionException as re:
            localctx.exception = re
            self._errHandler.reportError(self, re)
            self._errHandler.recover(self, re)
        finally:
            self.exitRule()
        return localctx





