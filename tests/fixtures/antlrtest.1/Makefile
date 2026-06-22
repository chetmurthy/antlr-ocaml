TOP=../../..
#PYTHONPATH:=$(TOP)/python:$(PYTHONPATH)
PYTHONPATH:=/home/chet/Hack/Antlr/src/antlr4/runtime/Python3/src:$(PYTHONPATH)

all: compare

compare:: output.NEW
	diff -Bwiu output output.NEW

<if(parserName)>
VISITOR=-visitor
<endif>
<lexerName>.py: <grammarName>.g4
	antlr4 $(VISITOR) -Dlanguage=Python3 <grammarName>.g4

output.NEW:: <lexerName>.py
	env PYTHONPATH=$(PYTHONPATH) python3 Test.py input > output.NEW

<if(parserName)>
GENPAFILES=<grammarName>Parser.py <grammarName>Listener.py
<endif>

clean::
	rm -rf __pycache__ <lexerName>.py $(GENPAFILES) <grammarName>.interp <grammarName>.tokens output.NEW
