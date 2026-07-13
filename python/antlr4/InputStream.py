import Trace

#
# Copyright (c) 2012-2017 The ANTLR Project. All rights reserved.
# Use of this file is governed by the BSD 3-clause license that
# can be found in the LICENSE.txt file in the project root.
#


#
#  Vacuum all input from a string and then treat it like a buffer.
#
from antlr4.Token import Token

inputStreamCounter = 0

class InputStream (object):
    __slots__ = ('name', 'strdata', '_index', 'data', '_size', 'id')

    def __init__(self, data: str):
        global inputStreamCounter
        Trace.writej([ 'ENTER InputStream.__init__', inputStreamCounter, data ])
        self.id = inputStreamCounter
        inputStreamCounter += 1
        self.name = "<empty>"
        self.strdata = data
        self._loadString()
        Trace.writej([ 'EXIT InputStream.__init__', self.asdict() ])

    def asdict(self):
        return ["InputStream", {
            'id' : self.id,
            'name' : self.name,
            'strdata': self.strdata,
            '_index' : self._index,
            'data': self.data,
            '_size': self._size,
        }]

    def _loadString(self):
        self._index = 0
        self.data = [ord(c) for c in self.strdata]
        self._size = len(self.data)

    @property
    def index(self):
        return self._index

    @property
    def size(self):
        return self._size

    # Reset the stream so that it's in the same state it was
    #  when the object was created *except* the data array is not
    #  touched.
    #
    def reset(self):
        Trace.writej([ 'ENTER InputStream.reset', self.asdict() ])
        self._index = 0
        Trace.writej([ 'EXIT InputStream.reset', self.asdict() ])

    def consume(self):
        Trace.writej([ 'ENTER InputStream.consume', self.asdict() ])
        if self._index >= self._size:
            assert self.LA(1) == Token.EOF
            raise Exception("cannot consume EOF")
        self._index += 1
        Trace.writej([ 'EXIT InputStream.consume', self.asdict() ])

    def _LA(self, offset: int):
        if offset==0:
            return 0 # undefined
        if offset<0:
            offset += 1 # e.g., translate LA(-1) to use offset=0
        pos = self._index + offset - 1
        if pos < 0 or pos >= self._size: # invalid
            return Token.EOF
        return self.data[pos]

    def LA(self, offset: int):
        Trace.writej([ 'ENTER InputStream.LA', self.asdict(), offset ])
        rv = self._LA(offset)
        Trace.writej([ 'EXIT InputStream.LA', self.asdict(),  rv ])
        return rv

    def LT(self, offset: int):
        return self.LA(offset)

    # mark/release do nothing; we have entire buffer
    def mark(self):
        return -1

    def release(self, marker: int):
        pass

    # consume() ahead until p==_index; can't just set p=_index as we must
    # update line and column. If we seek backwards, just set p
    #
    def _seek(self, _index: int):
        if _index<=self._index:
            self._index = _index # just jump; don't update stream state (line, ...)
            return
        # seek forward
        self._index = min(_index, self._size)

    def seek(self, _index: int):
        Trace.writej([ 'ENTER InputStream.seek', self.asdict(), _index ])
        self._seek(_index)
        Trace.writej([ 'EXIT InputStream.seek', self.asdict() ])

    def _getText(self, start :int, stop: int):
        if stop >= self._size:
            stop = self._size-1
        if start >= self._size:
            return ""
        else:
            return self.strdata[start:stop+1]

    def getText(self, start :int, stop: int):
        Trace.writej([ 'ENTER InputStream.getText', self.asdict(), start, stop ])
        rv = self._getText(start, stop)
        Trace.writej([ 'EXIT InputStream.getText', self.asdict(), rv ])
        return rv

    def __str__(self):
        return self.strdata
