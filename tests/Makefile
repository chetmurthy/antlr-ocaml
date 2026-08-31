WD=$(shell pwd)
TOP=..
include $(TOP)/config/Makefile.sub

ifndef JSONLOGGING
export JSONLOGGING=0
endif

PACKAGES := $(PACKAGES),antlr,parse_antlrv4,ST4,ounit2,cmdliner,yojson,antlrtest,pa_ppx.runtime

ML= \
	lib_test.ml antlr_test.ml atn_util.ml mimick_test.ml \
	antlrtest_test.ml antlrtest_util.ml deserialize_jsonlog.ml \
	replay_util.ml parser_test.ml grammar_tools_test.ml \
	st4syntax_test.ml st4internals_test.ml st4eval_test.ml st4_util.ml \
	location_handling_test.ml \
	testmatrix.ml

ALLSRC=$(ML)
ALLPACKAGES=$(PACKAGES)

EXE=lib_test.exe antlr_test.exe atn_util.exe mimick_test.exe \
	antlrtest_test.exe antlrtest_util.exe \
	deserialize_jsonlog.exe replay_util.exe \
	parser_test.exe grammar_tools_test.exe \
	st4syntax_test.exe st4internals_test.exe st4eval_test.exe st4_util.exe \
	location_handling_test.exe \
	testmatrix.exe

TESTML=$(shell ls *_test.ml)

OPT=$(EXE:.exe=.opt)

all: $(EXE) $(OPT)

test:: all $(TESTML:.ml=.TEST)

test-fully:: test dtest-all sttest-multi sttest-multi-verify

%.TEST: %.opt %.exe
	mkdir -p _build && ./$< -runner sequential -shards 1

MANAGETRIP=./tools/manage-trip-tests
deserialize-all:: replay_util.opt
	./replay_util.opt deserialize -v _generated/*/*/json.log

filter-all:: replay_util.opt
	./replay_util.opt simulate -it "ENTER PredictionContext.merge" _generated/*/*/json.log

simulate-all:: replay_util.opt
	./replay_util.opt simulate --ooe -e "PredictionContext.merge" _generated/*/*/json.log
#	./replay_util.opt simulate -it "ENTER PredictionContext.merge" _generated/*/*/json.log
#	./replay_util.opt simulate -it "ENTER PredictionContext.mergeArrays" _generated/*/*/json.log
#	./replay_util.opt simulate -it "ENTER PredictionContext.mergeRoot" _generated/*/*/json.log


DTEST_CompositeLexers = $(shell ls fixtures/descriptors/CompositeLexers/*.txt)
DTEST_CompositeParsers = $(shell ls fixtures/descriptors/CompositeParsers/*.txt)
DTEST_FullContextParsing = $(shell ls fixtures/descriptors/FullContextParsing/*.txt)
DTEST_LeftRecursion = $(shell ls fixtures/descriptors/LeftRecursion/*.txt)
DTEST_LexerErrors = $(shell ls fixtures/descriptors/LexerErrors/*.txt)
DTEST_LexerExec = $(shell ls fixtures/descriptors/LexerExec/*.txt)
DTEST_Listeners = $(shell ls fixtures/descriptors/Listeners/*.txt)
DTEST_ParserErrors = $(shell ls fixtures/descriptors/ParserErrors/*.txt)
DTEST_ParserExec = $(shell ls fixtures/descriptors/ParserExec/*.txt)
DTEST_ParseTrees = $(shell ls fixtures/descriptors/ParseTrees/*.txt)
DTEST_Performance = $(shell ls fixtures/descriptors/Performance/*.txt)
DTEST_SemPredEvalLexer = $(shell ls fixtures/descriptors/SemPredEvalLexer/*.txt)
DTEST_SemPredEvalParser = $(shell ls fixtures/descriptors/SemPredEvalParser/*.txt)
DTEST_Sets = $(shell ls fixtures/descriptors/Sets/*.txt)

DTEST_all = \
	$(DTEST_CompositeLexers) \
	$(DTEST_CompositeParsers) \
	$(DTEST_FullContextParsing) \
	$(DTEST_LeftRecursion) \
	$(DTEST_LexerErrors) \
	$(DTEST_LexerExec) \
	$(DTEST_Listeners) \
	$(DTEST_ParserErrors) \
	$(DTEST_ParserExec) \
	$(DTEST_ParseTrees) \
	$(DTEST_Performance) \
	$(DTEST_SemPredEvalLexer) \
	$(DTEST_SemPredEvalParser) \
	$(DTEST_Sets) \


uDTEST_custom = $(shell ls fixtures/custom-descriptors/*/*.txt)

DTEST_antlr4 = \
	fixtures/custom-descriptors/antlr4/A2.txt \
	fixtures/custom-descriptors/antlr4/A3.txt \
	fixtures/custom-descriptors/antlr4/ANTLRv4Lexer.txt \
	fixtures/custom-descriptors/antlr4/DTestTest.txt \
	fixtures/custom-descriptors/antlr4/Mode1.txt \
	fixtures/custom-descriptors/antlr4/Mode2.txt \
	fixtures/custom-descriptors/antlr4/ST0.txt \
	fixtures/custom-descriptors/antlr4/ST1.txt \
	fixtures/custom-descriptors/antlr4/ST2.txt \
	fixtures/custom-descriptors/antlr4/STG0.txt \
	fixtures/custom-descriptors/antlr4/STG1.txt \
	fixtures/custom-descriptors/antlr4/STG2.txt \

DTEST = $(DTEST_antlr4) $(DTEST_LexerExec)

DTEST := \
	fixtures/descriptors/LexerExec/CharSet.txt \
	fixtures/descriptors/ParserExec/Basic.txt \
	fixtures/custom-descriptors/antlr4/sexp1.txt \
	fixtures/custom-descriptors/antlr4/choice0.txt \
	fixtures/custom-descriptors/antlr4/choice1.txt \
	fixtures/custom-descriptors/antlr4/star1.txt \
	fixtures/custom-descriptors/antlr4/star2.txt \

DALL=$(DTEST_all) $(DTEST_custom)

$(info $(DALL))

DTESTCMD=full -v

%.DTEST: %.txt
	$(MANAGETRIP) $(DTESTCMD) $<

full-selected:: antlrtest_test.exe
	$(MANAGETRIP) $(DTESTCMD) $(DTEST)

dtest-selected: $(DTEST:.txt=.DTEST)

dtest-all: $(DALL:.txt=.DTEST)

STSEXPALL=$(shell ls fixtures/st4-single/*.sexp)

STSEXPMULTI=$(shell ls fixtures/st4-multi/*.sexp)

ST4UTIL=$(TOP)/tests/st4_util.opt
ST4GEN=_generated/st4

%.STTEST: %.sexp
	$(ST4UTIL) generate -f -d $(ST4GEN) $<
	$(ST4UTIL) compile -d $(ST4GEN) $<
	$(ST4UTIL) execute -d $(ST4GEN) $<
	$(ST4UTIL) check -d $(ST4GEN) $<

%.STTEST-MULTI: %.sexp
	$(ST4UTIL) $(STTESTCMD) -m $<

OCAMLVERBOSE=
OCAMLIGNORE=--ignore-whitespace --ignore-errors

%.STTEST-OCAML: %.sexp
	$(ST4UTIL) test-ocaml $(OCAMLVERBOSE) $(OCAMLIGNORE) -f $<

%.STTEST-MULTI-OCAML: %.sexp
	$(ST4UTIL) test-ocaml $(OCAMLVERBOSE) $(OCAMLIGNORE) -m $<

STTESTCMD=full -f -d $(ST4GEN)
sttest-multi-old:: fixtures/st4-multi/TestNullEmptyMatrix.sexp
	$(ST4UTIL) $(STTESTCMD) -m fixtures/st4-multi/TestCoreBasics.sexp
	$(ST4UTIL) $(STTESTCMD) -m fixtures/st4-multi/TestDictionaries.sexp
	$(ST4UTIL) $(STTESTCMD) -m fixtures/st4-multi/TestGroup.sexp
	$(ST4UTIL) $(STTESTCMD) -m fixtures/st4-multi/TestIndentation.sexp
	$(ST4UTIL) $(STTESTCMD) -m fixtures/st4-multi/TestLists.sexp
	$(ST4UTIL) $(STTESTCMD) -m fixtures/st4-multi/TestNoNewlineTemplates.sexp
	$(ST4UTIL) $(STTESTCMD) -m fixtures/st4-multi/TestOptions.sexp
	$(ST4UTIL) $(STTESTCMD) -m fixtures/st4-multi/TestSubtemplates.sexp
	$(ST4UTIL) $(STTESTCMD) -m fixtures/st4-multi/TestWhitespace.sexp
	$(ST4UTIL) $(STTESTCMD) -m fixtures/st4-multi/TestNullEmptyMatrix.sexp
	$(ST4UTIL) $(STTESTCMD) -m fixtures/st4-multi/TestIndirectionAndEarlyEval.sexp

sttest-multi: $(STSEXPMULTI:.sexp=.STTEST-MULTI)

sttest-multi-ocaml: $(STSEXPMULTI:.sexp=.STTEST-MULTI-OCAML)

sttest-multi-verify:
	$(MAKE) STTESTCMD="verify" sttest-multi

fixtures/st4-multi/TestNullEmptyMatrix.sexp: testmatrix.exe
	./testmatrix.exe > $@.NEW && mv $@.NEW $@

sttest-all: $(STSEXPALL:.sexp=.STTEST)

sttest-all-ocaml: $(STSEXPALL:.sexp=.STTEST-OCAML)

#ONE=LexerExec/CharSet
ONE=ParserExec/Basic
#ONE=CompositeParsers/ImportLexerWithOnlyFragmentRules
#ONE=CompositeParsers/KeywordVSIDOrder
generate-one:: antlrtest_util.opt
	mkdir -p _build && \
	rm -rf _generated/$(ONE) && \
	./antlrtest_util.opt generate $(GENARGS) -d _generated/$(ONE) \
	fixtures/descriptors/$(ONE).txt

test-one:: antlrtest_test.exe
	$(MAKE) -C _generated/$(ONE) all

compare-one:: antlrtest_test.exe
	$(MAKE) -C _generated/$(ONE) compare-atns

%.exe: %.cmo
	$(LAUNCH) $(OCAMLFIND) ocamlc -linkall -linkpkg $(DEBUG) $(OCAMLCFLAGS) -package $(PACKAGES) -linkpkg -linkall -o $@ $<

%.opt: %.cmx %.cmi
	$(LAUNCH) $(OCAMLFIND) ocamlopt -linkall -linkpkg $(DEBUG) $(OCAMLCFLAGS) -package $(PACKAGES) -linkpkg -linkall -o $@ $<

SHELL := /bin/bash
#FILE := CalcLexer.interp
FILE := Calc.interp
#FILE := /home/chet/Hack/Antlr/src/grammars-v4/antlr/antlr4/examples/grammars-v4/cmake/CMakeLexer.interp
#ATNDEBUG=--debug
#ATNVERIFY=--disable-verify
ATNJSON=--json
compare-one-file:: atn_util.opt
	diff -bBwi -u10 <( python3 deserialize_test.py $(FILE) | jq '.' ) <( ./atn_util.opt dump $(ATNVERIFY) $(ATNDEBUG) $(ATNJSON) $(FILE) | jq '.' )

run-python::
	python3 deserialize_test.py $(FILE)

run-ocaml:: atn_util.opt
	./atn_util.opt dump $(ATNVERIFY) $(ATNDEBUG) $(ATNJSON) $(FILE)

ANTLRDIRS= ~/Hack/Antlr/src/antlr4 ~/Hack/Antlr/src/grammars-v4
compare-full:: atn_util.opt
	set -e ;\
	for f in `find $(ANTLRDIRS) -name '*.interp' -print`; \
	do \
	echo "================ $$f ================" ; \
	diff -bBwi -u10 <( python3 deserialize_test.py $$f | jq '.' ) <( ./atn_util.opt dump $(ATNVERIFY) $(ATNDEBUG) $(ATNJSON) $$f | jq '.' ) ; \
	done

test-python::
	python3 deserialize_test.py /home/chet/Hack/Antlr/src/antlr4/runtime-testsuite/test/org/antlr/v4/test/runtime/java/api/JavaLexer.interp

test-all-python::
	find $(ANTLRDIRS) -name '*.interp' -print | xargs -n 1 --verbose python3 deserialize_test.py > /dev/null

clean::
	rm -rf *.cm* _build *.exe _generated/*.log


realclean:: clean
	rm -rf _generated
