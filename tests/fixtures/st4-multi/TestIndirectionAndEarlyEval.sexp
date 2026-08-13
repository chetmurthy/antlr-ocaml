(
("testEarlyEval"
((classname hello)
 (runs
  (
   ((input "<(name)>")
    (output "Ter")
    (attributes ((name (SV (STRING Ter)))))
    )
   )
  )
 ))
("testIndirectCallWithPassThru"
((classname hello)
  (groupfile (("t.stg" {|
t1(x) ::= "<x>"
main(x="hello",t="t1") ::= <<
<(t)(...)>
>>
 |})))
 (runs
  (
   ((input "<main()>")
    (output "")
    )
   )
  )
 (errors {bar|t.stg 3:34: mismatched input '...' expecting RPAREN
context [anonymous] 1:1 no such template: /main
|bar})
 ))
("testIndirectMap"
((classname hello)
 (groupfile (("a.stg" {| 
a(x) ::= "[<x>]"
test(names,templateName) ::= "hi <names:(templateName)()>!"
|})))
 (runs
  (
   ((input "<test(names,templateName)>")
    (output "hi [Ter][Tom][Sumana]!")
    (attributes
     ((names (MV ((STRING Ter) (STRING Tom) (STRING Sumana)))) (templateName (SV (STRING a))))
     )
    )
   )
  )

 ))
("testIndirectProp"
((classname hello)
 (runs
  (
   ((input "<u.(propname)>: <u.name>")
    (output "1: parrt")
    (attributes ((u (SV (DICT ((id (STRING 1)) (name (STRING parrt))))))
    		 (propname (SV (STRING id)))
    		))
    )
   )
  )

 ))
("testIndirectTemplateInclude"
((classname hello)
  (groupfile (("a.stg" {|
foo() ::= "bar"
test(name) ::= "<(name)()>"
 |})))
 (runs
  (
   ((input "<test(name)>")
    (output "bar")
    (attributes ((name (SV (STRING foo)))))
    )
   )
  )
 ))
("testIndirectTemplateIncludeViaTemplate"
((classname hello)
  (groupfile (("t.stg" {|
foo() ::= "bar"
tname() ::= "foo"
test(name) ::= "<(tname())()>"
 |})))
 (runs
  (
   ((input "<test(name)>")
    (output "bar")
    )
   )
  )
 (errors {bar|context [anonymous] 1:6 attribute name isn't defined
|bar})
 ))
("testIndirectTemplateIncludeWithArgs"
((classname hello)
  (groupfile (("a.stg" {|
foo(x,y) ::= "<x><y>"
test(name) ::= "<(name)({1},{2})>"
 |})))
 (runs
  (
   ((input "<test(name)>")
    (output "12")
    (attributes ((name (SV (STRING foo)))))
    )
   )
  )
 ))
("testNonStringDictLookup"
((classname hello)
 (runs
  (
   ((input "<m.(intkey)>")
    (output "foo")
    (attributes
     ((m (SV (DICT (("36" (STRING foo)))))) (intkey (SV (STRING 36))))
     )
    )
   )
  )

 ))
)
