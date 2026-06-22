TOP=../../..
#PYTHONPATH:=$(TOP)/python:$(PYTHONPATH)
PYTHONPATH:=/home/chet/Hack/Antlr/src/antlr4/runtime/Python3/src:$(PYTHONPATH)

all: compare

compare:: output.NEW
	diff -Bwiu output output.NEW

<lexerName>.py: <lexerName>.g4
	antlr4 -Dlanguage=Python3 <lexerName>.g4

output.NEW:: <lexerName>.py
	env PYTHONPATH=$(PYTHONPATH) python3 Test.py input > output.NEW

clean::
	rm -rf __pycache__ <lexerName>.py <lexerName>.interp <lexerName>.tokens output.NEW
