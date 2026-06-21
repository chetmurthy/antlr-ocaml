import sys
import codecs
from antlr4 import *
from TLexer import TLexer
from TParser import TParser
from TListener import TListener
from TVisitor import TVisitor

class TreeShapeListener(ParseTreeListener):

    def visitTerminal(self, node:TerminalNode):
        pass

    def visitErrorNode(self, node:ErrorNode):
        pass

    def exitEveryRule(self, ctx:ParserRuleContext):
        pass

    def enterEveryRule(self, ctx:ParserRuleContext):
        for child in ctx.getChildren():
            parent = child.parentCtx
            if not isinstance(parent, RuleNode) or parent.getRuleContext() != ctx:
                raise IllegalStateException("Invalid parse tree shape detected.")

def main(argv):
    input = FileStream(argv[1], encoding='utf-8', errors='replace')
    lexer = TLexer(input)
    stream = CommonTokenStream(lexer)
    parser = TParser(stream)
    parser._interp.predictionMode = PredictionMode.LL
    tree = parser.a()
    ParseTreeWalker.DEFAULT.walk(TreeShapeListener(), tree)
if __name__ == '__main__':
    main(sys.argv)

