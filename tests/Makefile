WD=$(shell pwd)
TOP=..
include $(TOP)/config/Makefile.sub

PACKAGES := $(PACKAGES),antlr,ounit2

ML= \
	lib_test.ml antlr_test.ml \

ALLSRC=$(ML)
ALLPACKAGES=$(PACKAGES)

TESTS=lib_test.exe antlr_test.exe

all: $(TESTS)

test:: all
	mkdir -p _build && ./lib_test.exe
	mkdir -p _build && ./antlr_test.exe

lib_test.exe: lib_test.cmo
	$(LAUNCH) $(OCAMLFIND) ocamlc -linkall -linkpkg $(OCAMLCFLAGS) -package $(PACKAGES) -linkpkg -linkall -o $@ $<

antlr_test.exe: antlr_test.cmo
	$(LAUNCH) $(OCAMLFIND) ocamlc -linkall -linkpkg $(OCAMLCFLAGS) -package $(PACKAGES) -linkpkg -linkall -o $@ $<

clean::
	rm -rf *.cm* _build *.exe

