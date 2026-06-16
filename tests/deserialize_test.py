import sys

sys.path
sys.path.append('../python')

from antlr4 import *
from antlr4.atn.ATNType import ATNType
from antlr4.atn.ATNState import *
import re

def extract_atn(txt):
    rex = re.compile(r"atn:\s*(\[[^]]+\])")
    res = rex.search(txt)
    txt = res.group(1)
#    print(txt)
    atn = eval(txt)
    return(atn)

def main(args):
    fname = args[1]
    print("Filename: %s" % fname)
    with open(fname) as f: s = f.read()
    ser_atn = extract_atn(s)
    des = ATNDeserializer()
    atn = des.deserialize(ser_atn)
    atn.dump()
    

if __name__ == '__main__':
    main(sys.argv)
