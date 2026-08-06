((classname hello)
 (template_s {|<foo:{f | <f>}>|})
 (attributes ())
 (groupfile (("a.stg" {| foo ::= [ "a":"b", "c":"d" ] |})))
 (expected {bar|ac|bar}))
 