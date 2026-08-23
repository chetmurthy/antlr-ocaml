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
RUNNER=$(TOP)/tests/tools/dtest-runner
WD=`pwd`

ifeq ($(NOVERBOSE),)
VERBOSE=-v
endif

ifndef JSONLOGGING
export JSONLOGGING=0
endif

<if(showDFA)>
SHOWARGS=--show-dfa
<endif>

LOCARG=-n

ifdef MAXDEPTH
  MAXDEPTHARG := -m $(MAXDEPTH)
endif

EEARGS=$(LOCARG) $(MAXDEPTHARG)

compile::

python-prepare:: <lexerName>.py update-pertest
<if(parserName)>
	$(NOVERBOSE) $(ADJUST) <grammarName>Lexer.py
	$(NOVERBOSE) $(ADJUST) <grammarName>Parser.py
	$(NOVERBOSE) cp <grammarName>Lexer.interp Lexer.interp
	$(NOVERBOSE) cp <grammarName>.interp Parser.interp
<else>
	$(NOVERBOSE) $(ADJUST) <lexerName>.py
	$(NOVERBOSE) cp <grammarName>.interp Lexer.interp
<endif>

update-pertest::
	$(NOVERBOSE) cp $(TESTBASEDIR)/* .
	$(NOVERBOSE) if [ -d $(PERTESTDIR) ]; then cp -r $(PERTESTDIR)/. .; fi

compare::
	$(NOVERBOSE) env TOP=$(TOP) PYTHONPATH=$(PYTHONPATH) $(RUNNER) compare $(VERBOSE)

all-tests::
	$(NOVERBOSE) $(MAKE) {python,ocaml}-test{,-named-output} || true

save-json-log: json.log
	cp json.log json.log.SAVED

compare-json-log:: json.log.SAVED json.log
	diff -Bwiu json.log.SAVED json.log

<if(parserName)>
VISITOR=-visitor
<endif>
<lexerName>.py: <grammarName>.g4
	$(NOVERBOSE) antlr4 $(VISITOR) $(LIBARG) -Dlanguage=Python3 <grammarName>.g4

l.ml:
	$(NOVERBOSE) $(TOP)/tests/atn_util.opt emit-ocaml-lexer -i Lexer.interp --grammar-lib $(TOP)/tests/fixtures/grammar-lib -t translation.json --constants-module L_constants <grammarName>.g4 > l.ml.NEW && mv l.ml.NEW l.ml

l_constants.ml:
	$(NOVERBOSE) $(TOP)/tests/atn_util.opt emit-ocaml-constants Lexer.interp > l_constants.ml.NEW && mv l_constants.ml.NEW l_constants.ml

python-test:: <lexerName>.py
	$(NOVERBOSE) env TOP=$(TOP) PYTHONPATH=$(PYTHONPATH) $(RUNNER) run $(VERBOSE) $(SHOWARGS)
	$(NOVERBOSE) env TOP=$(TOP) PYTHONPATH=$(PYTHONPATH) $(RUNNER) json-entry-exit $(VERBOSE) --ee-args "$(EEARGS)" $(SHOWARGS)
	$(NOVERBOSE) env TOP=$(TOP) PYTHONPATH=$(PYTHONPATH) $(RUNNER) run $(VERBOSE) --lexer-only $(SHOWARGS)
	$(NOVERBOSE) env TOP=$(TOP) PYTHONPATH=$(PYTHONPATH) $(RUNNER) json-entry-exit $(VERBOSE) --lexer-only --ee-args "$(EEARGS)" $(SHOWARGS)

named-python-test:: <lexerName>.py
	$(NOVERBOSE) env TOP=$(TOP) PYTHONPATH=$(PYTHONPATH) $(RUNNER) run $(VERBOSE) $(SHOWARGS) $(NAME)
	$(NOVERBOSE) env TOP=$(TOP) PYTHONPATH=$(PYTHONPATH) $(RUNNER) json-entry-exit $(VERBOSE) --ee-args "$(EEARGS)" $(SHOWARGS) $(NAME)
	$(NOVERBOSE) env TOP=$(TOP) PYTHONPATH=$(PYTHONPATH) $(RUNNER) run $(VERBOSE) --lexer-only $(SHOWARGS) $(NAME)
	$(NOVERBOSE) env TOP=$(TOP) PYTHONPATH=$(PYTHONPATH) $(RUNNER) json-entry-exit $(VERBOSE) --lexer-only --ee-args "$(EEARGS)" $(SHOWARGS) $(NAME)

python-test-named-output::
	$(NOVERBOSE) env TOP=$(TOP) PYTHONPATH=$(PYTHONPATH) $(RUNNER) run $(VERBOSE) $(SHOWARGS) --named-types
	$(NOVERBOSE) env TOP=$(TOP) PYTHONPATH=$(PYTHONPATH) $(RUNNER) run $(VERBOSE) $(SHOWARGS) --lexer-only --named-types

named-python-test-named-output::
	$(NOVERBOSE) env TOP=$(TOP) PYTHONPATH=$(PYTHONPATH) $(RUNNER) run $(VERBOSE) $(SHOWARGS) --named-types $(NAME)
	$(NOVERBOSE) env TOP=$(TOP) PYTHONPATH=$(PYTHONPATH) $(RUNNER) run $(VERBOSE) $(SHOWARGS) --lexer-only --named-types $(NAME)

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
	$(NOVERBOSE) rm -f json.log
	$(NOVERBOSE) diff -bBwi -u10 \
	\<( env PYTHONPATH=$(PYTHONPATH) python3 $(TOP)/tests/deserialize_test.py <grammarName>.interp | jq '.' ) \
	\<( $(TOP)/tests/atn_util.opt dump --json <grammarName>.interp | jq '.' )
	$(NOVERBOSE) mv json.log lexer-atn-json.log
<if(parserName)>
	$(NOVERBOSE) diff -bBwi -u10 \
	\<( env PYTHONPATH=$(PYTHONPATH) python3 $(TOP)/tests/deserialize_test.py <lexerName>.interp | jq '.' ) \
	\<( $(TOP)/tests/atn_util.opt dump --json <lexerName>.interp | jq '.' )
<endif>

visualize-lexer: <lexerName>.interp
	xdot \<( $(TOP)/tests/atn_util.opt graph --with-rule-index --xdot <lexerName>.interp )

<if(parserName)>
visualize-parser: <grammarName>.interp
	xdot \<( $(TOP)/tests/atn_util.opt graph --with-rule-index --xdot <grammarName>.interp )
<endif>

realclean:: clean
	rm -rf __pycache__ $(GENLEXFILES) $(GENPAFILES) $(GENGRAMFILES)

clean::
	rm -rf output.NEW errors.NEW *.log *.BAK *.RAW

-include ocaml-Makefile
