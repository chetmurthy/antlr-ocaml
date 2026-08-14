# TODO list

1. [half-done] fix locations in ANTLR lexer

   - done for stringtemplate
   - not done/tested for parse_antlrv4

2. start evaluator

3. add code to cause Python and OCaml lexers to raise error on first lex failure

4. and update DTESTs and STTESTs to run with this enabled, update error text.

5. a new dtest-runner:

a test-runner that:

(-z): test-name is either empty (== DEFAULT) or a string

(a) given the test-name, will create and enter into a directory for the outputs

(b) given either ocaml or python, will run that test on the #a-named input

(c) flags for json, named-types for the output

(d) so 2^3 cases:

  * ocaml or python
  * jsonlogging
  * named-types
  * [when parser grammar] full or lexer-only

(e) diffs between expected and python for named-types=false,  lexer-only=false

(f) diffs between ocaml and python for each case

(g) if each case in a separate dir, no need to conditionalize on jsonlogging

(h) expected files and inputs are kept in main dir

commands:

run

 --ocaml / --python
 --lexer-only
 --named-types


compare

  --expected [otherwise, ocaml-vs-python]
  --lexer-only
  --named-types


directory-format:

_build/<test-name>/

  - subdirs {,lexer-only-}{ocaml,python}{,-named-types}
  - contents:

    - output, errors
    - json.log.RAW, json.log
