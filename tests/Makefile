WD=$(shell pwd)
TOP=..
include $(TOP)/config/Makefile.sub

PACKAGES := $(PACKAGES),antlr,ounit2,cmdliner,yojson,antlrtest

ML= \
	lib_test.ml antlr_test.ml roundtrip_atn.ml \
	antlrtest_test.ml generate_antlrtest.ml

ALLSRC=$(ML)
ALLPACKAGES=$(PACKAGES)

TESTS=lib_test.exe antlr_test.exe roundtrip_atn.exe \
	antlrtest_test.exe generate_antlrtest.exe

all: $(TESTS)

test:: all
	mkdir -p _build && ./lib_test.exe
	mkdir -p _build && ./antlr_test.exe
	mkdir -p _build && ./antlrtest_test.exe

generate-all:: antlrtest_test.exe
	mkdir -p _build && set -e ; set -x ;\
	for d in `cd fixtures/descriptors ; find . -name '*.txt' -print` ;\
	do \
	rm -rf _build/$${d/.txt/} && \
	./generate_antlrtest.exe -d _build/$${d/.txt/} \
	fixtures/descriptors/$$d ;\
	done

DTEST=LexerExec/CharSet ParserExec/Basic
generate-selected:: antlrtest_test.exe
	mkdir -p _build && set -e ; set -x ;\
	for d in $(DTEST) ;\
	do \
	rm -rf _build/$$d && \
	./generate_antlrtest.exe -d _build/$$d \
	fixtures/descriptors/$$d.txt ;\
	done

test-selected:: antlrtest_test.exe
	set -e ; set -x ;\
	for d in $(DTEST) ;\
	do \
	$(MAKE) -C _build/$$d all ;\
	done

#ONE=LexerExec/CharSet
#ONE=ParserExec/Basic
#ONE=CompositeParsers/ImportLexerWithOnlyFragmentRules
ONE=CompositeParsers/KeywordVSIDOrder
generate-one:: antlrtest_test.exe
	mkdir -p _build && \
	rm -rf _build/X && \
	./generate_antlrtest.exe -d _build/$(ONE) \
	fixtures/descriptors/$(ONE).txt

lib_test.exe: lib_test.cmo
	$(LAUNCH) $(OCAMLFIND) ocamlc -linkall -linkpkg $(DEBUG) $(OCAMLCFLAGS) -package $(PACKAGES) -linkpkg -linkall -o $@ $<

antlr_test.exe: antlr_test.cmo
	$(LAUNCH) $(OCAMLFIND) ocamlc -linkall -linkpkg $(DEBUG) $(OCAMLCFLAGS) -package $(PACKAGES) -linkpkg -linkall -o $@ $<

antlrtest_test.exe: antlrtest_test.cmo
	$(LAUNCH) $(OCAMLFIND) ocamlc -linkall -linkpkg $(DEBUG) $(OCAMLCFLAGS) -package $(PACKAGES) -linkpkg -linkall -o $@ $<

generate_antlrtest.exe: generate_antlrtest.cmo
	$(LAUNCH) $(OCAMLFIND) ocamlc -linkall -linkpkg $(DEBUG) $(OCAMLCFLAGS) -package $(PACKAGES) -linkpkg -linkall -o $@ $<

roundtrip_atn.exe: roundtrip_atn.cmo
	$(LAUNCH) $(OCAMLFIND) ocamlc -linkall -linkpkg $(DEBUG) $(OCAMLCFLAGS) -package $(PACKAGES) -linkpkg -linkall -o $@ $<


SHELL := /bin/bash
FILE := CalcLexer.interp
#FILE := /home/chet/Hack/Antlr/src/grammars-v4/antlr/antlr4/examples/grammars-v4/cmake/CMakeLexer.interp
#ATNDEBUG=--debug
#ATNVERIFY=--disable-verify
ATNJSON=--json
compare-one:: roundtrip_atn.exe
	diff -bBwi -u10 <( python3 deserialize_test.py $(FILE) ) <( ./roundtrip_atn.exe $(ATNVERIFY) $(ATNDEBUG) $(ATNJSON) $(FILE) )

run-python::
	python3 deserialize_test.py $(FILE)

run-ocaml:: roundtrip_atn.exe
	./roundtrip_atn.exe $(ATNVERIFY) $(ATNDEBUG) $(ATNJSON) $(FILE)

ANTLRDIRS= ~/Hack/Antlr/src/antlr4 ~/Hack/Antlr/src/grammars-v4
compare-all:: roundtrip_atn.exe
	set -e ;\
	for f in `find $(ANTLRDIRS) -name '*.interp' -print`; \
	do \
	echo "================ $$f ================" ; \
	diff -bBwi -u10 <( python3 deserialize_test.py $$f ) <( ./roundtrip_atn.exe $(ATNVERIFY) $(ATNDEBUG) $(ATNJSON) $$f ) ; \
	done

test-python::
	python3 deserialize_test.py /home/chet/Hack/Antlr/src/antlr4/runtime-testsuite/test/org/antlr/v4/test/runtime/java/api/JavaLexer.interp

test-all-python::
	find $(ANTLRROOT) -name '*.interp' -print | xargs -n 1 --verbose python3 deserialize_test.py 

clean::
	rm -rf *.cm* _build *.exe

