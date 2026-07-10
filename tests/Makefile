WD=$(shell pwd)
TOP=..
include $(TOP)/config/Makefile.sub

PACKAGES := $(PACKAGES),antlr,ounit2,cmdliner,yojson,antlrtest,pa_ppx.runtime

ML= \
	lib_test.ml antlr_test.ml atn_util.ml mimick_test.ml \
	antlrtest_test.ml antlrtest_util.ml deserialize_jsonlog.ml \
	replay_test.ml

ALLSRC=$(ML)
ALLPACKAGES=$(PACKAGES)

TESTS=lib_test.exe antlr_test.exe atn_util.exe mimick_test.exe \
	antlrtest_test.exe antlrtest_util.exe \
	deserialize_jsonlog.exe replay_test.exe

TESTSOPT=$(TESTS:.exe=.opt)

all: $(TESTS) $(TESTSOPT)

test:: all
	mkdir -p _build && ./lib_test.exe
	mkdir -p _build && ./antlr_test.exe
	mkdir -p _build && ./mimick_test.exe
	mkdir -p _build && ./antlrtest_test.exe

MANAGETRIP=./trip-tests/manage-trip-tests
deserialize-all:: replay_test.opt
	./replay_test.opt deserialize -v _generated/*/*/json.log

filter-all:: replay_test.opt
	./replay_test.opt simulate -it "ENTER PredictionContext.merge" _generated/*/*/json.log

simulate-all:: replay_test.opt
	./replay_test.opt simulate --ooe -e "PredictionContext.merge" _generated/*/*/json.log
#	./replay_test.opt simulate -it "ENTER PredictionContext.merge" _generated/*/*/json.log
#	./replay_test.opt simulate -it "ENTER PredictionContext.mergeArrays" _generated/*/*/json.log
#	./replay_test.opt simulate -it "ENTER PredictionContext.mergeRoot" _generated/*/*/json.log

generate-all:: antlrtest_util.opt
	mkdir -p _build && $(MANAGETRIP) generate -v

prepare-all:: antlrtest_util.opt
	mkdir -p _build && $(MANAGETRIP) prepare -v

test-all:: antlrtest_util.opt
	mkdir -p _build && $(MANAGETRIP) test -v

compare-all:: antlrtest_util.opt
	mkdir -p _build && $(MANAGETRIP) compare-atns -v

save-json-log-all:: antlrtest_util.opt
	mkdir -p _build && $(MANAGETRIP) save-json-log -v

compare-json-log-all:: antlrtest_util.opt
	mkdir -p _build && $(MANAGETRIP) compare-json-log -v

clean-all:: antlrtest_util.opt
	mkdir -p _build && $(MANAGETRIP) clean -v

realclean-all:: antlrtest_util.opt
	mkdir -p _build && $(MANAGETRIP) realclean -v

DTEST=$(shell ls fixtures/descriptors/LexerExec/*)
#CTEST=$(shell ls fixtures/custom-descriptors/*/*)
SELECTED=$(DTEST) $(CTEST)
generate-selected:: antlrtest_test.exe
	mkdir -p _build && $(MANAGETRIP) generate -v $(SELECTED)

prepare-selected:: antlrtest_test.exe
	mkdir -p _build && $(MANAGETRIP) prepare -v $(SELECTED)

test-selected:: antlrtest_test.exe
	mkdir -p _build && $(MANAGETRIP) test -v $(SELECTED)

clean-selected:: antlrtest_test.exe
	mkdir -p _build && $(MANAGETRIP) clean -v $(SELECTED)

realclean-selected:: antlrtest_test.exe
	mkdir -p _build && $(MANAGETRIP) realclean -v $(SELECTED)

compare-selected:: antlrtest_test.exe
	mkdir -p _build && $(MANAGETRIP) compare-atns -v $(SELECTED)

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

%.opt: %.cmx
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
	find $(ANTLRROOT) -name '*.interp' -print | xargs -n 1 --verbose python3 deserialize_test.py 

clean::
	rm -rf *.cm* _build *.exe _generated/*.log


realclean:: clean
	rm -rf _generated
