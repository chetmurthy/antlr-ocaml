import Trace
import json
import traceback

#
# Copyright (c) 2012-2017 The ANTLR Project. All rights reserved.
# Use of this file is governed by the BSD 3-clause license that
# can be found in the LICENSE.txt file in the project root.
#/

# A tuple: (ATN state, predicted alt, syntactic, semantic context).
#  The syntactic context is a graph-structured stack node whose
#  path(s) to the root is the rule invocation(s)
#  chain used to arrive at the state.  The semantic context is
#  the tree of semantic predicates encountered before reaching
#  an ATN state.
#/
from io import StringIO
from antlr4.PredictionContext import PredictionContext
from antlr4.atn.ATNState import ATNState, DecisionState
from antlr4.atn.LexerActionExecutor import LexerActionExecutor
from antlr4.atn.SemanticContext import SemanticContext

# need a forward declaration
ATNConfig = None

configCounter = 0

class ATNConfig(object):
    __slots__ = (
        'state', 'alt', 'context', 'semanticContext', 'reachesIntoOuterContext',
        'precedenceFilterSuppressed', 'id'

    )

    def __init__(self, state:ATNState=None, alt:int=None, context:PredictionContext=None, semantic:SemanticContext=None, config:ATNConfig=None):
        global configCounter
        self.id = configCounter
        Trace.write(json.dumps([ 'ENTER ATNConfig.__init__', self.id,
                                 (None if state is None else state.stateNumber),
                                 (None if alt is None else alt),
                                 (None if context is None else context.asdict()),
                                 (None if semantic is None else semantic.asdict()),
                                 (None if config is None else config.asdict())
                                ],
                               sort_keys=True, indent=4))
        configCounter += 1
        if config is not None:
            if state is None:
                state = config.state
            if alt is None:
                alt = config.alt
            if context is None:
                context = config.context
            if semantic is None:
                semantic = config.semanticContext
        if semantic is None:
            semantic = SemanticContext.NONE
        assert (state is not None)
        assert (alt is not None)
#        assert (context is not None)
        assert (semantic is not None)
        # The ATN state associated with this configuration#/
        self.state = state
        # What alt (or lexer rule) is predicted by this configuration#/
        self.alt = alt
        # The stack of invoking states leading to the rule/states associated
        #  with this config.  We track only those contexts pushed during
        #  execution of the ATN simulator.
        self.context = context
        self.semanticContext = semantic
        # We cannot execute predicates dependent upon local context unless
        # we know for sure we are in the correct context. Because there is
        # no way to do this efficiently, we simply cannot evaluate
        # dependent predicates unless we are in the rule that initially
        # invokes the ATN simulator.
        #
        # closure() tracks the depth of how far we dip into the
        # outer context: depth &gt; 0.  Note that it may not be totally
        # accurate depth since I don't ever decrement. TODO: make it a boolean then
        self.reachesIntoOuterContext = 0 if config is None else config.reachesIntoOuterContext
        self.precedenceFilterSuppressed = False if config is None else config.precedenceFilterSuppressed
        Trace.write(json.dumps([ 'EXIT ATNConfig.__init__',
                                 ATNConfig.asdict(self)
                                ],
                               sort_keys=True, indent=4))

    def asdict(self):
        d = {
            'id' : self.id,
            'state' : self.state.stateNumber,
            'alt' : self.alt,
            'context' : None if self.context is None else self.context.asdict(),
            'semanticContext' : self.semanticContext.asdict(),
            'reachesIntoOuterContext' : self.reachesIntoOuterContext,
            'precedenceFilterSuppressed' : self.precedenceFilterSuppressed,
        }
        return ["ATNConfig", d]

    # An ATN configuration is equal to another if both have
    #  the same state, they predict the same alternative, and
    #  syntactic/semantic contexts are the same.
    #/
    def real__eq__(self, other):
        if self is other:
            return True
        elif not isinstance(other, ATNConfig):
            return False
        else:
            return self.state.stateNumber==other.state.stateNumber \
                and self.alt==other.alt \
                and ((self.context is other.context) or (self.context==other.context)) \
                and self.semanticContext==other.semanticContext \
                and self.precedenceFilterSuppressed==other.precedenceFilterSuppressed

    def __eq__(self, other):
        rv = self.real__eq__(other)
        Trace.write(json.dumps([ 'ATNConfig.__eq__',
                                 self.asdict(), other.asdict(), rv ],
                               sort_keys=True, indent=4))
        return rv

    def strkey(self):
        return ("%s/%s" % (self.hashkey(), str(self.context)))

    def hashkey(self):
        return ("%d/%d/%s" % (self.state.stateNumber, self.alt, str(self.semanticContext)))

    def __hash__(self):
        return hash((self.state.stateNumber, self.alt, self.context, self.semanticContext))

    def hashCodeForConfigSet(self):
#        return hash((self.state.stateNumber, self.alt, hash(self.semanticContext)))
        return self.hashkey()

    def _equalsForConfigSet(self, other):
        if self is other:
            return True
        elif not isinstance(other, ATNConfig):
            return False
        else:
            return self.state.stateNumber==other.state.stateNumber \
                and self.alt==other.alt \
                and self.semanticContext==other.semanticContext

    def equalsForConfigSet(self, other):
        rv = self._equalsForConfigSet(other)
        Trace.nowrite(json.dumps([ 'ATNConfig.equalsForConfigSet',
                                 self.asdict(), other.asdict(), rv ],
                               sort_keys=True, indent=4))
        return rv

    def __str__(self):
        with StringIO() as buf:
            buf.write('(')
            buf.write(str(self.state))
            buf.write(",")
            buf.write(str(self.alt))
            if self.context is not None:
                buf.write(",[")
                buf.write(str(self.context))
                buf.write("]")
            if self.semanticContext is not None and self.semanticContext is not SemanticContext.NONE:
                buf.write(",")
                buf.write(str(self.semanticContext))
            if self.reachesIntoOuterContext>0:
                buf.write(",up=")
                buf.write(str(self.reachesIntoOuterContext))
            buf.write(')')
            return buf.getvalue()

    def incrementRIOC(self):
        Trace.write(json.dumps([ 'ENTER ATNConfig.incrementRIOC',
                                 self.asdict()
                                ],
                               sort_keys=True, indent=4))
        self.reachesIntoOuterContext += 1
        Trace.write(json.dumps([ 'EXIT ATNConfig.incrementRIOC',
                                 self.asdict()
                                ],
                               sort_keys=True, indent=4))

    def update_RIOC(self, v):
        Trace.write(json.dumps([ 'ENTER ATNConfig.update_RIOC',
                                 self.asdict(),
                                 v
                                ],
                               sort_keys=True, indent=4))
        self.reachesIntoOuterContext = v
        Trace.write(json.dumps([ 'EXIT ATNConfig.update_RIOC',
                                 self.asdict()
                                ],
                               sort_keys=True, indent=4))

    def set_PFS(self):
        Trace.write(json.dumps([ 'ENTER ATNConfig.set_PFS',
                                 self.asdict(),
                                ],
                               sort_keys=True, indent=4))
        self.precedenceFilterSuppressed = True
        Trace.write(json.dumps([ 'EXIT ATNConfig.set_PFS',
                                 self.asdict()
                                ],
                               sort_keys=True, indent=4))


# need a forward declaration
LexerATNConfig = None

class LexerATNConfig(ATNConfig):
    __slots__ = ('lexerActionExecutor', 'passedThroughNonGreedyDecision')

    def __init__(self, state:ATNState, alt:int=None, context:PredictionContext=None, semantic:SemanticContext=SemanticContext.NONE,
                 lexerActionExecutor:LexerActionExecutor=None, config:LexerATNConfig=None):
        Trace.write(json.dumps([ 'ENTER LexerATNConfig.__init__',
                                 (None if state is None else state.stateNumber),
                                 (None if alt is None else alt),
                                 (None if context is None else context.asdict()),
                                 (None if semantic is None else semantic.asdict()),
                                 (None if lexerActionExecutor is None else lexerActionExecutor.asdict()),
                                 (None if config is None else config.asdict())
                                ],
                               sort_keys=True, indent=4))
        super().__init__(state=state, alt=alt, context=context, semantic=semantic, config=config)
        if config is not None:
            if lexerActionExecutor is None:
                lexerActionExecutor = config.lexerActionExecutor
        # This is the backing field for {@link #getLexerActionExecutor}.
        self.lexerActionExecutor = lexerActionExecutor
        self.passedThroughNonGreedyDecision = False if config is None else self.checkNonGreedyDecision(config, state)
        Trace.write(json.dumps([ 'EXIT LexerATNConfig.__init__',
                                 self.asdict()
                                ],
                               sort_keys=True, indent=4))

    def asdict(self):
        d = super(LexerATNConfig, self).asdict()[1]
        if hasattr(self,'lexerActionExecutor'):
            d['lexerActionExecutor'] = None if self.lexerActionExecutor is None else self.lexerActionExecutor.asdict()
        if hasattr(self,'passedThroughNonGreedyDecision'):
            d['passedThroughNonGreedyDecision'] = self.passedThroughNonGreedyDecision
        return ["LexerATNConfig", d]

    def real__eq__(self, other):
        if self is other:
            return True
        elif not isinstance(other, LexerATNConfig):
            return False
        if self.passedThroughNonGreedyDecision != other.passedThroughNonGreedyDecision:
            return False
        if not(self.lexerActionExecutor == other.lexerActionExecutor):
            return False
        return super().real__eq__(other)

    def __eq__(self, other):
        rv = self.real__eq__(other)
#        traceback.print_stack(file=Trace.fh)
        Trace.write(json.dumps([ 'LexerATNConfig.__eq__',
                                 self.asdict(), other.asdict(), rv ],
                               sort_keys=True, indent=4))
        return rv

    def __hash__(self):
        return hash((self.state.stateNumber, self.alt, self.context,
                self.semanticContext, self.passedThroughNonGreedyDecision,
                self.lexerActionExecutor))

    def hashkey(self):
        return ("%d/%d/%s/%s/%s/%s" % (self.state.stateNumber, self.alt, self.context,
                                       str(self.semanticContext),
                                       self.passedThroughNonGreedyDecision,
                                       str(self.lexerActionExecutor)
                                       ))

    def strkey(self):
        return self.hashkey()

    def hashCodeForConfigSet(self):
#        return hash(self)
        return self.hashkey()


    def equalsForConfigSet(self, other):
        return self==other



    def checkNonGreedyDecision(self, source:LexerATNConfig, target:ATNState):
        return source.passedThroughNonGreedyDecision \
            or isinstance(target, DecisionState) and target.nonGreedy
