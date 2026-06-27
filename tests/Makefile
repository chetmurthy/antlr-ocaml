WD=$(shell pwd)
TOP=..
include $(TOP)/config/Makefile.sub

PACKAGES := $(PACKAGES),antlr,ounit2,cmdliner,yojson,antlrtest,pa_ppx.runtime

ML= \
	lib_test.ml antlr_test.ml atn_util.ml \
	antlrtest_test.ml generate_antlrtest.ml deserialize_jsonlog.ml

ALLSRC=$(ML)
ALLPACKAGES=$(PACKAGES)

TESTS=lib_test.exe antlr_test.exe atn_util.exe \
	antlrtest_test.exe generate_antlrtest.exe \
	deserialize_jsonlog.exe

TESTSOPT=$(TESTS:.exe=.opt)

all: $(TESTS) $(TESTSOPT)

test:: all
	mkdir -p _build && ./lib_test.exe
	mkdir -p _build && ./antlr_test.exe
	mkdir -p _build && ./antlrtest_test.exe

GENARGS="--template-dir=fixtures/antlrtest.2"
#ALLTESTS=$(shell (cd fixtures/descriptors && ls */*.txt))
ALLTESTS=$(shell (cd fixtures/descriptors && ls */*.txt | grep -v Performance ))
generate-all:: antlrtest_test.exe
	mkdir -p _build && set -e ;\
	for d in $(ALLTESTS) ;\
	do \
	rm -rf _build/$${d/.txt/} && \
	./generate_antlrtest.opt $(GENARGS) -d _build/$${d/.txt/} \
	fixtures/descriptors/$$d ;\
	done

test-all:: antlrtest_test.exe
	mkdir -p _build && set -e ;\
	for d in $(ALLTESTS) ;\
	do \
	[ -d _build/$${d/.txt/} ] && $(MAKE) -C _build/$${d/.txt/} all ;\
	done

compare-all:: antlrtest_test.exe
	mkdir -p _build && set -e ;\
	for d in $(ALLTESTS) ;\
	do \
	[ -d _build/$${d/.txt/} ] && $(MAKE) -C _build/$${d/.txt/} compare-atns ;\
	done

clean-all:: antlrtest_test.exe
	mkdir -p _build && set -e ;\
	for d in `cd fixtures/descriptors ; find . -name '*.txt' -print` ;\
	do \
	[ -d _build/$${d/.txt/} ] && $(MAKE) -C _build/$${d/.txt/} clean ;\
	done

generate-all-nonstop:: antlrtest_test.exe
	mkdir -p _build && set -e ;\
	for d in `cd fixtures/descriptors ; find . -name '*.txt' -print` ;\
	do \
	rm -rf _build/$${d/.txt/} && \
	./generate_antlrtest.exe $(GENARGS) -d _build/$${d/.txt/} \
	fixtures/descriptors/$$d || true ;\
	done

DTEST=$(shell cd fixtures/descriptors && ls LexerExec/* | perl -p -e 's,\.txt,,')
#CTEST=$(shell cd fixtures/custom-descriptors && ls */* | perl -p -e 's,\.txt,,')
SELECTED=$(DTEST) $(CTEST)
generate-selected:: antlrtest_test.exe
	mkdir -p _build && set -e ;\
	for d in $(SELECTED) ;\
	do \
	rm -rf _build/$$d && \
	./generate_antlrtest.exe $(GENARGS) -d _build/$$d \
	fixtures/*descriptors/$$d.txt ;\
	done

test-selected:: antlrtest_test.exe
	set -e ;\
	for d in $(SELECTED) ;\
	do \
	[ -d _build/$$d ] && $(MAKE) -C _build/$$d all ;\
	done

clean-selected:: antlrtest_test.exe
	set -e ;\
	for d in $(SELECTED) ;\
	do \
	[ -d _build/$$d ] && $(MAKE) -C _build/$$d clean ;\
	done

compare-selected:: antlrtest_test.exe
	set -e ;\
	for d in $(SELECTED) ;\
	do \
	[ -d _build/$$d ] && $(MAKE) -C _build/$$d compare-atns ;\
	done

#ONE=LexerExec/CharSet
ONE=ParserExec/Basic
#ONE=CompositeParsers/ImportLexerWithOnlyFragmentRules
#ONE=CompositeParsers/KeywordVSIDOrder
generate-one:: antlrtest_test.exe
	mkdir -p _build && \
	rm -rf _build/$(ONE) && \
	./generate_antlrtest.exe $(GENARGS) -d _build/$(ONE) \
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

