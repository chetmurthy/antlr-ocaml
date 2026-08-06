(
 ("hello"
  ((classname hello) (template_s "<{Hello, <name>!}>")
   (attributes ((name (SV (STRING World))))) (groupfile ())
   (expected "Hello, World!"))
  )
 ("TestCoreBasics-testNullAttr"
  ((classname testNullAttr)
   (template_s {|hi <name>!|})
   (attributes ())
   (groupfile ())
   (expected {bar|hi !|bar}))
  )
 ("TestCoreBasics-testAttrIsList"
  ((classname hello)
   (template_s {|hi <name>!|})
   (attributes ((name (MV ((LIST ((STRING Ter) (STRING Tom))) (STRING Sumana))))))
   (groupfile ())
   (expected {bar|hi TerTomSumana!|bar})))
 ("TestCoreBasics-testAttr"
  ((classname hello)
   (template_s {|hi <name>!|})
   (attributes ((name (SV (STRING "Ter")))))
   (groupfile ())
   (expected {bar|hi Ter!|bar}))
  )
 ("TestCoreBasics-testBoolean1"
  ((classname hello) (template_s "<{Hello, <name>!}>")
   (attributes ((name (SV (BOOL true))))) (groupfile ())
   (expected {bar|Hello, true!|bar}))
  )
 ("TestCoreBasics-testChainAttr"
  ((classname hello)
   (template_s {|<x>:<names>!|})
   (attributes
    ((names (MV ((STRING Ter) (STRING Tom))))
     (x (SV (STRING "1")))
     )
    )
   (groupfile ())
   (expected {bar|1:TerTom!|bar}))
  )
 ("TestCoreBasics-testInclude"
  ((classname hello)
   (template_s {|load <box()>;|})
   (attributes ())
   (groupfile (("a.stg" {| box() ::= "kewl
daddy" |})))
   (expected {bar|load kewl
daddy;|bar}))
  )
 ("TestCoreBasics-testIncludeWithArg2"
  ((classname hello)
   (template_s {|load <box("arg", foo())>;|})
   (attributes ((name (SV (STRING Ter)))))
   (groupfile (("a.stg" 
                {| box(x,y) ::= "kewl <x> <y> daddy"
foo() ::= "blech" |})))
   (expected {bar|load kewl arg blech daddy;|bar}))
  )
 ("TestCoreBasics-testIncludeWithArg"
  ((classname hello)
   (template_s {|load <box("arg")>;|})
   (attributes ((name (SV (STRING Ter)))))
   (groupfile (("a.stg" {| box(x) ::= "kewl <x> daddy" |})))
   (expected {bar|load kewl arg daddy;|bar}))
  )
 ("TestCoreBasics-testIncludeWithEmptySubtemplateArg"
  ((classname hello)
   (template_s {|load <box({})>;|})
   (attributes ((name (SV (STRING Ter)))))
   (groupfile (("a.stg" {| box(x) ::= "kewl <x> daddy" |})))
   (expected {bar|load kewl  daddy;|bar}))
  )
 ("TestCoreBasics-testIncludeWithNestedArgs"
  ((classname hello)
   (template_s {|load <box(foo("arg"))>;|})
   (attributes ((name (SV (STRING Ter)))))
   (groupfile (("a.stg" 
                {| box(y) ::= "kewl <y> daddy"
foo(x) ::= "blech <x>" |})))
   (expected {bar|load kewl blech arg daddy;|bar}))
  )
 ("TestCoreBasics-testMapAcrossDictionaryUsesKeys"
  ((classname hello)
   (template_s "<foo:{f | <f>}>")
   (attributes ((foo (SV (DICT ((a (STRING b)) (c (STRING d))))))))
   (groupfile ())
   (expected {bar|ac|bar}))
  )
 ("TestCoreBasics-testNullAttrProp"
  ((classname hello)
   (template_s {|<u.id>: <u.name>|})
   (attributes ())
   (groupfile ())
   (expected {bar|: |bar}))
  )
 ("TestCoreBasics-testNullAttr"
  ((classname testNullAttr)
   (template_s {|hi <name>!|})
   (attributes ())
   (groupfile ())
   (expected {bar|hi !|bar}))
  )
 ("TestCoreBasics-testPassThru"
  ((classname hello)
   (template_s {|<a("x","y")>|})
   (attributes ())
   (groupfile (("a.stg" 
                {| 
a(x,y) ::= "<b(...)>"
b(x,y) ::= "<x><y>"
|})))
   (expected {bar|xy|bar}))
  )
 ("TestCoreBasics-testPassThruWithDefaultValue"
  ((classname hello)
   (template_s {|<a(x="x")>|})
   (attributes ())
   (groupfile (("a.stg" 
                {| 
a(x,y) ::= "<b(...)>"
b(x,y={99}) ::= "<x><y>"
|})))
   (expected {bar|x99|bar}))
  )
 ("TestCoreBasics-testProp"
  ((classname hello)
   (template_s {|<u.id>: <u.name>|})
   (attributes ())
   (groupfile (("a.stg" {| u ::= [ "id":"1", "name": "parrt" ] |})))
   (expected {bar|1: parrt|bar}))
  )
 ("TestCoreBasics-testPropWithNoAttr"
  ((classname hello)
   (template_s {|<foo.a>: <ick>|})
   (attributes ())
   (groupfile (("a.stg" {| foo ::= [ "a":"b" ] |})))
   (expected {bar|b: |bar}))
  )
 ("TestCoreBasics-testDefineTemplate"
  ((classname hello)
 (template_s {|<test(name)>|})
 (attributes ((name (MV ((STRING Ter) (STRING Tom) (STRING Sumana))))))
 (groupfile (("a.stg" 
{| 
   inc(x) ::= "<x>+1"
   test(name) ::= "hi <name>!"
 |})))
 (expected {bar|hi TerTomSumana!|bar}))
  )
 ("TestCoreBasics-testMap"
  ((classname hello)
   (template_s {|<test(name)>|})
   (attributes ((name (MV ((STRING Ter) (STRING Tom) (STRING Sumana))))))
   (groupfile (("a.stg" 
                {| 
   inc(x) ::= "[<x>]"
   test(name) ::= "hi <name:inc()>!"
 |})))
   (expected {bar|hi [Ter][Tom][Sumana]!|bar}))
  )
 ("TestCoreBasics-testPassThruNoMissingArgs"
  ((classname hello)
   (template_s {|<a(x="x",y="y")>|})
   (attributes ())
   (groupfile (("a.stg" 
                {| 
   a(x,y) ::= "<b(y={99},x={1},...)>"
   b(x,y) ::= "<x><y>"
 |})))
   (expected {bar|199|bar}))
  )
 ("TestCoreBasics-testPassThruPartialArgs"
  ((classname hello)
   (template_s {|<a(x="x",y="y")>|})
   (attributes ())
   (groupfile (("a.stg" 
                {| 
  a(x,y) ::= "<b(y={99},...)>"
  b(x,y) ::= "<x><y>"
 |})))
   (expected {bar|x99|bar}))
  )
 ("TestCoreBasics-testPassThruWithDefaultValueThatLacksDefinitionAbove"
  ((classname hello)
   (template_s {|<a(x="x")>|})
   (attributes ())
   (groupfile (("a.stg" 
                {| 
  a(x) ::= "<b(...)>"
  b(x,y={99}) ::= "<x><y>"
 |})))
   (expected {bar|x99|bar}))
  )
 )

