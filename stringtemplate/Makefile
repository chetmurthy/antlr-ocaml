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
	l_stg_constants.ml l_st_constants.ml \
	actionFuns_st.ml \
	l_stg.ml l_st.ml \
	st_types.ml stg_types.ml \
	camlp5_adapter.ml \
	pa_st.ml pa_stg.ml


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

bootstrap:: ../tests/atn_util.opt
	cp $(TOP)/tests/fixtures/grammar-lib/Lex* grammars/
	cp $(TOP)/tests/fixtures/grammar-lib/ST*.g4 grammars/
	cp $(TOP)/tests/fixtures/pertest-files/antlr4/ST1/translation.json .
	cp $(TOP)/tests/fixtures/pertest-files/antlr4/ST1/actionFuns_st.ml actionFuns_st.ml 
	(cd grammars && antlr4 -Dlanguage=Python3 STGLexer.g4)
	(cd grammars && antlr4 -Dlanguage=Python3 STLexer.g4)
	$(TOP)/tests/atn_util.opt emit-ocaml-lexer \
	  -i grammars/STGLexer.interp \
	  --grammar-lib grammars \
	  -t translation.json \
	  grammars/STGLexer.g4 > l_stg.ml.NEW && mv l_stg.ml.NEW l_stg.ml
	$(TOP)/tests/atn_util.opt emit-ocaml-constants \
	  grammars/STGLexer.interp > l_stg_constants.ml.NEW && \
	  mv l_stg_constants.ml.NEW l_stg_constants.ml
	$(TOP)/tests/atn_util.opt emit-ocaml-lexer \
	  -i grammars/STLexer.interp \
	  --grammar-lib grammars \
	  -t translation.json \
	  grammars/STLexer.g4 > l_st.ml.NEW && mv l_st.ml.NEW l_st.ml
	$(TOP)/tests/atn_util.opt emit-ocaml-constants \
	  grammars/STLexer.interp > l_st_constants.ml.NEW && \
	  mv l_st_constants.ml.NEW l_st_constants.ml



#	$(TOP)/tests/atn_util.opt emit-ocaml-atn grammars/Lexer.interp > ANTLRv4Lexer_atn.ml.NEW && mv ANTLRv4Lexer_atn.ml.NEW ANTLRv4Lexer_atn.ml

$(TARGET_PACKAGE).cmo $(TARGET_PACKAGE).cmi: $(CMO)
	$(OCAMLFIND) ocamlc $(DEBUG) -pack -o $(TARGET_PACKAGE).cmo $^

$(TARGET_PACKAGE).cmx: $(CMO:.cmo=.cmx)
	$(OCAMLFIND) ocamlopt $(DEBUG) -pack -o $(TARGET_PACKAGE).cmx $^

$(TARGET): $(TARGET_PACKAGE).cmo
	$(OCAMLFIND) ocamlc $(DEBUG) $^ -a -o $(TARGET)

$(TARGET:.cma=.cmxa): $(TARGET_PACKAGE).cmx
	$(OCAMLFIND) ocamlopt $(DEBUG) $^ -a -o $(TARGET:.cma=.cmxa)
