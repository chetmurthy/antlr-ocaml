import Trace

#
# Copyright (c) 2012-2017 The ANTLR Project. All rights reserved.
# Use of this file is governed by the BSD 3-clause license that
# can be found in the LICENSE.txt file in the project root.

# This implementation of {@link TokenStream} loads tokens from a
# {@link TokenSource} on-demand, and places the tokens in a buffer to provide
# access to any previous token by index.
#
# <p>
# This token stream ignores the value of {@link Token#getChannel}. If your
# parser requires the token stream filter tokens to only those on a particular
# channel, such as {@link Token#DEFAULT_CHANNEL} or
# {@link Token#HIDDEN_CHANNEL}, use a filtering token stream such a
# {@link CommonTokenStream}.</p>
from io import StringIO
from antlr4.Token import Token
from antlr4.error.Errors import IllegalStateException

# need forward declaration
Lexer = None

# this is just to keep meaningful parameter types to Parser
class TokenStream(object):

    pass


tokenStreamCounter = 0

class BufferedTokenStream(TokenStream):
    __slots__ = ('tokenSource', 'tokens', 'index', 'fetchedEOF', 'id')

    def __init__(self, tokenSource:Lexer):
        global tokenStreamCounter
        Trace.writej(lambda:[ 'ENTER BufferedTokenStream.__init__', tokenStreamCounter, tokenSource.asdict() ])
        self.id = tokenStreamCounter
        tokenStreamCounter += 1
        # The {@link TokenSource} from which tokens for this stream are fetched.
        self.tokenSource = tokenSource

        # A collection of all tokens fetched from the token source. The list is
        # considered a complete view of the input once {@link #fetchedEOF} is set
        # to {@code true}.
        self.tokens = []

        # The index into {@link #tokens} of the current token (next token to
        # {@link #consume}). {@link #tokens}{@code [}{@link #p}{@code ]} should be
        # {@link #LT LT(1)}.
        #
        # <p>This field is set to -1 when the stream is first constructed or when
        # {@link #setTokenSource} is called, indicating that the first token has
        # not yet been fetched from the token source. For additional information,
        # see the documentation of {@link IntStream} for a description of
        # Initializing Methods.</p>
        self.index = -1

        # Indicates whether the {@link Token#EOF} token has been fetched from
        # {@link #tokenSource} and added to {@link #tokens}. This field improves
        # performance for the following cases:
        #
        # <ul>
        # <li>{@link #consume}: The lookahead check in {@link #consume} to prevent
        # consuming the EOF symbol is optimized by checking the values of
        # {@link #fetchedEOF} and {@link #p} instead of calling {@link #LA}.</li>
        # <li>{@link #fetch}: The check to prevent adding multiple EOF symbols into
        # {@link #tokens} is trivial with this field.</li>
        # <ul>
        self.fetchedEOF = False
        Trace.writej(lambda:[ 'EXIT BufferedTokenStream.__init__', self.asdict(terse=False) ])

    def asdict(self, terse=True):
        if terse:
            return ["BufferedTokenStreamTerse", {
                'id' : self.id,
                'index' : self.index,
                'fetchedEOF' : self.fetchedEOF,
            }]
        else:
            return ["BufferedTokenStream", {
                'id' : self.id,
                'tokenSource' : self.tokenSource.asdict(),
                'tokens' : [ t.asdict() for t in self.tokens ],
                'index' : self.index,
                'fetchedEOF' : self.fetchedEOF,
            }]


    def mark(self):
        Trace.writej(lambda:[ 'ENTER BufferedTokenStream.mark', self.asdict() ])
        rv = self._mark()
        Trace.writej(lambda:[ 'EXIT BufferedTokenStream.mark', self.asdict(), rv ])
        return rv

    def _mark(self):
        return 0

    def release(self, marker:int):
        Trace.writej(lambda:[ 'ENTER BufferedTokenStream.release', self.asdict(), marker ])
        rv = self._release(marker)
        Trace.writej(lambda:[ 'EXIT BufferedTokenStream.release', self.asdict(), rv ])
        return rv

    def _release(self, marker:int):
        # no resources to release
        pass


    def reset(self):
        Trace.writej(lambda:[ 'ENTER BufferedTokenStream.reset', self.asdict() ])
        rv = self._reset()
        Trace.writej(lambda:[ 'EXIT BufferedTokenStream.reset', self.asdict(terse=False), rv ])
        return rv

    def _reset(self):
        self.seek(0)

    def seek(self, marker:int):
        Trace.writej(lambda:[ 'ENTER BufferedTokenStream.seek', self.asdict(), marker ])
        rv = self._seek(marker)
        Trace.writej(lambda:[ 'EXIT BufferedTokenStream.seek', self.asdict(), rv ])
        return rv

    def _seek(self, index:int):
        self.lazyInit()
        self.index = self.adjustSeekIndex(index)


    def get(self, marker:int):
        Trace.writej(lambda:[ 'ENTER BufferedTokenStream.get', self.asdict(), marker ])
        rv = self._get(marker)
        Trace.writej(lambda:[ 'EXIT BufferedTokenStream.get', self.asdict(), rv.asdict() ])
        return rv

    def _get(self, index:int):
        self.lazyInit()
        return self.tokens[index]

    def consume(self):
        Trace.writej(lambda:[ 'ENTER BufferedTokenStream.consume', self.asdict() ])
        rv = self._consume()
        Trace.writej(lambda:[ 'EXIT BufferedTokenStream.consume', self.asdict(), rv ])
        return rv

    def _consume(self):
        skipEofCheck = False
        if self.index >= 0:
            if self.fetchedEOF:
                # the last token in tokens is EOF. skip check if p indexes any
                # fetched token except the last.
                skipEofCheck = self.index < len(self.tokens) - 1
            else:
               # no EOF token in tokens. skip check if p indexes a fetched token.
                skipEofCheck = self.index < len(self.tokens)
        else:
            # not yet initialized
            skipEofCheck = False

        if not skipEofCheck and self.LA(1) == Token.EOF:
            raise IllegalStateException("cannot consume EOF")

        if self.sync(self.index + 1):
            self.index = self.adjustSeekIndex(self.index + 1)


    def sync(self, marker:int):
        Trace.writej(lambda:[ 'ENTER BufferedTokenStream.sync', self.asdict(), marker ])
        rv = self._sync(marker)
        Trace.writej(lambda:[ 'EXIT BufferedTokenStream.sync', self.asdict(), rv ])
        return rv

    # Make sure index {@code i} in tokens has a token.
    #
    # @return {@code true} if a token is located at index {@code i}, otherwise
    #    {@code false}.
    # @see #get(int i)
    #/
    def _sync(self, i:int):
        n = i - len(self.tokens) + 1 # how many more elements we need?
        if n > 0 :
            fetched = self.fetch(n)
            return fetched >= n
        return True

    def fetch(self, marker:int):
        Trace.writej(lambda:[ 'ENTER BufferedTokenStream.fetch', self.asdict(), marker ])
        rv = self._fetch(marker)
        Trace.writej(lambda:[ 'EXIT BufferedTokenStream.fetch', self.asdict(), rv ])
        return rv

    # Add {@code n} elements to buffer.
    #
    # @return The actual number of elements added to the buffer.
    #/
    def _fetch(self, n:int):
        if self.fetchedEOF:
            return 0
        for i in range(0, n):
            t = self.tokenSource.nextToken()
            t.tokenIndex = len(self.tokens)
            self.tokens.append(t)
            if t.type==Token.EOF:
                self.fetchedEOF = True
                return i + 1
        return n


    def getTokens(self, start:int, stop:int, types:set=None):
        Trace.writej(lambda:[ 'ENTER BufferedTokenStream.getTokens',
                              self.asdict(),
                              start,
                              stop,
                              sorted([t for t in types])
                             ])
        rv = self._getTokens(marker)
        Trace.writej(lambda:[ 'EXIT BufferedTokenStream.getTokens',
                              self.asdict(),
                              [x.asdict() for x in rv]
                             ])
        return rv

    # Get all tokens from start..stop inclusively#/
    def _getTokens(self, start:int, stop:int, types:set=None):
        if start<0 or stop<0:
            return None
        self.lazyInit()
        subset = []
        if stop >= len(self.tokens):
            stop = len(self.tokens)-1
        for i in range(start, stop):
            t = self.tokens[i]
            if t.type==Token.EOF:
                break
            if types is None or t.type in types:
                subset.append(t)
        return subset


    def LA(self, marker:int):
        Trace.writej(lambda:[ 'ENTER BufferedTokenStream.LA', self.asdict(), marker ])
        rv = self._LA(marker)
        Trace.writej(lambda:[ 'EXIT BufferedTokenStream.LA', self.asdict(), rv ])
        return rv

    def _LA(self, i:int):
        return self.LT(i).type


    def LB(self, marker:int):
        Trace.writej(lambda:[ 'ENTER BufferedTokenStream.LB', self.asdict(), marker ])
        rv = self._LB(marker)
        Trace.writej(lambda:[ 'EXIT BufferedTokenStream.LB',
                              self.asdict(),
                              rv.asdict()
                             ])
        return rv

    def _LB(self, k:int):
        if (self.index-k) < 0:
            return None
        return self.tokens[self.index-k]


    def LT(self, marker:int):
        Trace.writej(lambda:[ 'ENTER BufferedTokenStream.LT', self.asdict(), marker ])
        rv = self._LT(marker)
        Trace.writej(lambda:[ 'EXIT BufferedTokenStream.LT',
                              self.asdict(),
                              rv.asdict()
                             ])
        return rv


    def _LT(self, k:int):
        self.lazyInit()
        if k==0:
            return None
        if k < 0:
            return self.LB(-k)
        i = self.index + k - 1
        self.sync(i)
        if i >= len(self.tokens): # return EOF token
            # EOF must be last token
            return self.tokens[len(self.tokens)-1]
        return self.tokens[i]

    # Allowed derived classes to modify the behavior of operations which change
    # the current stream position by adjusting the target token index of a seek
    # operation. The default implementation simply returns {@code i}. If an
    # exception is thrown in this method, the current stream index should not be
    # changed.
    #
    # <p>For example, {@link CommonTokenStream} overrides this method to ensure that
    # the seek target is always an on-channel token.</p>
    #
    # @param i The target token index.
    # @return The adjusted target token index.

    def adjustSeekIndex(self, marker:int):
        Trace.writej(lambda:[ 'ENTER BufferedTokenStream.adjustSeekIndex', self.asdict(), marker ])
        rv = self._adjustSeekIndex(marker)
        Trace.writej(lambda:[ 'EXIT BufferedTokenStream.adjustSeekIndex', self.asdict(), rv ])
        return rv

    def _adjustSeekIndex(self, i:int):
        return i

    def lazyInit(self):
        Trace.writej(lambda:[ 'ENTER BufferedTokenStream.lazyInit', self.asdict() ])
        rv = self._lazyInit()
        Trace.writej(lambda:[ 'EXIT BufferedTokenStream.lazyInit', self.asdict(terse=False) ])
        return rv

    def _lazyInit(self):
        if self.index == -1:
            self.setup()

    def setup(self):
        self.sync(0)
        self.index = self.adjustSeekIndex(0)

    def setTokenSource(self, tokenSource):
        Trace.writej(lambda:[ 'ENTER BufferedTokenStream.setTokenSource', self.asdict(), tokenSource.asdict() ])
        rv = self._setTokenSource(tokenSource)
        Trace.writej(lambda:[ 'EXIT BufferedTokenStream.setTokenSource', self.asdict(terse=False), rv ])
        return rv

    # Reset this token stream by setting its token source.#/
    def _setTokenSource(self, tokenSource:Lexer):
        self.tokenSource = tokenSource
        self.tokens = []
        self.index = -1
        self.fetchedEOF = False


    # Given a starting index, return the index of the next token on channel.
    #  Return i if tokens[i] is on channel.  Return the index of the EOF token
    # if there are no tokens on channel between i and EOF.
    #/
    def nextTokenOnChannel(self, i:int, channel:int):
        self.sync(i)
        if i>=len(self.tokens):
            return len(self.tokens) - 1
        token = self.tokens[i]
        while token.channel!=channel:
            if token.type==Token.EOF:
                return i
            i += 1
            self.sync(i)
            token = self.tokens[i]
        return i

    # Given a starting index, return the index of the previous token on channel.
    #  Return i if tokens[i] is on channel. Return -1 if there are no tokens
    #  on channel between i and 0.
    def previousTokenOnChannel(self, i:int, channel:int):
        while i>=0 and self.tokens[i].channel!=channel:
            i -= 1
        return i

    # Collect all tokens on specified channel to the right of
    #  the current token up until we see a token on DEFAULT_TOKEN_CHANNEL or
    #  EOF. If channel is -1, find any non default channel token.
    def getHiddenTokensToRight(self, tokenIndex:int, channel:int=-1):
        self.lazyInit()
        if tokenIndex<0 or tokenIndex>=len(self.tokens):
            raise Exception(str(tokenIndex) + " not in 0.." + str(len(self.tokens)-1))
        from antlr4.Lexer import Lexer
        nextOnChannel = self.nextTokenOnChannel(tokenIndex + 1, Lexer.DEFAULT_TOKEN_CHANNEL)
        from_ = tokenIndex+1
        # if none onchannel to right, nextOnChannel=-1 so set to = last token
        to = (len(self.tokens)-1) if nextOnChannel==-1 else nextOnChannel
        return self.filterForChannel(from_, to, channel)


    # Collect all tokens on specified channel to the left of
    #  the current token up until we see a token on DEFAULT_TOKEN_CHANNEL.
    #  If channel is -1, find any non default channel token.
    def getHiddenTokensToLeft(self, tokenIndex:int, channel:int=-1):
        self.lazyInit()
        if tokenIndex<0 or tokenIndex>=len(self.tokens):
            raise Exception(str(tokenIndex) + " not in 0.." + str(len(self.tokens)-1))
        from antlr4.Lexer import Lexer
        prevOnChannel = self.previousTokenOnChannel(tokenIndex - 1, Lexer.DEFAULT_TOKEN_CHANNEL)
        if prevOnChannel == tokenIndex - 1:
            return None
        # if none on channel to left, prevOnChannel=-1 then from=0
        from_ = prevOnChannel+1
        to = tokenIndex-1
        return self.filterForChannel(from_, to, channel)


    def filterForChannel(self, left:int, right:int, channel:int):
        hidden = []
        for i in range(left, right+1):
            t = self.tokens[i]
            if channel==-1:
                from antlr4.Lexer import Lexer
                if t.channel!= Lexer.DEFAULT_TOKEN_CHANNEL:
                    hidden.append(t)
            elif t.channel==channel:
                    hidden.append(t)
        if len(hidden)==0:
            return None
        return hidden

    def getSourceName(self):
        return self.tokenSource.getSourceName()

    # Get the text of all tokens in this buffer.#/
    def getText(self, start:int=None, stop:int=None):
        self.lazyInit()
        self.fill()
        if isinstance(start, Token):
            start = start.tokenIndex
        elif start is None:
            start = 0
        if isinstance(stop, Token):
            stop = stop.tokenIndex
        elif stop is None or stop >= len(self.tokens):
            stop = len(self.tokens) - 1
        if start < 0 or stop < 0 or stop < start:
            return ""
        with StringIO() as buf:
            for i in range(start, stop+1):
                t = self.tokens[i]
                if t.type==Token.EOF:
                    break
                buf.write(t.text)
            return buf.getvalue()


    def fill(self):
        Trace.writej(lambda:[ 'ENTER BufferedTokenStream.fill', self.asdict() ])
        rv = self._fill()
        Trace.writej(lambda:[ 'EXIT BufferedTokenStream.fill', self.asdict(terse=False) ])
        return rv

    # Get all tokens from lexer until EOF#/
    def _fill(self):
        self.lazyInit()
        while self.fetch(1000)==1000:
            pass
