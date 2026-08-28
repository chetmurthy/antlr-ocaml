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
LIBDIR=.
LIBARG=-lib $(LIBDIR)
RUNNER=$(TOP)/tests/tools/dtest-runner
ST4UTIL=$(TOP)/tests/st4_util.opt
WD=`pwd`

ifeq ($(NOVERBOSE),)
VERBOSE=-v
endif

ifndef JSONLOGGING
export JSONLOGGING=0
endif

<if(showDFA)><\\>
SHOWARGS=--show-dfa
<endif><\\>

LOCARG=-n

ifdef MAXDEPTH
  MAXDEPTHARG := -m $(MAXDEPTH)
endif

EEARGS=$(LOCARG) $(MAXDEPTHARG)

compile::

python-prepare:: gen-python/<lexerName>.py<\\>
<if(parserName)>
	$(NOVERBOSE) $(ADJUST) gen-python/<grammarName>Lexer.py
	$(NOVERBOSE) $(ADJUST) gen-python/<grammarName>Parser.py
	$(NOVERBOSE) cp gen-python/<grammarName>Lexer.interp Lexer.interp
	$(NOVERBOSE) cp gen-python/<grammarName>.interp Parser.interp
<else>
	$(NOVERBOSE) $(ADJUST) gen-python/<lexerName>.py
	$(NOVERBOSE) cp gen-python/<grammarName>.interp Lexer.interp
<endif>

update-pertest::
	$(NOVERBOSE) cp $(TESTBASEDIR)/* .
	$(NOVERBOSE) if [ -d $(PERTESTDIR) ]; then cp -r $(PERTESTDIR)/. .; fi

compare::
	$(NOVERBOSE) env TOP=$(TOP) PYTHONPATH=$(PYTHONPATH) $(RUNNER) compare $(VERBOSE)

all-tests::
	$(NOVERBOSE) $(MAKE) {python,ocaml}-test{,-named-output} || true
<namedTests:{ n |<\t>$(NOVERBOSE) $(MAKE) NAME=<n> named-{python,ocaml\}-test{,-named-output\} || true
}>

save-json-log: json.log
	cp json.log json.log.SAVED

compare-json-log:: json.log.SAVED json.log
	diff -Bwiu json.log.SAVED json.log

<if(parserName)>
VISITOR=-visitor
<endif>
gen-python/<lexerName>.py: <grammarNames:{ n | gen-python/<n>.g4 }>
	$(NOVERBOSE) (cd gen-python && antlr4 $(VISITOR) $(LIBARG) -Dlanguage=Python3 <grammarName>.g4)

<grammarNames:{ n |gen-python/<n>.g4: raw/<n>.g4
	$(NOVERBOSE) mkdir -p gen-python
	$(NOVERBOSE) (cd gen-python && $(ST4UTIL) transform --group ../Python3.stg ../raw/<n>.g4 > <n>.g4.NEW && mv <n>.g4.NEW <n>.g4)

}>

gen-cpp/<lexerName>.cpp: <grammarNames:{ n | gen-cpp/<n>.g4 }>
	$(NOVERBOSE) (cd gen-cpp && antlr4 $(VISITOR) $(LIBARG) -Dlanguage=Cpp <grammarName>.g4)

CPPTESTSTG=/home/chet/Hack/Antlr/src/antlr4/runtime-testsuite/resources/org/antlr/v4/test/runtime/templates/Cpp.test.stg
<grammarNames:{ n |gen-cpp/<n>.g4: raw/<n>.g4
	$(NOVERBOSE) mkdir -p gen-cpp
	$(NOVERBOSE) (cd gen-cpp && $(ST4UTIL) transform --group $(CPPTESTSTG) ../raw/<n>.g4 > <n>.g4.NEW && mv <n>.g4.NEW <n>.g4)

}>

<grammarNames:{ n |gen-ocaml/<n>.g4: raw/<n>.g4
	$(NOVERBOSE) mkdir -p gen-ocaml
	$(NOVERBOSE) (cd gen-ocaml && $(ST4UTIL) transform --group ../OCaml.stg ../raw/<n>.g4 > <n>.g4.NEW && mv <n>.g4.NEW <n>.g4)

}>

l.ml: <grammarNames:{ n | gen-ocaml/<n>.g4 }>
	$(NOVERBOSE) $(TOP)/tests/atn_util.opt emit-ocaml-lexer -i Lexer.interp --grammar-lib . --constants-module L_constants gen-ocaml/<grammarName>.g4 > l.ml.NEW && mv l.ml.NEW l.ml

l_constants.ml:
	$(NOVERBOSE) $(TOP)/tests/atn_util.opt emit-ocaml-constants Lexer.interp > l_constants.ml.NEW && mv l_constants.ml.NEW l_constants.ml

python-test:: gen-python/<lexerName>.py
	$(NOVERBOSE) env TOP=$(TOP) PYTHONPATH=$(WD)/gen-python:$(PYTHONPATH) $(RUNNER) run $(VERBOSE) $(SHOWARGS)
	$(NOVERBOSE) env TOP=$(TOP) PYTHONPATH=$(WD)/gen-python:$(PYTHONPATH) $(RUNNER) json-entry-exit $(VERBOSE) --ee-args "$(EEARGS)" $(SHOWARGS)
	$(NOVERBOSE) env TOP=$(TOP) PYTHONPATH=$(WD)/gen-python:$(PYTHONPATH) $(RUNNER) run $(VERBOSE) --lexer-only $(SHOWARGS)
	$(NOVERBOSE) env TOP=$(TOP) PYTHONPATH=$(WD)/gen-python:$(PYTHONPATH) $(RUNNER) json-entry-exit $(VERBOSE) --lexer-only --ee-args "$(EEARGS)" $(SHOWARGS)

named-python-test:: gen-python/<lexerName>.py
	$(NOVERBOSE) env TOP=$(TOP) PYTHONPATH=$(WD)/gen-python:$(PYTHONPATH) $(RUNNER) run $(VERBOSE) $(SHOWARGS) $(NAME)
	$(NOVERBOSE) env TOP=$(TOP) PYTHONPATH=$(WD)/gen-python:$(PYTHONPATH) $(RUNNER) json-entry-exit $(VERBOSE) --ee-args "$(EEARGS)" $(SHOWARGS) $(NAME)
	$(NOVERBOSE) env TOP=$(TOP) PYTHONPATH=$(WD)/gen-python:$(PYTHONPATH) $(RUNNER) run $(VERBOSE) --lexer-only $(SHOWARGS) $(NAME)
	$(NOVERBOSE) env TOP=$(TOP) PYTHONPATH=$(WD)/gen-python:$(PYTHONPATH) $(RUNNER) json-entry-exit $(VERBOSE) --lexer-only --ee-args "$(EEARGS)" $(SHOWARGS) $(NAME)

python-test-named-output::
	$(NOVERBOSE) env TOP=$(TOP) PYTHONPATH=$(WD)/gen-python:$(PYTHONPATH) $(RUNNER) run $(VERBOSE) $(SHOWARGS) --named-types
	$(NOVERBOSE) env TOP=$(TOP) PYTHONPATH=$(WD)/gen-python:$(PYTHONPATH) $(RUNNER) run $(VERBOSE) $(SHOWARGS) --lexer-only --named-types

named-python-test-named-output::
	$(NOVERBOSE) env TOP=$(TOP) PYTHONPATH=$(WD)/gen-python:$(PYTHONPATH) $(RUNNER) run $(VERBOSE) $(SHOWARGS) --named-types $(NAME)
	$(NOVERBOSE) env TOP=$(TOP) PYTHONPATH=$(WD)/gen-python:$(PYTHONPATH) $(RUNNER) run $(VERBOSE) $(SHOWARGS) --lexer-only --named-types $(NAME)

<if(parserName)>
GENPAFILES=<grammarName>Parser.py <grammarName>Listener.py <grammarName>Visitor.py
GENLEXFILES=<grammarName>Lexer.py <grammarName>Lexer.interp <grammarName>Lexer.tokens
GENGRAMFILES=<grammarName>.interp <grammarName>.tokens
<else>
GENLEXFILES=<lexerName>.py <lexerName>.interp <lexerName>.tokens
<endif>

deserialize-python-json::
	env PYTHONPATH=$(PYTHONPATH) python3 $(TOP)/tests/deserialize_test.py <lexerName>.interp<\\>
<if(parserName)>
	env PYTHONPATH=$(PYTHONPATH) python3 $(TOP)/tests/deserialize_test.py <grammarName>.interp
<endif>

deserialize-python::
	env PYTHONPATH=$(PYTHONPATH) python3 $(TOP)/tests/deserialize_test.py <lexerName>.interp<\\>
<if(parserName)>
	env PYTHONPATH=$(PYTHONPATH) python3 $(TOP)/tests/deserialize_test.py <grammarName>.interp
<endif>

deserialize-ocaml-json::
	$(TOP)/tests/atn_util.opt dump --json gen-python/<lexerName>.interp<\\>
<if(parserName)>
	$(TOP)/tests/atn_util.opt dump --json gen-python/<grammarName>.interp
<endif>

deserialize-ocaml::
	$(TOP)/tests/atn_util.opt dump gen-python/<lexerName>.interp<\\>
<if(parserName)>
	$(TOP)/tests/atn_util.opt dump gen-python/<grammarName>.interp
<endif>

compare-atns:: gen-python/<lexerName>.py
	$(NOVERBOSE) rm -f json.log
	$(NOVERBOSE) diff -bBwi -u10 \
	\<( env PYTHONPATH=$(PYTHONPATH) python3 $(TOP)/tests/deserialize_test.py gen-python/<grammarName>.interp | jq '.' ) \
	\<( $(TOP)/tests/atn_util.opt dump --json gen-python/<grammarName>.interp | jq '.' )
	$(NOVERBOSE) mv json.log lexer-atn-json.log<\\>
<if(parserName)>
	$(NOVERBOSE) diff -bBwi -u10 \
	\<( env PYTHONPATH=$(PYTHONPATH) python3 $(TOP)/tests/deserialize_test.py gen-python/<lexerName>.interp | jq '.' ) \
	\<( $(TOP)/tests/atn_util.opt dump --json gen-python/<lexerName>.interp | jq '.' )
<endif>

visualize-lexer: gen-python/<lexerName>.interp
	xdot \<( $(TOP)/tests/atn_util.opt graph --with-rule-index --xdot gen-python/<lexerName>.interp )

<if(parserName)>
visualize-parser: gen-python/<grammarName>.interp
	xdot \<( $(TOP)/tests/atn_util.opt graph --with-rule-index --xdot gen-python/<grammarName>.interp )
<endif>

.SECONDARY:

realclean:: clean
	rm -rf __pycache__ $(GENLEXFILES) $(GENPAFILES) $(GENGRAMFILES)

clean::
	rm -rf output.NEW errors.NEW *.log *.BAK gen-python gen-ocaml

-include ocaml-Makefile
