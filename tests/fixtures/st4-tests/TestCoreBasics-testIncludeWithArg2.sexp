((classname hello)
 (template_s {|load <box("arg", foo())>;|})
 (attributes ((name (SV (STRING Ter)))))
 (groupfile (("a.stg" 
{| box(x,y) ::= "kewl <x> <y> daddy"
   foo() ::= "blech" |})))
 (expected {bar|load kewl arg blech daddy;|bar}))
 