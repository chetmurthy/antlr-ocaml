WD=$(shell pwd)
TOP=..
include $(TOP)/config/Makefile.sub

ifndef JSONLOGGING
export JSONLOGGING=0
endif

PACKAGES := $(PACKAGES),antlr,parse_antlrv4,ounit2,cmdliner,yojson,antlrtest,pa_ppx.runtime

ML= \
	lib_test.ml antlr_test.ml atn_util.ml mimick_test.ml \
	antlrtest_test.ml antlrtest_util.ml deserialize_jsonlog.ml \
	replay_util.ml parser_test.ml grammar_tools_test.ml

ALLSRC=$(ML)
ALLPACKAGES=$(PACKAGES)

EXE=lib_test.exe antlr_test.exe atn_util.exe mimick_test.exe \
	antlrtest_test.exe antlrtest_util.exe \
	deserialize_jsonlog.exe replay_util.exe \
	parser_test.exe grammar_tools_test.exe

TESTML=$(shell ls *_test.ml)

OPT=$(EXE:.exe=.opt)

all: $(EXE) $(OPT)

test:: all $(TESTML:.ml=.TEST)

%.TEST: %.opt
	mkdir -p _build && ./$<

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
generate-all:: antlrtest_test.exe
	mkdir -p _generated && $(MANAGETRIP) generate -v

python-prepare-all:: antlrtest_test.exe
	$(MANAGETRIP) python-prepare -v

depend-all:: antlrtest_test.exe
	$(MANAGETRIP) depend -v

compile-all:: antlrtest_test.exe
	$(MANAGETRIP) compile -v

python-test-all:: antlrtest_test.exe
	$(MANAGETRIP) python-test -v

clean-all:: antlrtest_test.exe
	$(MANAGETRIP) clean -v

realclean-all:: antlrtest_test.exe
	$(MANAGETRIP) realclean -v

compare-all:: antlrtest_test.exe
	$(MANAGETRIP) compare-atns -v

update-pertest-all:: antlrtest_test.exe
	$(MANAGETRIP) update-pertest -v

ocaml-compile-all:: antlrtest_test.exe
	$(MANAGETRIP) ocaml-compile -v

ocaml-test-all:: antlrtest_test.exe
	$(MANAGETRIP) ocaml-test -v

ocaml-compare-all:: antlrtest_test.exe
	$(MANAGETRIP) ocaml-compare -v

#DTEST=$(shell ls fixtures/descriptors/LexerExec/*)
#CTEST=$(shell ls fixtures/custom-descriptors/*/*)
DTEST=\
	fixtures/descriptors/LexerExec/CharSet.txt \
	fixtures/descriptors/LexerExec/CharSetRange.txt \
	fixtures/descriptors/LexerExec/CharSetInSet.txt \
	fixtures/descriptors/LexerExec/CharSetNot.txt \
	fixtures/descriptors/LexerExec/CharSetPlus.txt \
	fixtures/descriptors/LexerExec/CharSetWithEscapedChar.txt \
	fixtures/descriptors/LexerExec/CharSetWithMissingEscapeChar.txt \
	fixtures/descriptors/LexerExec/CharSetWithQuote1.txt \
	fixtures/descriptors/LexerExec/CharSetWithQuote2.txt \
	fixtures/descriptors/LexerExec/EOFByItself.txt \
	fixtures/descriptors/LexerExec/EOFSuffixInFirstRule_1.txt \
	fixtures/descriptors/LexerExec/EOFSuffixInFirstRule_2.txt \
	fixtures/descriptors/LexerExec/EscapedCharacters.txt \
	fixtures/descriptors/LexerExec/EscapeTargetStringLiteral.txt \
	fixtures/descriptors/LexerExec/GreedyClosure.txt \
	fixtures/descriptors/LexerExec/GreedyOptional.txt \
	fixtures/descriptors/LexerExec/GreedyPositiveClosure.txt \
	fixtures/descriptors/LexerExec/HexVsID.txt \
	fixtures/descriptors/LexerExec/KeywordID.txt \
	fixtures/descriptors/LexerExec/NonGreedyClosure.txt \
	fixtures/descriptors/LexerExec/NonGreedyOptional.txt \
	fixtures/descriptors/LexerExec/NonGreedyPositiveClosure.txt \
	fixtures/descriptors/LexerExec/NonGreedyTermination1.txt \
	fixtures/descriptors/LexerExec/NonGreedyTermination2.txt \
	fixtures/descriptors/LexerExec/Parentheses.txt \
	fixtures/descriptors/LexerExec/QuoteTranslation.txt \
	fixtures/descriptors/LexerExec/GreedyConfigs.txt \
	fixtures/descriptors/LexerExec/NonGreedyConfigs.txt \
	fixtures/descriptors/LexerExec/ActionPlacement.txt \
	fixtures/descriptors/LexerExec/RecursiveLexerRuleRefWithWildcardPlus_1.txt \
	fixtures/descriptors/LexerExec/RecursiveLexerRuleRefWithWildcardPlus_2.txt \
	fixtures/descriptors/LexerExec/RecursiveLexerRuleRefWithWildcardStar_1.txt \
	fixtures/descriptors/LexerExec/RecursiveLexerRuleRefWithWildcardStar_2.txt \
	fixtures/descriptors/LexerExec/RefToRuleDoesNotSetTokenNorEmitAnother.txt \
	fixtures/descriptors/LexerExec/ReservedWordsEscaping_NULL.txt \
	fixtures/descriptors/LexerExec/ReservedWordsEscaping.txt \
	fixtures/descriptors/LexerExec/Slashes.txt \
	fixtures/descriptors/LexerExec/StackoverflowDueToNotEscapedHyphen.txt \
	fixtures/descriptors/LexerExec/TokenType0xFFFF.txt \
	fixtures/descriptors/LexerExec/UnicodeCharSet.txt \
	fixtures/descriptors/LexerExec/ZeroLengthToken.txt \


DTEST += \
	fixtures/descriptors/LexerErrors/DFAToATNThatFailsBackToDFA.txt \
	fixtures/descriptors/LexerErrors/DFAToATNThatMatchesThenFailsInATN.txt \
	fixtures/descriptors/LexerErrors/EnforcedGreedyNestedBraces_1.txt \
	fixtures/descriptors/LexerErrors/EnforcedGreedyNestedBraces_2.txt \
	fixtures/descriptors/LexerErrors/ErrorInMiddle.txt \
	fixtures/descriptors/LexerErrors/InvalidCharAtStartAfterDFACache.txt \
	fixtures/descriptors/LexerErrors/InvalidCharAtStart.txt \
	fixtures/descriptors/LexerErrors/InvalidCharInTokenAfterDFACache.txt \
	fixtures/descriptors/LexerErrors/InvalidCharInToken.txt \
	fixtures/descriptors/LexerErrors/LexerExecDFA.txt \
	fixtures/descriptors/LexerErrors/StringsEmbeddedInActions_1.txt \
	fixtures/descriptors/LexerErrors/StringsEmbeddedInActions_2.txt \

DTEST += \
	fixtures/descriptors/CompositeLexers/LexerDelegatorInvokesDelegateRule.txt \
	fixtures/descriptors/CompositeLexers/LexerDelegatorRuleOverridesDelegate.txt \

DTEST += \
	fixtures/descriptors/SemPredEvalLexer/DisableRule.txt \
	fixtures/descriptors/SemPredEvalLexer/EnumNotID.txt \
	fixtures/descriptors/SemPredEvalLexer/IDnotEnum.txt \
	fixtures/descriptors/SemPredEvalLexer/IDvsEnum.txt \
	fixtures/descriptors/SemPredEvalLexer/Indent.txt \
	fixtures/descriptors/SemPredEvalLexer/LexerInputPositionSensitivePredicates.txt \
	fixtures/descriptors/SemPredEvalLexer/PredicatedKeywords.txt \
	fixtures/descriptors/SemPredEvalLexer/RuleSempredFunction.txt \

#DTEST := \
#	fixtures/descriptors/ParserExec/Basic.txt

DTEST += \
	fixtures/custom-descriptors/antlr4/ANTLRv4Lexer.txt \
	fixtures/custom-descriptors/antlr4/A2.txt \
	fixtures/custom-descriptors/SemPredEvalLexer/IdentKinds.txt \

DTEST += \
	fixtures/custom-descriptors/SemPredEvalLexer/ManyPredsActions.txt \
	fixtures/custom-descriptors/SemPredEvalLexer/ManyPredsActions.2.txt \
	fixtures/custom-descriptors/SemPredEvalLexer/ManyPredsActions.3.txt \

DTEST += \
	fixtures/custom-descriptors/CompositeLexers/LexerDelegatorRuleOverridesDelegate.1.txt \
	fixtures/custom-descriptors/CompositeLexers/LexerDelegatorRuleOverridesDelegate.2.txt \

DTEST := \
	fixtures/descriptors/ParserExec/Basic.txt \
	fixtures/descriptors/LexerExec/CharSet.txt \
	fixtures/custom-descriptors/antlr4/ANTLRv4Lexer.txt \
	fixtures/custom-descriptors/antlr4/A2.txt \
	fixtures/custom-descriptors/antlr4/A3.txt \

DTEST += \
	fixtures/custom-descriptors/antlr4/ST1.txt \


SELECTED=$(DTEST) $(CTEST)
generate-selected:: antlrtest_test.exe
	mkdir -p _generated && $(MANAGETRIP) generate -v $(SELECTED)

python-prepare-selected:: antlrtest_test.exe
	$(MANAGETRIP) python-prepare -v $(SELECTED)

depend-selected:: antlrtest_test.exe
	$(MANAGETRIP) depend -v $(SELECTED)

compile-selected:: antlrtest_test.exe
	$(MANAGETRIP) compile -v $(SELECTED)

python-test-selected:: antlrtest_test.exe
	$(MANAGETRIP) python-test -v $(SELECTED)

clean-selected:: antlrtest_test.exe
	$(MANAGETRIP) clean -v $(SELECTED)

realclean-selected:: antlrtest_test.exe
	$(MANAGETRIP) realclean -v $(SELECTED)

compare-selected:: antlrtest_test.exe
	$(MANAGETRIP) compare-atns -v $(SELECTED)

update-pertest-selected:: antlrtest_test.exe
	$(MANAGETRIP) update-pertest -v $(SELECTED)

ocaml-compile-selected:: antlrtest_test.exe
	$(MANAGETRIP) ocaml-compile -v $(SELECTED)

ocaml-test-selected:: antlrtest_test.exe
	$(MANAGETRIP) ocaml-test -v $(SELECTED)

ocaml-compare-selected:: antlrtest_test.exe
	$(MANAGETRIP) ocaml-compare -v $(SELECTED)

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
	find $(ANTLRDIRS) -name '*.interp' -print | xargs -n 1 --verbose python3 deserialize_test.py > /dev/null

clean::
	rm -rf *.cm* _build *.exe _generated/*.log


realclean:: clean
	rm -rf _generated
