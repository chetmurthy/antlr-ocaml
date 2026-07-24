import Trace
Trace.start("json.log.RAW")
import Util
<if(!python3)>from __future__ import print_function<endif>
import sys
import codecs
import argparse
from antlr4 import *
from <lexerName> import <lexerName>
<if(parserName)>
from <parserName> import <parserName>
from <grammarName>Listener import <grammarName>Listener
from <grammarName>Visitor import <grammarName>Visitor

class TreeShapeListener(ParseTreeListener):

    def visitTerminal(self, node<if(python3)>:TerminalNode<endif>):
        pass

    def visitErrorNode(self, node<if(python3)>:ErrorNode<endif>):
        pass

    def exitEveryRule(self, ctx<if(python3)>:ParserRuleContext<endif>):
        pass

    def enterEveryRule(self, ctx<if(python3)>:ParserRuleContext<endif>):
        for child in ctx.getChildren():
            parent = child.parentCtx
            if not isinstance(parent, RuleNode) or parent.getRuleContext() != ctx:
                raise IllegalStateException("Invalid parse tree shape detected.")
<endif>

def main(argv):
<if(traceATN)>
    ParserATNSimulator.trace_atn_sim = True
    PredictionContext._trace_atn_sim = True
<endif>
    parser = argparse.ArgumentParser(
                    prog='Test',
                    description='Test',
                    epilog='Test')
    parser.add_argument('input')
    parser.add_argument('--disable-logging',action='store_true')
    args = parser.parse_args()
    if args.disable_logging: Trace.disable()
    txt = Util.file_contents(args.input, encoding='utf-8', errors='replace')
    input = InputStream(txt)
    lexer = <lexerName>(input)
    stream = CommonTokenStream(lexer)
<if(parserName)>
    parser = <parserName>(stream)
    parser._interp.predictionMode = PredictionMode.<predictionMode>
<if(!buildParseTree)>
    parser.buildParseTrees = False
<endif>
<if(showDiagnosticErrors)>
    parser.addErrorListener(DiagnosticErrorListener())
<endif>
    tree = parser.<parserStartRuleName>()
    ParseTreeWalker.DEFAULT.walk(TreeShapeListener(), tree)
<else>
    stream.fill()
    [ print(<if(python3)>t<else>unicode(t)<endif>) for t in stream.tokens ]
<if(showDFA)>
    print(lexer._interp.decisionToDFA[Lexer.DEFAULT_MODE].toLexerString(), end='')
<endif>
<endif>

if __name__ == '__main__':
    main(sys.argv)

