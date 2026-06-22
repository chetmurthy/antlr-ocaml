TOP=/home/chet/Hack/Camlp5/src/ALL/antlr-ocaml
PYTHONPATH:=$(TOP)/python:$(PYTHONPATH)
#PYTHONPATH:=/home/chet/Hack/Antlr/src/antlr4/runtime/Python3/src:$(PYTHONPATH)
SHELL := /bin/bash

all: compare

compare:: output.NEW errors.NEW
	diff -Bwiu output output.NEW
	diff -Bwiu errors errors.NEW

<if(parserName)>
VISITOR=-visitor
<endif>
<lexerName>.py: <grammarName>.g4
	antlr4 $(VISITOR) -Dlanguage=Python3 <grammarName>.g4

output.NEW errors.NEW:: <lexerName>.py
	env PYTHONPATH=$(PYTHONPATH) python3 Test.py input > output.NEW 2> errors.NEW

<if(parserName)>
GENPAFILES=<grammarName>Parser.py <grammarName>Listener.py <grammarName>Visitor.py
GENLEXFILES=<grammarName>Lexer.py <grammarName>Lexer.interp <grammarName>Lexer.tokens
GENGRAMFILES=<grammarName>.interp <grammarName>.tokens
<else>
GENLEXFILES=<lexerName>.py <lexerName>.interp <lexerName>.tokens
<endif>

deserialize-python::
	env PYTHONPATH=$(PYTHONPATH) python3 $(TOP)/tests/deserialize_test.py <lexerName>.interp

deserialize-ocaml::
	$(TOP)/tests/roundtrip_atn.exe --json <lexerName>.interp

compare-atns:: <lexerName>.py
	diff -bBwi -u10 \
	<( env PYTHONPATH=$(PYTHONPATH) python3 $(TOP)/tests/deserialize_test.py <grammarName>.interp ) \
	<( $(TOP)/tests/roundtrip_atn.exe --json <grammarName>.interp )
<if(parserName)>
	diff -bBwi -u10 \
	<( env PYTHONPATH=$(PYTHONPATH) python3 $(TOP)/tests/deserialize_test.py <lexerName>.interp ) \
	<( $(TOP)/tests/roundtrip_atn.exe --json <lexerName>.interp )
<endif>


clean::
	rm -rf __pycache__ $(GENLEXFILES) $(GENPAFILES) $(GENGRAMFILES) output.NEW errors.NEW json.log
