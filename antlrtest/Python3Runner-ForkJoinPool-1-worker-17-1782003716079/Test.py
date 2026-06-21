import sys
import codecs
from antlr4 import *
from L import L
def main(argv):
    input = FileStream(argv[1], encoding='utf-8', errors='replace')
    lexer = L(input)
    stream = CommonTokenStream(lexer)
    stream.fill()
    [ print(t) for t in stream.tokens ]
if __name__ == '__main__':
    main(sys.argv)

