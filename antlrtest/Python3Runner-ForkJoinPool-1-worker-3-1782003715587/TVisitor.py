# Generated from /tmp/Python3Runner-ForkJoinPool-1-worker-3-1782003715587/T.g4 by ANTLR 4.13.2
from antlr4 import *
if "." in __name__:
    from .TParser import TParser
else:
    from TParser import TParser

# This class defines a complete generic visitor for a parse tree produced by TParser.

class TVisitor(ParseTreeVisitor):

    # Visit a parse tree produced by TParser#a.
    def visitA(self, ctx:TParser.AContext):
        return self.visitChildren(ctx)



del TParser