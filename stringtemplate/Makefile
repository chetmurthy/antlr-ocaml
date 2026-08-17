# Makefile,v
# Copyright (c) INRIA 2007-2017

WD=$(shell pwd)
TOP=..
include $(TOP)/config/Makefile.sub

DESTDIR=

PACKAGES := $(PACKAGES),antlr

TARGET_PACKAGE=stringtemplate
TARGET = $(TARGET_PACKAGE).cma

ML=\
	lexerBase.ml \
	st_util.ml \
	ST0Lexer_constants.ml ST1Lexer_constants.ml ST2Lexer_constants.ml STG0Lexer_constants.ml STG2Lexer_constants.ml \
	ActionFuns_ST0.ml ActionFuns_ST1.ml ActionFuns_ST2.ml ActionFuns_STG2.ml \
	ST0Lexer.ml ST1Lexer.ml ST2Lexer.ml STG0Lexer.ml STG2Lexer.ml \
	st_types.ml sttypes2.ml stg_types.ml \
	camlp5_adapter.ml \
	pa_st.ml \
	pa.ml \
	st_ops.ml \
	eval.ml \
	testharness.ml old_testharness.ml \
	sexpio.ml

TOOLSML = mk_meta.ml
ALLSRC=$(ML) $(TOOLSML)
ALLPACKAGES=$(PACKAGES)

OCAMLCFLAGS := $(OCAMLCFLAGS) -for-pack Stringtemplate

all: $(TARGET) $(TARGET:.cma=.cmxa)
	$(MAKE) DESTDIR=$(WD)/$(TOP)/local-install/ install

doc: $(CMT) $(CMTI)

TARGET_INSTALL_FILES= $(PACKED_ARCHIVE_TARGET_INSTALL_FILES)
install:: default_install

local-install::
	$(MAKE) DESTDIR=$(WD)/$(TOP)/local-install/ install

clean::
	rm -rf META mk_meta mk_meta.ml

LEXERS=ST0Lexer ST1Lexer ST2Lexer

bootstrap:: ../tests/atn_util.opt
	env TOP=$(TOP) ./bootstrap-lexers
	env TOP=$(TOP) ./regenerate-lexers
#	$(TOP)/tests/atn_util.opt emit-ocaml-atn grammars/Lexer.interp > ANTLRv4Lexer_atn.ml.NEW && mv ANTLRv4Lexer_atn.ml.NEW ANTLRv4Lexer_atn.ml

regenerate:: ../tests/atn_util.opt
	env TOP=$(TOP) ./regenerate-lexers

$(TARGET_PACKAGE).cmo $(TARGET_PACKAGE).cmi: $(CMO)
	$(OCAMLFIND) ocamlc $(DEBUG) -pack -o $(TARGET_PACKAGE).cmo $^

$(TARGET_PACKAGE).cmx: $(CMO:.cmo=.cmx)
	$(OCAMLFIND) ocamlopt $(DEBUG) -pack -o $(TARGET_PACKAGE).cmx $^

$(TARGET): $(TARGET_PACKAGE).cmo
	$(OCAMLFIND) ocamlc $(DEBUG) $^ -a -o $(TARGET)

$(TARGET:.cma=.cmxa): $(TARGET_PACKAGE).cmx
	$(OCAMLFIND) ocamlopt $(DEBUG) $^ -a -o $(TARGET:.cma=.cmxa)
