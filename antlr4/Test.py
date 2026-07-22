import Trace
Trace.start("json.log.RAW")
import Util
from io import StringIO
import sys
import codecs
import argparse
from antlr4 import *
from M import M

def main(argv):
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
    lexer = M(input)
    stream = CommonTokenStream(lexer)
    stream.fill()
    [ print(pptoken(lexer,t)) for t in stream.tokens ]

def pptoken(lexer,tok):
    with StringIO() as buf:
        buf.write("[@")
        buf.write(str(tok.tokenIndex))
        buf.write(",")
        buf.write(str(tok.start))
        buf.write(":")
        buf.write(str(tok.stop))
        buf.write("='")
        txt = tok.text
        if txt is not None:
            txt = txt.replace("\n","\\n")
            txt = txt.replace("\r","\\r")
            txt = txt.replace("\t","\\t")
        else:
            txt = "<no text>"
        buf.write(txt)
        buf.write("',<")
        assert (tok.type <= len(lexer.symbolicNames))
        if tok.type < 0 or tok.type >= len(lexer.symbolicNames):
            buf.write(str(tok.type))
        else:
            buf.write(lexer.symbolicNames[tok.type]+"="+str(tok.type))
        buf.write(">")
        if tok.channel > 0:
            buf.write(",channel=")
            buf.write(str(tok.channel))
        buf.write(",")
        buf.write(str(tok.line))
        buf.write(":")
        buf.write(str(tok.column))
        buf.write("]")
        return buf.getvalue()

if __name__ == '__main__':
    main(sys.argv)
