import sys
import json

fh = None
_enabled = True

disabled = {
#    "ENTER ATNConfigSet.add",
#    "EXIT ATNConfigSet.add",
#    "ENTER ATNConfigSet.__init__",
#    "EXIT ATNConfigSet.__init__",
#    "ENTER ATNConfigSet.__eq__",
#    "EXIT ATNConfigSet.__eq__",
#    "ENTER ATNConfigSet.set_DIOC",
#    "EXIT ATNConfigSet.set_DIOC",
#    "ENTER ATNConfigSet.setReadonly",
#    "EXIT ATNConfigSet.setReadonly",
#    "ENTER ATNConfigSet.update_HSC",
#    "EXIT ATNConfigSet.update_HSC",
#    "ENTER ATNConfigSet.set_UA",
#    "EXIT ATNConfigSet.set_UA",
#    "ENTER ATNConfigSet.set_CA",
#    "EXIT ATNConfigSet.set_CA",
#    "ENTER ATNConfigSet.getOrAdd",
#    "EXIT ATNConfigSet.getOrAdd",
#    'ATNConfigSet.optimizeConfigs',
#    "ENTER OrderedATNConfigSet.__init__",
#    "EXIT OrderedATNConfigSet.__init__",

#    "ENTER ATNConfig.__init__",
#    "EXIT ATNConfig.__init__",
#    "ENTER ATNConfig.__eq__",
#    "EXIT ATNConfig.__eq__",
#    "ENTER ATNConfig.equalsForConfigSet",
#    "EXIT ATNConfig.equalsForConfigSet",
#    "ENTER ATNConfig.incrementRIOC",
#    "EXIT ATNConfig.incrementRIOC",
#    "ENTER ATNConfig.update_RIOC",
#    "EXIT ATNConfig.update_RIOC",
#    "ENTER ATNConfig.set_PFS",
#    "EXIT ATNConfig.set_PFS",

#    "ENTER LexerATNConfig.__init__",
#    "EXIT LexerATNConfig.__init__",
#    "ENTER LexerATNConfig.__eq__",
#    "EXIT LexerATNConfig.__eq__",

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
    
#    "ENTER DFA.__init__",
#    "EXIT DFA.__init__",
#    "ENTER DFA.set_s0",
#    "EXIT DFA.set_s0",
#    "ENTER DFA.states_add",
#    "EXIT DFA.states_add",
#    "ENTER DFA.states_get",
#    "EXIT DFA.states_get",
#    "ENTER DFA.states_len",
#    "EXIT DFA.states_len",

#    "ENTER DFAState.__init__",
#    "EXIT DFAState.__init__",
#    "ENTER DFAState.makeEdges",
#    "EXIT DFAState.makeEdges",
#    "ENTER DFAState.setEdge",
#    "EXIT DFAState.setEdge",
#    "ENTER DFAState.set_isAcceptState",
#    "EXIT DFAState.set_isAcceptState",
#    "ENTER DFAState.set_lexerActionExecutor",
#    "EXIT DFAState.set_lexerActionExecutor",
#    "ENTER DFAState.set_prediction",
#    "EXIT DFAState.set_prediction",
#    "ENTER DFAState.set_stateNumber",
#    "EXIT DFAState.set_stateNumber",

    "ENTER LexerATNSimulator.__init__",
    "EXIT LexerATNSimulator.__init__",
    "ENTER LexerATNSimulator.match",
    "EXIT LexerATNSimulator.match",
    "ENTER Lexer.nextToken",
    "EXIT Lexer.nextToken",

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
    'EXIT ParserATNSimulator.__init__',
    
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
