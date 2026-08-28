((classname hello)
 (groupfile (("g.stg" {|
import "/home/chet/Hack/Camlp5/src/ALL/antlr-ocaml/tests/fixtures/OCaml.test.stg"

handleBeginArgument() ::= <<ActionFuns.handleBeginArgument self cu>>
handleEndArgument() ::= <<ActionFuns.handleEndArgument self cu>>

prerrln(s) ::= <<(prerr_string (<s>); prerr_newline())>>
prerr(s) ::= <<(prerr_string (<s>))>>
location() ::= <<Fmt.(str "line %d:%d:" self._tokenStartLine self._tokenStartColumn)>>
dquotes(s) ::= <<"<s>">>

|})))
   (runs
    (
     ((input {|{<writeln("\"I\"")>}|})
      (output {bar|{output_string stdout ("I"^"\n")}|bar})
      (comments {|
basic variable-reference
|}
       )
      )

     ((input {|{<Text():writeln()>}|})
      (output {bar|{output_string stdout ((R.text self cu)^"\n")}|bar})
      (comments {|
basic variable-reference
|}
       )
      )

     ((input {|{<PlusText("stuff fail: "):writeln()>}|})
      (output {bar|{output_string stdout (("stuff fail: " ^ (R.text self cu))^"\n")}|bar})
      (comments {|
basic variable-reference
|}
       )
      )

     ((input {|{ <handleBeginArgument()> }|})
      (output {bar|{ ActionFuns.handleBeginArgument self cu }|bar})
      (comments {|
basic variable-reference
|}
       )
      )

     ((input {|{ <handleEndArgument()> }|})
      (output {bar|{ ActionFuns.handleEndArgument self cu }|bar})
      (comments {|
basic variable-reference
|}
       )
      )
     ((input {|{ <prerrln(AppendStr(location(), dquotes(" '\\n' in string")))> }|})
      (output {bar|{ (prerr_string (Fmt.(str "line %d:%d:" self._tokenStartLine self._tokenStartColumn) ^ " '\n' in string"); prerr_newline()) }|bar})
      (comments {|
basic variable-reference
|}
       )
      )

     )
    )
   )