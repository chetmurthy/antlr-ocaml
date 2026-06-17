WD=$(shell pwd)
TOP=..
include $(TOP)/config/Makefile.sub

PACKAGES := $(PACKAGES),antlr,ounit2,cmdliner

ML= \
	lib_test.ml antlr_test.ml roundtrip_atn.ml \

ALLSRC=$(ML)
ALLPACKAGES=$(PACKAGES)

TESTS=lib_test.exe antlr_test.exe roundtrip_atn.exe

all: $(TESTS)

test:: all
	mkdir -p _build && ./lib_test.exe
	mkdir -p _build && ./antlr_test.exe

lib_test.exe: lib_test.cmo
	$(LAUNCH) $(OCAMLFIND) ocamlc -linkall -linkpkg $(OCAMLCFLAGS) -package $(PACKAGES) -linkpkg -linkall -o $@ $<

antlr_test.exe: antlr_test.cmo
	$(LAUNCH) $(OCAMLFIND) ocamlc -linkall -linkpkg $(OCAMLCFLAGS) -package $(PACKAGES) -linkpkg -linkall -o $@ $<

roundtrip_atn.exe: roundtrip_atn.cmo
	$(LAUNCH) $(OCAMLFIND) ocamlc -linkall -linkpkg $(OCAMLCFLAGS) -package $(PACKAGES) -linkpkg -linkall -o $@ $<


SHELL := /bin/bash
#FILE := CalcLexer.interp
FILE := /home/chet/Hack/Antlr/src/antlr4/antlr4-maven-plugin/src/test/projects/importsCustom/src/main/antlr4/imports/TestBaseLexer.interp
ATNDEBUG=--debug
#ATNVERIFY=--disable-verify
compare-one:: roundtrip_atn.exe
	diff -bBwi -u10 <( python3 deserialize_test.py $(FILE) ) <( ./roundtrip_atn.exe $(ATNVERIFY) $(ATNDEBUG) $(FILE) )

run-python::
	python3 deserialize_test.py $(FILE)

run-ocaml:: roundtrip_atn.exe
	./roundtrip_atn.exe $(ATNVERIFY) $(ATNDEBUG) $(FILE)

compare-all:: roundtrip_atn.exe
	set -e ;\
	for f in `find ~/Hack/Antlr/src/antlr4 -name '*.interp' -print`; \
	do \
	echo "================ $$f ================" ; \
	diff -bBwiu <( python3 deserialize_test.py $$f ) <( ./roundtrip_atn.exe $$f ) ; \
	done

test-python::
	python3 deserialize_test.py /home/chet/Hack/Antlr/src/antlr4/runtime-testsuite/test/org/antlr/v4/test/runtime/java/api/JavaLexer.interp

test-all-python::
	find $(ANTLRROOT) -name '*.interp' -print | xargs -n 1 --verbose python3 deserialize_test.py 

clean::
	rm -rf *.cm* _build *.exe

