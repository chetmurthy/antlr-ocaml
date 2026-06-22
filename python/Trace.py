import sys
import json

fh = None

def start(fname):
    global fh
    fh = open(fname, "w")

def write(s):
    fh.write(s)
    fh.write("\n")
