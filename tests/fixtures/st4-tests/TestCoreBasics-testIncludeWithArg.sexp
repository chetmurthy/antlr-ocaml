((classname hello)
 (template_s {|load <box("arg")>;|})
 (attributes ((name (SV (STRING Ter)))))
 (groupfile (("a.stg" {| box(x) ::= "kewl <x> daddy" |})))
 (expected {bar|load kewl arg daddy;|bar}))
 