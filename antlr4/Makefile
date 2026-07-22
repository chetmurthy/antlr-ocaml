WD=$(shell pwd)
TOP=/home/chet/Hack/Camlp5/src/ALL/antlr-ocaml
include $(TOP)/config/Makefile.sub

PYTHONPATH:=$(TOP)/python:$(PYTHONPATH)
#PYTHONPATH:=/home/chet/Hack/Antlr/src/antlr4/runtime/Python3/src:$(PYTHONPATH)
SHELL := /bin/bash
ADJUST=$(TOP)/tests/tools/adjust-dfa
TESTBASEDIR=$(TOP)/tests/fixtures/test-base-files
PERTESTDIR=$(TOP)/tests/fixtures/pertest-files/antlr4/ANTLRv4Lexer
REPLAYTEST=$(TOP)/tests/replay_test.opt
LIBDIR=$(TOP)/tests/fixtures/grammar-lib
LIBARG=-lib $(LIBDIR)

ifndef JSONLOGGING
export JSONLOGGING=0
endif


all: compare

compile::

prepare:: M.py update-pertest
	$(ADJUST) M.py
	cp M.interp Lexer.interp

update-pertest::
	cp $(TESTBASEDIR)/* .
	if [ -d $(PERTESTDIR) ]; then cp $(PERTESTDIR)/* .; fi

compare:: output.NEW errors.NEW
	diff -Bwiu output output.NEW
	diff -Bwiu errors errors.NEW

save-json-log: json.log
	cp json.log json.log.SAVED

compare-json-log:: json.log.SAVED json.log
	diff -Bwiu json.log.SAVED json.log

M.py: M.g4
	antlr4 $(VISITOR) $(LIBARG) -Dlanguage=Python3 M.g4

output.NEW errors.NEW json.log:: M.py
	env PYTHONPATH=$(PYTHONPATH) python3 Test.py $(RUNARGS) input > output.NEW 2> errors.NEW
	jq -S . json.log.RAW > json.log.NEW && mv json.log.NEW json.log

GENLEXFILES=M.py M.interp M.tokens

deserialize-python-json::
	env PYTHONPATH=$(PYTHONPATH) python3 $(TOP)/tests/deserialize_test.py M.interp

deserialize-python::
	env PYTHONPATH=$(PYTHONPATH) python3 $(TOP)/tests/deserialize_test.py M.interp

deserialize-ocaml-json::
	$(TOP)/tests/atn_util.opt dump --json M.interp

deserialize-ocaml::
	$(TOP)/tests/atn_util.opt dump M.interp

compare-atns:: M.py
	diff -bBwi -u10 \
	<( env PYTHONPATH=$(PYTHONPATH) python3 $(TOP)/tests/deserialize_test.py M.interp | jq '.' ) \
	<( $(TOP)/tests/atn_util.opt dump --json M.interp | jq '.' )

visualize-lexer: M.interp
	xdot <( $(TOP)/tests/atn_util.opt graph --with-rule-index --xdot M.interp )


realclean:: clean
	rm -rf __pycache__ $(GENLEXFILES) $(GENPAFILES) $(GENGRAMFILES)

clean::
	rm -rf output.NEW errors.NEW *.log *.BAK *.RAW

-include ocaml-Makefile
