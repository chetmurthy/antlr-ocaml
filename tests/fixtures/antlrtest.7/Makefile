WD=$(shell pwd)
TOP=/home/chet/Hack/Camlp5/src/ALL/antlr-ocaml
include $(TOP)/config/Makefile.sub

PYTHONPATH:=$(TOP)/python:$(PYTHONPATH)
#PYTHONPATH:=/home/chet/Hack/Antlr/src/antlr4/runtime/Python3/src:$(PYTHONPATH)
SHELL := /bin/bash
ADJUST=$(TOP)/tests/tools/adjust-dfa
TESTBASEDIR=$(TOP)/tests/fixtures/test-base-files
PERTESTDIR=$(TOP)/tests/fixtures/pertest-files/<testName>
REPLAYTEST=$(TOP)/tests/replay_util.opt
LIBDIR=$(TOP)/tests/fixtures/grammar-lib
LIBARG=-lib $(LIBDIR)

ifndef JSONLOGGING
export JSONLOGGING=0
endif

<if(showDFA)>
SHOWDFA=1
<endif>

python-test: python-compare lexer-output.NEW

compile::

python-prepare:: <lexerName>.py update-pertest
<if(parserName)>
	$(ADJUST) <grammarName>Lexer.py
	$(ADJUST) <grammarName>Parser.py
	cp <grammarName>Lexer.interp Lexer.interp
	cp <grammarName>.interp Parser.interp
<else>
	$(ADJUST) <lexerName>.py
	cp <grammarName>.interp Lexer.interp
<endif>

update-pertest::
	cp $(TESTBASEDIR)/* .
	if [ -d $(PERTESTDIR) ]; then cp -r $(PERTESTDIR)/. .; fi

python-compare:: output.NEW errors.NEW
	diff -Bwiu output output.NEW
	diff -Bwiu errors errors.NEW

save-json-log: json.log
	cp json.log json.log.SAVED

compare-json-log:: json.log.SAVED json.log
	diff -Bwiu json.log.SAVED json.log

<if(parserName)>
VISITOR=-visitor
<endif>
<lexerName>.py: <grammarName>.g4
	antlr4 $(VISITOR) $(LIBARG) -Dlanguage=Python3 <grammarName>.g4

l.ml:
	$(TOP)/tests/atn_util.opt emit-ocaml-lexer -i Lexer.interp --grammar-lib $(TOP)/tests/fixtures/grammar-lib -t translation.json <grammarName>.g4 > l.ml.NEW && mv l.ml.NEW l.ml

l_constants.ml:
	$(TOP)/tests/atn_util.opt emit-ocaml-constants Lexer.interp > l_constants.ml.NEW && mv l_constants.ml.NEW l_constants.ml

output.NEW errors.NEW json.log:: <lexerName>.py
	env PYTHONPATH=$(PYTHONPATH) python3 Test.py $(RUNARGS) input > output.NEW 2> errors.NEW
	jq -S . json.log.RAW > json.log.NEW && mv json.log.NEW json.log

named-python-test:: M.py
	env PYTHONPATH=$(PYTHONPATH) python3 Test.py $(RUNARGS) input.$(NAME) > output.$(NAME).NEW 2> errors.$(NAME).NEW
	env PYTHONPATH=$(PYTHONPATH) python3 TestLexer.py $(RUNARGS) input.$(NAME) > lexer-output.$(NAME).NEW 2> lexer-errors.$(NAME).NEW
	jq -S . json.log.RAW > json.log.NEW && mv json.log.NEW json.log
	diff -Bwiu output.$(NAME) output.$(NAME).NEW
	diff -Bwiu errors.$(NAME) errors.$(NAME).NEW

python-test-named-output::
	env JSONLOGGING=0 PYTHONPATH=$(PYTHONPATH) python3 Test.py --named-types $(RUNARGS) input > output-named-types.NEW

named-python-test-named-output::
	env JSONLOGGING=0 PYTHONPATH=$(PYTHONPATH) python3 Test.py --named-types $(RUNARGS) input.$(NAME) > output-named-types.$(NAME).NEW

lexer-output.NEW lexer-errors.NEW lexer-json.log:: <lexerName>.py
	env PYTHONPATH=$(PYTHONPATH) python3 TestLexer.py $(RUNARGS) input > lexer-output.NEW 2> lexer-errors.NEW
	jq -S . json.log.RAW > json.log.NEW && mv json.log.NEW lexer-json.log

<if(parserName)>
GENPAFILES=<grammarName>Parser.py <grammarName>Listener.py <grammarName>Visitor.py
GENLEXFILES=<grammarName>Lexer.py <grammarName>Lexer.interp <grammarName>Lexer.tokens
GENGRAMFILES=<grammarName>.interp <grammarName>.tokens
<else>
GENLEXFILES=<lexerName>.py <lexerName>.interp <lexerName>.tokens
<endif>

deserialize-python-json::
	env PYTHONPATH=$(PYTHONPATH) python3 $(TOP)/tests/deserialize_test.py <lexerName>.interp
<if(parserName)>
	env PYTHONPATH=$(PYTHONPATH) python3 $(TOP)/tests/deserialize_test.py <grammarName>.interp
<endif>

deserialize-python::
	env PYTHONPATH=$(PYTHONPATH) python3 $(TOP)/tests/deserialize_test.py <lexerName>.interp
<if(parserName)>
	env PYTHONPATH=$(PYTHONPATH) python3 $(TOP)/tests/deserialize_test.py <grammarName>.interp
<endif>

deserialize-ocaml-json::
	$(TOP)/tests/atn_util.opt dump --json <lexerName>.interp
<if(parserName)>
	$(TOP)/tests/atn_util.opt dump --json <grammarName>.interp
<endif>

deserialize-ocaml::
	$(TOP)/tests/atn_util.opt dump <lexerName>.interp
<if(parserName)>
	$(TOP)/tests/atn_util.opt dump <grammarName>.interp
<endif>

compare-atns:: <lexerName>.py
	diff -bBwi -u10 \
	<( env PYTHONPATH=$(PYTHONPATH) python3 $(TOP)/tests/deserialize_test.py <grammarName>.interp | jq '.' ) \
	<( $(TOP)/tests/atn_util.opt dump --json <grammarName>.interp | jq '.' )
<if(parserName)>
	diff -bBwi -u10 \
	<( env PYTHONPATH=$(PYTHONPATH) python3 $(TOP)/tests/deserialize_test.py <lexerName>.interp | jq '.' ) \
	<( $(TOP)/tests/atn_util.opt dump --json <lexerName>.interp | jq '.' )
<endif>

visualize-lexer: <lexerName>.interp
	xdot <( $(TOP)/tests/atn_util.opt graph --with-rule-index --xdot <lexerName>.interp )

<if(parserName)>
visualize-parser: <grammarName>.interp
	xdot <( $(TOP)/tests/atn_util.opt graph --with-rule-index --xdot <grammarName>.interp )
<endif>

realclean:: clean
	rm -rf __pycache__ $(GENLEXFILES) $(GENPAFILES) $(GENGRAMFILES)

clean::
	rm -rf output.NEW errors.NEW *.log *.BAK *.RAW

-include ocaml-Makefile
