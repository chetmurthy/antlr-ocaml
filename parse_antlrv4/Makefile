# Makefile,v
# Copyright (c) INRIA 2007-2017

WD=$(shell pwd)
TOP=..
include $(TOP)/config/Makefile.sub

DESTDIR=

PACKAGES := $(PACKAGES),antlr

TARGET_PACKAGE=parse_antlrv4
TARGET = $(TARGET_PACKAGE).cma

ML=\
	lexerBase.ml l_constants.ml actionFuns.ml l.ml \
	camlp5_adapter.ml \
	grammar_types.ml pa.ml migrate_grammar.ml grammar_tools.ml

TOOLSML = mk_meta.ml
ALLSRC=$(ML) $(TOOLSML)
ALLPACKAGES=$(PACKAGES)

OCAMLCFLAGS := $(OCAMLCFLAGS) -for-pack Parse_antlrv4

all: $(TARGET) $(TARGET:.cma=.cmxa)
	$(MAKE) DESTDIR=$(WD)/$(TOP)/local-install/ install

doc: $(CMT) $(CMTI)

TARGET_INSTALL_FILES= $(PACKED_ARCHIVE_TARGET_INSTALL_FILES)
install:: default_install

local-install::
	$(MAKE) DESTDIR=$(WD)/$(TOP)/local-install/ install

clean::
	rm -rf META mk_meta mk_meta.ml

bootstrap:: ../tests/atn_util.opt
	(cd grammars && antlr4 -Dlanguage=Python3 ANTLRv4Lexer.g4)
	$(TOP)/tests/atn_util.opt emit-ocaml-lexer -i grammars/ANTLRv4Lexer.interp --grammar-lib $(TOP)/tests/fixtures/grammar-lib -t $(TOP)/tests/translation.json grammars/ANTLRv4Lexer.g4 > l.ml.NEW && mv l.ml.NEW l.ml
	$(TOP)/tests/atn_util.opt emit-ocaml-constants grammars/ANTLRv4Lexer.interp > l_constants.ml.NEW && mv l_constants.ml.NEW l_constants.ml


$(TARGET_PACKAGE).cmo $(TARGET_PACKAGE).cmi: $(CMO)
	$(OCAMLFIND) ocamlc $(DEBUG) -pack -o $(TARGET_PACKAGE).cmo $^

$(TARGET_PACKAGE).cmx: $(CMO:.cmo=.cmx)
	$(OCAMLFIND) ocamlopt $(DEBUG) -pack -o $(TARGET_PACKAGE).cmx $^

$(TARGET): $(TARGET_PACKAGE).cmo
	$(OCAMLFIND) ocamlc $(DEBUG) $^ -a -o $(TARGET)

$(TARGET:.cma=.cmxa): $(TARGET_PACKAGE).cmx
	$(OCAMLFIND) ocamlopt $(DEBUG) $^ -a -o $(TARGET:.cma=.cmxa)
