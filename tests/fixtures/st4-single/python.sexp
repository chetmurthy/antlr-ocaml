((classname hello)
 (groupfile (("g.stg" {|
import "/home/chet/Hack/Camlp5/src/ALL/antlr-ocaml/tests/fixtures/Python3.test.stg"

handleBeginArgument() ::= <<self.handleBeginArgument();>>
handleEndArgument() ::= <<self.handleEndArgument();>>

prerrln(s) ::= <<print(<s>, file=sys.stderr)>>
prerr(s) ::= <<print(<s>,end='',file=sys.stderr)>>
location() ::= <<("line %s:%s:" % (self._tokenStartLine, self._tokenStartColumn))>>
dquotes(s) ::= <<"<s>">>

|})))
   (runs
    (
     ((input {|{<writeln("\"I\"")>}|})
      (output {bar|{print("I", file=self._output)}|bar})
      (comments {|
basic variable-reference
|}
       )
      )

     ((input {|{<Text():writeln()>}|})
      (output {bar|{print(self.text, file=self._output)}|bar})
      (comments {|
basic variable-reference
|}
       )
      )

     ((input {|{<PlusText("stuff fail: "):writeln()>}|})
      (output {bar|{print("stuff fail: " + self.text, file=self._output)}|bar})
      (comments {|
basic variable-reference
|}
       )
      )

     ((input {|{ <handleBeginArgument()> }|})
      (output {bar|{ self.handleBeginArgument(); }|bar})
      (comments {|
basic variable-reference
|}
       )
      )

     ((input {|{ <handleEndArgument()> }|})
      (output {bar|{ self.handleEndArgument(); }|bar})
      (comments {|
basic variable-reference
|}
       )
      )

     ((input {|{ <prerrln(AppendStr(location(), dquotes(" '\\n' in string")))> }|})
      (output {bar|{ print(("line %s:%s:" % (self._tokenStartLine, self._tokenStartColumn)) + " '\n' in string", file=sys.stderr) }|bar})
      (comments {|
basic variable-reference
|}
       )
      )
     )
    )
   )