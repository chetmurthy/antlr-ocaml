import Trace
Trace.start("json.log.RAW")
import Util
<if(!python3)>from __future__ import print_function<endif>
import sys
import codecs
import argparse
from antlr4 import *
from <lexerName> import <lexerName>

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
    parser.add_argument('--named-types',action='store_true')
    parser.add_argument('--show-dfa',action='store_true')
    args = parser.parse_args()
    if args.disable_logging: Trace.disable()
    txt = Util.file_contents(args.input, encoding='utf-8', errors='replace')
    input = InputStream(txt)
    lexer = <lexerName>(input)
    stream = CommonTokenStream(lexer)
    stream.fill()
    if args.named_types:
        [ print(Token__str(lexer, t)) for t in stream.tokens ]
    else:
        [ print(<if(python3)>t<else>unicode(t)<endif>) for t in stream.tokens ]
    if args.show_dfa:
        print(lexer._interp.decisionToDFA[Lexer.DEFAULT_MODE].toLexerString(), end='')

def Token__str(lexer, t):
    txt = t.text
    if txt is not None:
        txt = txt.replace("\n","\\n")
        txt = txt.replace("\r","\\r")
        txt = txt.replace("\t","\\t")
    else:
        txt = "\<no text>"
    type_string = lexer.symbolicNames[t.type]
    return ("[@%s,%s:%s='%s',\<%s>,channel=%s,%s:%s]" %
            (t.tokenIndex, t.start, t.stop, txt, type_string,t.channel,t.line,t.column))

if __name__ == '__main__':
    main(sys.argv)

