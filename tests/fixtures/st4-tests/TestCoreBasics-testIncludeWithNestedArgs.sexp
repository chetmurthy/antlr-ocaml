((classname hello)
 (template_s {|load <box(foo("arg"))>;|})
 (attributes ((name (SV (STRING Ter)))))
 (groupfile (("a.stg" 
{| box(y) ::= "kewl <y> daddy"
   foo(x) ::= "blech <x>" |})))
 (expected {bar|load kewl blech arg daddy;|bar}))
 