WD=$(shell pwd)
TOP=..
include $(TOP)/config/Makefile.sub

ifndef JSONLOGGING
export JSONLOGGING=0
endif

PACKAGES := $(PACKAGES),antlr,parse_antlrv4,stringtemplate,ounit2,cmdliner,yojson,antlrtest,pa_ppx.runtime

ML= \
	lib_test.ml antlr_test.ml atn_util.ml mimick_test.ml \
	antlrtest_test.ml antlrtest_util.ml deserialize_jsonlog.ml \
	replay_util.ml parser_test.ml grammar_tools_test.ml \
	stringtemplate_test.ml stringtemplate_util.ml \
	location_handling_test.ml \
	testmatrix.ml

ALLSRC=$(ML)
ALLPACKAGES=$(PACKAGES)

EXE=lib_test.exe antlr_test.exe atn_util.exe mimick_test.exe \
	antlrtest_test.exe antlrtest_util.exe \
	deserialize_jsonlog.exe replay_util.exe \
	parser_test.exe grammar_tools_test.exe \
	stringtemplate_test.exe stringtemplate_util.exe \
	location_handling_test.exe \
	testmatrix.exe

TESTML=$(shell ls *_test.ml)

OPT=$(EXE:.exe=.opt)

all: $(EXE) $(OPT)

test:: all $(TESTML:.ml=.TEST)

test-fully:: test dtest-all sttest-multi sttest-multi-verify

%.TEST: %.opt %.exe
	mkdir -p _build && ./$< -runner sequential -shards 1

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

DTEST := \
	fixtures/custom-descriptors/antlr4/DTestTest.txt \
	fixtures/descriptors/ParserExec/Basic.txt \
	fixtures/custom-descriptors/antlr4/ST0.txt \
	fixtures/custom-descriptors/antlr4/ST1.txt \
	fixtures/custom-descriptors/antlr4/ST2.txt \
	fixtures/custom-descriptors/antlr4/STG1.txt \
	fixtures/descriptors/SemPredEvalLexer/Indent.txt \

DTEST := \
	fixtures/custom-descriptors/antlr4/ST0.txt \
	fixtures/custom-descriptors/antlr4/ST1.txt \
	fixtures/custom-descriptors/antlr4/ST2.txt \

DALL=$(shell ls fixtures/descriptors/*/*) $(shell ls fixtures/custom-descriptors/*/*)

DTESTCMD=full -v

%.DTEST: %.txt
	$(MANAGETRIP) $(DTESTCMD) $<

full-selected:: antlrtest_test.exe
	$(MANAGETRIP) $(DTESTCMD) $(DTEST)

dtest-selected: $(DTEST:.txt=.DTEST)

dtest-all: $(DALL:.txt=.DTEST)

STJSONALL=$(shell ls fixtures/st4-single/*.json)
STSEXPALL=$(shell ls fixtures/st4-single/*.sexp)

ST4UTIL=$(TOP)/tests/stringtemplate_util.opt
ST4GEN=_generated/st4

%.STTEST: %.json
	$(ST4UTIL) generate -f -d $(ST4GEN) $<
	$(ST4UTIL) compile -d $(ST4GEN) $<
	$(ST4UTIL) execute -d $(ST4GEN) $<
	$(ST4UTIL) check -d $(ST4GEN) $<

%.STTEST: %.sexp
	$(ST4UTIL) generate -f -d $(ST4GEN) $<
	$(ST4UTIL) compile -d $(ST4GEN) $<
	$(ST4UTIL) execute -d $(ST4GEN) $<
	$(ST4UTIL) check -d $(ST4GEN) $<

STTESTCMD=full -f -d $(ST4GEN)
sttest-multi:: fixtures/st4-multi/TestNullEmptyMatrix.sexp
	$(ST4UTIL) $(STTESTCMD) -m fixtures/st4-multi/TestCoreBasics.sexp
	$(ST4UTIL) $(STTESTCMD) -m fixtures/st4-multi/TestDictionaries.sexp
	$(ST4UTIL) $(STTESTCMD) -m fixtures/st4-multi/TestGroup.sexp
	$(ST4UTIL) $(STTESTCMD) -m fixtures/st4-multi/TestIndentation.sexp
	$(ST4UTIL) $(STTESTCMD) -m fixtures/st4-multi/TestLists.sexp
	$(ST4UTIL) $(STTESTCMD) -m fixtures/st4-multi/TestNoNewlineTemplates.sexp
	$(ST4UTIL) $(STTESTCMD) -m fixtures/st4-multi/TestOptions.sexp
	$(ST4UTIL) $(STTESTCMD) -m fixtures/st4-multi/TestSubtemplates.sexp
	$(ST4UTIL) $(STTESTCMD) -m fixtures/st4-multi/TestWhitespace.sexp
	$(ST4UTIL) $(STTESTCMD) -m fixtures/st4-multi/TestNullEmptyMatrix.sexp
	$(ST4UTIL) $(STTESTCMD) -m fixtures/st4-multi/TestIndirectionAndEarlyEval.sexp

sttest-multi-verify:
	$(MAKE) STTESTCMD="verify" sttest-multi

fixtures/st4-multi/TestNullEmptyMatrix.sexp: testmatrix.exe
	./testmatrix.exe > $@.NEW && mv $@.NEW $@

sttest-all: $(STJSONALL:.json=.STTEST) $(STSEXPALL:.sexp=.STTEST)

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

%.opt: %.cmx %.cmi
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
