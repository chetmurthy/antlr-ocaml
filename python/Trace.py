import sys
import json

fh = None
_enabled = True

disabled = {
    'ENTER mergeCache_add',
    'EXIT mergeCache_add',
    'ENTER PredictionContext.merge',
    'EXIT PredictionContext.merge',
    'ENTER PredictionContext.mergeSingletons',
    'EXIT PredictionContext.mergeSingletons',
    'ENTER PredictionContext.mergeRoot',
    'EXIT PredictionContext.mergeRoot',
    'ENTER PredictionContext.mergeArrays',
    'EXIT PredictionContext.mergeArrays',

    'Lexer.__init__',
    'Lexer.reset',
    'Lexer.skip',
    'Lexer.more',
    'Lexer.mode',
    'Lexer.pushMode',
    'Lexer.popMode',
    'Lexer.emitToken',
    'Lexer.emit',
    'Lexer.emitEOF',

    'END LexerATNSimulator.addDFAEdge',
    'LexerATNSimulator.__add_state__',
    
}

def start(fname):
    global fh
    fh = open(fname, "w")

def write(s):
    global _enabled
    if _enabled:
        fh.write(s)
        fh.write("\n")

def nowrite(s):
    pass

def writej(j):
    global disabled
    global _enabled
    if _enabled and not (j[0] in disabled):
        s = json.dumps(j, sort_keys=True, indent=4)
        fh.write(s)
        fh.write("\n")

def nowritej(j):
    pass

def disable():
    global _enabled
    orig = _enabled
    _enabled = False
    return orig

def restore(orig):
    global _enabled
    _enabled = orig

def with_disabled(f):
    orig = disable()
    rv = f()
    restore(orig)
    return rv
