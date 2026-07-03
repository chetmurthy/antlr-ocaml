WD=$(shell pwd)
TOP=..
include $(TOP)/config/Makefile.sub

PACKAGES := $(PACKAGES),antlr,ounit2,cmdliner,yojson,antlrtest,pa_ppx.runtime

ML= \
	lib_test.ml antlr_test.ml atn_util.ml \
	antlrtest_test.ml antlrtest_util.ml deserialize_jsonlog.ml \
	jsonlog_util.ml

ALLSRC=$(ML)
ALLPACKAGES=$(PACKAGES)

TESTS=lib_test.exe antlr_test.exe atn_util.exe \
	antlrtest_test.exe antlrtest_util.exe \
	deserialize_jsonlog.exe jsonlog_util.exe

TESTSOPT=$(TESTS:.exe=.opt)

all: $(TESTS) $(TESTSOPT)

test:: all
	mkdir -p _build && ./lib_test.exe
	mkdir -p _build && ./antlr_test.exe
	mkdir -p _build && ./antlrtest_test.exe

MANAGETRIP=./trip-tests/0.manage
generate-all:: antlrtest_util.opt
	mkdir -p _build && $(MANAGETRIP) generate -v

test-all:: antlrtest_util.opt
	mkdir -p _build && $(MANAGETRIP) test -v

compare-all:: antlrtest_util.opt
	mkdir -p _build && $(MANAGETRIP) compare-atns -v

clean-all:: antlrtest_util.opt
	mkdir -p _build && $(MANAGETRIP) clean -v

realclean-all:: antlrtest_util.opt
	mkdir -p _build && $(MANAGETRIP) realclean -v

DTEST=$(shell ls fixtures/descriptors/LexerExec/*)
#CTEST=$(shell ls fixtures/custom-descriptors/*/*)
SELECTED=$(DTEST) $(CTEST)
generate-selected:: antlrtest_test.exe
	mkdir -p _build && $(MANAGETRIP) generate -v $(SELECTED)

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
	rm -rf _build/$(ONE) && \
	./antlrtest_util.opt generate $(GENARGS) -d _build/$(ONE) \
	fixtures/descriptors/$(ONE).txt

test-one:: antlrtest_test.exe
	$(MAKE) -C _build/$(ONE) all

compare-one:: antlrtest_test.exe
	$(MAKE) -C _build/$(ONE) compare-atns

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
	rm -rf *.cm* _build *.exe

