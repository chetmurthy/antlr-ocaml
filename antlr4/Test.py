import Trace
Trace.start("json.log.RAW")
import Util
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
    [ print(t) for t in stream.tokens ]
if __name__ == '__main__':
    main(sys.argv)
