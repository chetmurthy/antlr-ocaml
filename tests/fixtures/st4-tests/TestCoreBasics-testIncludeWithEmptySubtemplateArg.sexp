((classname hello)
 (template_s {|load <box({})>;|})
 (attributes ((name (SV (STRING Ter)))))
 (groupfile (("a.stg" {| box(x) ::= "kewl <x> daddy" |})))
 (expected {bar|load kewl  daddy;|bar}))
 