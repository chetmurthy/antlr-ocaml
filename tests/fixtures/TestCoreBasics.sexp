(
 ("hello"
  ((classname hello) (template_s "<{Hello, <name>!}>")
   (attributes ((name (SV (STRING World))))) (groupfile ())
   (output "Hello, World!"))
  )
 ("TestCoreBasics-testNullAttr"
  ((classname testNullAttr)
   (template_s {|hi <name>!|})
   (attributes ())
   (groupfile ())
   (output {bar|hi !|bar})
   (errors "context [anonymous] 1:4 attribute name isn't defined\n")
   )
  )
 ("TestCoreBasics-testAttrIsList"
  ((classname hello)
   (template_s {|hi <name>!|})
   (attributes ((name (MV ((LIST ((STRING Ter) (STRING Tom))) (STRING Sumana))))))
   (groupfile ())
   (output {bar|hi TerTomSumana!|bar})))
 ("TestCoreBasics-testAttr"
  ((classname hello)
   (template_s {|hi <name>!|})
   (attributes ((name (SV (STRING "Ter")))))
   (groupfile ())
   (output {bar|hi Ter!|bar}))
  )
 ("TestCoreBasics-testBoolean1"
  ((classname hello) (template_s "<{Hello, <name>!}>")
   (attributes ((name (SV (BOOL true))))) (groupfile ())
   (output {bar|Hello, true!|bar}))
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
   (output {bar|1:TerTom!|bar}))
  )
 ("TestCoreBasics-testSetUnknownAttr"
  ((classname hello)
   (template_s {|<t()>|})
   (attributes ())
   (groupfile (("a.stg" {|
t() ::= <<hi <name>!>>
 |})))
   (output "hi !")
   (errors "context [anonymous /t] 1:4 attribute name isn't defined\n")
   )
  )
 ("TestCoreBasics-testInclude"
  ((classname hello)
   (template_s {|load <box()>;|})
   (attributes ())
   (groupfile (("a.stg" {| box() ::= "kewl
daddy" |})))
   (output {bar|load kewl
daddy;|bar})
   (errors {bar|a.stg 1:16: \n in string
|bar})
   )
  )
 ("TestCoreBasics-testIncludeWithArg2"
  ((classname hello)
   (template_s {|load <box("arg", foo())>;|})
   (attributes ((name (SV (STRING Ter)))))
   (groupfile (("a.stg" 
                {| box(x,y) ::= "kewl <x> <y> daddy"
foo() ::= "blech" |})))
   (output {bar|load kewl arg blech daddy;|bar}))
  )
 ("TestCoreBasics-testIncludeWithArg"
  ((classname hello)
   (template_s {|load <box("arg")>;|})
   (attributes ((name (SV (STRING Ter)))))
   (groupfile (("a.stg" {| box(x) ::= "kewl <x> daddy" |})))
   (output {bar|load kewl arg daddy;|bar}))
  )
 ("TestCoreBasics-testIncludeWithEmptySubtemplateArg"
  ((classname hello)
   (template_s {|load <box({})>;|})
   (attributes ((name (SV (STRING Ter)))))
   (groupfile (("a.stg" {| box(x) ::= "kewl <x> daddy" |})))
   (output {bar|load kewl  daddy;|bar}))
  )
 ("TestCoreBasics-testIncludeWithNestedArgs"
  ((classname hello)
   (template_s {|load <box(foo("arg"))>;|})
   (attributes ((name (SV (STRING Ter)))))
   (groupfile (("a.stg" 
                {| box(y) ::= "kewl <y> daddy"
foo(x) ::= "blech <x>" |})))
   (output {bar|load kewl blech arg daddy;|bar}))
  )
 ("TestCoreBasics-testMapAcrossDictionaryUsesKeys"
  ((classname hello)
   (template_s "<foo:{f | <f>}>")
   (attributes ((foo (SV (DICT ((a (STRING b)) (c (STRING d))))))))
   (groupfile ())
   (output {bar|ac|bar}))
  )
 ("TestCoreBasics-testNullAttrProp"
  ((classname hello)
   (template_s {|<u.id>: <u.name>|})
   (attributes ())
   (groupfile ())
   (output {bar|: |bar})
   (errors {bar|context [anonymous] 1:1 attribute u isn't defined
context [anonymous] 1:9 attribute u isn't defined
|bar})
   )
  )
 ("TestCoreBasics-testNullAttr"
  ((classname testNullAttr)
   (template_s {|hi <name>!|})
   (attributes ())
   (groupfile ())
   (output {bar|hi !|bar})
   (errors {bar|context [anonymous] 1:4 attribute name isn't defined
|bar})
   )
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
   (output {bar|xy|bar}))
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
   (output {bar|x99|bar})
   (errors {bar|context [anonymous] 1:1 passed 1 arg(s) to template /a with 2 declared arg(s)
|bar})
   )
  )
 ("TestCoreBasics-testProp"
  ((classname hello)
   (template_s {|<u.id>: <u.name>|})
   (attributes ())
   (groupfile (("a.stg" {| u ::= [ "id":"1", "name": "parrt" ] |})))
   (output {bar|1: parrt|bar}))
  )
 ("TestCoreBasics-testPropWithNoAttr"
  ((classname hello)
   (template_s {|<foo.a>: <ick>|})
   (attributes ())
   (groupfile (("a.stg" {| foo ::= [ "a":"b" ] |})))
   (output {bar|b: |bar})
   (errors {bar|context [anonymous] 1:10 attribute ick isn't defined
|bar})
   )
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
 (output {bar|hi TerTomSumana!|bar}))
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
   (output {bar|hi [Ter][Tom][Sumana]!|bar}))
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
   (output {bar|199|bar}))
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
   (output {bar|x99|bar}))
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
   (output {bar|x99|bar}))
  )
 ("TestCoreBasics-testIndirectMap"
  ((classname hello)
   (template_s {|<test(t="inc",name=name)>|})
   (attributes ((name (MV ((STRING Ter) (STRING Tom) (STRING Sumana))))))
   (groupfile (("a.stg" 
                {| 
   inc(x) ::= "[<x>]"
   test(t,name) ::= "<name:(t)()>!"
 |})))
   (output "[Ter][Tom][Sumana]!"))
  )
("TestCoreBasics-testMapThenParallelMap"
 ((classname hello)
  (template_s {|<test(names,phones)>|})
  (attributes ((names (MV ((STRING Ter) (STRING Tom) (STRING Sumana))))
               (phones (MV ((STRING "x5001") (STRING "x5002"))))
               ))
  (groupfile (("a.stg" 
{| 
  bold(x) ::= "[<x>]"
  test(name,phones) ::= "hi <[names:bold()],phones:{n,p | <n>:<p>;}>"

 |})))
 (output "hi [Ter]:x5001;[Tom]:x5002;[Sumana]:;"))
)
("TestCoreBasics-testMapWithExprAsTemplateName"
 ((classname hello)
  (template_s {|<test(name)>|})
  (attributes ((name (MV ((STRING Ter) (STRING Tom) (STRING Sumana))))))
  (groupfile (("a.stg" 
{| 
 d ::= ["foo":"bold"]
 test(name) ::= "<name:(d.foo)()>"
 bold(x) ::= <<*<x>*>>
 |})))
 (output "*Ter**Tom**Sumana*"))
)
("TestCoreBasics-testParallelMap"
 ((classname hello)
  (template_s {|<test(names,phones)>|})
  (attributes ((names (MV ((STRING Ter) (STRING Tom) (STRING Sumana))))
              (phones (MV ((STRING "x5001") (STRING "x5002") (STRING "x5003"))))
             ))
 (groupfile (("a.stg" 
{| 
  test(name,phones) ::= "hi <names,phones:{n,p | <n>:<p>;}>"

  |})))
 (output "hi Ter:x5001;Tom:x5002;Sumana:x5003;"))
)
("TestCoreBasics-testParallelMapThenMap"
 ((classname hello)
  (template_s {|<test(names,phones)>|})
  (attributes ((names (MV ((STRING Ter) (STRING Tom) (STRING Sumana))))
              (phones (MV ((STRING "x5001") (STRING "x5002"))))
             ))
  (groupfile (("a.stg" 
{| 
  bold(x) ::= "[<x>]"
  test(name,phones) ::= "hi <names,phones:{n,p | <n>:<p>;}:bold()>"

 |})))
 (output "hi [Ter:x5001;][Tom:x5002;][Sumana:;]"))
)
("TestCoreBasics-testParallelMapWith3Versus2Elements"
 ((classname hello)
  (template_s {|<test(names,phones)>|})
  (attributes ((names (MV ((STRING Ter) (STRING Tom) (STRING Sumana))))
              (phones (MV ((STRING "x5001") (STRING "x5002"))))
             ))
  (groupfile (("a.stg" 
{| 
  test(name,phones) ::= "hi <names,phones:{n,p | <n>:<p>;}>"

 |})))
  (output "hi Ter:x5001;Tom:x5002;Sumana:;"))
)
("TestCoreBasics-testMapIndexes2"
((classname hello)
 (template_s {|<test(name)>|})
 (attributes ((name (MV ((STRING Ter) (STRING Tom) NULL (STRING Sumana))))
             ))
 (groupfile (("a.stg" 
{| 
   test(name) ::= "<name:{n | <i>:<n>}; separator=\", \">"
 |})))
 (output "1:Ter, 2:Tom, 3:Sumana"))
)
("TestCoreBasics-testMapIndexes"
((classname hello)
 (template_s {|<test(name)>|})
 (attributes ((name (MV ((STRING Ter) (STRING Tom) NULL (STRING Sumana))))
             ))
 (groupfile (("a.stg" 
{| 
   inc(x,i) ::= "<i>:<x>"
   test(name) ::= "<name:{n|<inc(n,i)>}; separator=\", \">"
 |})))
 (output "1:Ter, 2:Tom, 3:Sumana"))
)
("TestCoreBasics-testMapNullValueInList"
((classname hello)
 (template_s {|<test(name)>|})
 (attributes ((name (MV ((STRING Ter) (STRING Tom) NULL (STRING Sumana))))
             ))
 (groupfile (("a.stg" 
{| 
   test(name) ::= "<name; separator=\", \">"
 |})))
 (output "Ter, Tom, Sumana"))
)
("TestCoreBasics-testMapNullValue"
((classname hello)
 (template_s {|<test()>|})
 (attributes ())
 (groupfile (("a.stg" 
{| 
   a(x) ::= "[<x>]"
   test(name) ::= "hi <name:a()>!"
 |})))
 (output "hi !")
 (errors {bar|context [anonymous] 1:1 passed 0 arg(s) to template /test with 1 declared arg(s)
|bar})
 )
)
("TestCoreBasics-testMapSingleValue"
((classname hello)
 (template_s {|<test(name)>|})
 (attributes ((name (SV (STRING Ter)))
             ))
 (groupfile (("a.stg" 
{| 
   a(x) ::= "[<x>]"
   test(name) ::= "hi <name:a()>!"
 |})))
 (output "hi [Ter]!"))
)
("TestCoreBasics-testRepeatedMap"
((classname hello)
 (template_s {|<test(name)>|})
 (attributes ((name (MV ((STRING Ter) (STRING Tom) (STRING Sumana))))
             ))
 (groupfile (("a.stg" 
{| 
   a(x) ::= "[<x>]"
   b(x) ::= "(<x>)"
   test(name) ::= "hi <name:a():b()>!"
 |})))
 (output "hi ([Ter])([Tom])([Sumana])!"))
)
("TestCoreBasics-testRepeatedMapWithNullValueAndNullOption"
((classname hello)
 (template_s {|<test(name)>|})
 (attributes ((name (MV ((STRING Ter) NULL (STRING Sumana))))
             ))
 (groupfile (("a.stg" 
{| 
   a(x) ::= "[<x>]"
   b(x) ::= "(<x>)"
   test(name) ::= "hi <name:a():b(); null={x}>!"
 |})))
 (output "hi ([Ter])x([Sumana])!"))
)
("TestCoreBasics-testRepeatedMapWithNullValue"
((classname hello)
 (template_s {|<test(name)>|})
 (attributes ((name (MV ((STRING Ter) NULL (STRING Sumana))))
             ))
 (groupfile (("a.stg" 
{| 
   a(x) ::= "[<x>]"
   b(x) ::= "(<x>)"
   test(name) ::= "hi <name:a():b()>!"
 |})))
 (output "hi ([Ter])([Sumana])!"))
)
("TestCoreBasics-testRoundRobinMap"
((classname hello)
 (template_s {|<test(name)>|})
 (attributes ((name (MV ((STRING Ter) (STRING Tom) (STRING Sumana))))
             ))
 (groupfile (("a.stg" 
{| 
   a(x) ::= "[<x>]"
   b(x) ::= "(<x>)"
   test(name) ::= "hi <name:a(),b()>!"
 |})))
 (output "hi [Ter](Tom)[Sumana]!"))
)
("TestCoreBasics-testTrueCond"
((classname hello)
 (template_s "<if(name)>works<endif>")
 (attributes ((name (SV (STRING Ter)))
             ))
 (groupfile ())
 (output "works"))
)
("TestCoreBasics-testCondParens"
((classname hello)
 (template_s "<if(!(x||y)&&!z)>works<endif>")
 (attributes ())
 (groupfile ())
 (output "works")
 (errors {bar|context [anonymous] 1:6 attribute x isn't defined
context [anonymous] 1:9 attribute y isn't defined
context [anonymous] 1:14 attribute z isn't defined
|bar})
 )
)
("TestCoreBasics-testElseIf2"
((classname hello)
 (template_s "<if(x)>fail1<elseif(y)>fail2<elseif(z)>works<else>fail3<endif>")
 (attributes ((z (SV (STRING blort)))))
 (groupfile ())
 (output "works")
 (errors {bar|context [anonymous] 1:4 attribute x isn't defined
context [anonymous] 1:20 attribute y isn't defined
|bar})
 )
)
("TestCoreBasics-testElseIf3"
((classname hello)
 (template_s "<if(x)><elseif(y)><elseif(z)>works<else><endif>")
 (attributes ((z (SV (STRING blort)))))
 (groupfile ())
 (output "works")
 (errors {bar|context [anonymous] 1:4 attribute x isn't defined
context [anonymous] 1:15 attribute y isn't defined
|bar})
 )
)
("TestCoreBasics-testEmptyIFTemplate"
((classname hello)
 (template_s "<if(x)>fail<elseif(name)><endif>")
 (attributes ((name (SV (STRING Ter)))
             ))
 (groupfile ())
 (output "")
 (errors {bar|context [anonymous] 1:4 attribute x isn't defined
|bar})
 )
)
("TestCoreBasics-testFalseCond2"
((classname hello)
 (template_s "<if(name)>works<endif>")
 (attributes ((name (SV NULL))))
 (groupfile ())
 (output ""))
)
("TestCoreBasics-testFalseCond"
((classname hello)
 (template_s "<if(name)>works<endif>")
 (attributes ())
 (groupfile ())
 (output "")
 (errors {bar|context [anonymous] 1:4 attribute name isn't defined
|bar})
 )
)
("TestCoreBasics-testFalseCondWithFormalArgs"
((classname hello)
 (template_s "<a()>")
 (attributes ((name (SV NULL))))
 (groupfile (("group.stg" 
{| 
   a(scope) ::= <<
foo
    <if(scope)>oops<endif>
bar
>>
 |})))

 (output "foo\nbar")
 (errors {bar|context [anonymous] 1:1 passed 0 arg(s) to template /a with 1 declared arg(s)
|bar})
 )
)
("TestCoreBasics-testNotFalseCond"
((classname hello)
 (template_s "<if(!name)>works<endif>")
 (attributes ())
 (groupfile ())
 (output "works")
 (errors {bar|context [anonymous] 1:5 attribute name isn't defined
|bar})
 )
)
("TestCoreBasics-testNotTrueCond"
((classname hello)
 (template_s "<if(!name)>works<endif>")
 (attributes ((name (SV (STRING Ter)))))
 (groupfile ())
 (output ""))
)
("TestCoreBasics-testParensInConditonal2"
((classname hello)
 (template_s "<if((!a||b)&&!(c||d))>broken<else>works<endif>")
 (attributes ((a (SV (BOOL true)))
              (b (SV (BOOL true)))
              (c (SV (BOOL true)))
              (d (SV (BOOL true)))
             ))
 (groupfile ())
 (output "works"))
)
("TestCoreBasics-testParensInConditonal"
((classname hello)
 (template_s "<if((a||b)&&(c||d))>works<endif>")
 (attributes ((a (SV (BOOL true)))
              (b (SV (BOOL true)))
              (c (SV (BOOL true)))
              (d (SV (BOOL true)))
             ))
 (groupfile ())
 (output "works"))
)
("TestCoreBasics-testElseIfAllExprFalse"
((classname hello)
 (template_s "<if(name)>fail<elseif(id)>fail<else>works<endif>")
 (attributes ())
 (groupfile ())
 (output "works")
 (errors {bar|context [anonymous] 1:4 attribute name isn't defined
context [anonymous] 1:22 attribute id isn't defined
|bar})
 )
)
("TestCoreBasics-testElseIfNoElseAllFalse"
((classname hello)
 (template_s "<if(name)>fail<elseif(id)>fail<endif>")
 (attributes ())
 (groupfile ())
 (output "")
 (errors {bar|context [anonymous] 1:4 attribute name isn't defined
context [anonymous] 1:22 attribute id isn't defined
|bar})
 )
)
("TestCoreBasics-testElseIf"
((classname hello)
 (template_s "<if(name)>fail<elseif(id)>works<else>fail<endif>")
 (attributes ((id (SV (STRING "2DF3DF")))
             ))
 (groupfile ())
 (output "works")
 (errors {bar|context [anonymous] 1:4 attribute name isn't defined
|bar})
 )
)
("TestCoreBasics-testFalseCondWithElse"
((classname hello)
 (template_s "<if(name)>fail<else>works<endif>")
 (attributes ())
 (groupfile ())
 (output "works")
 (errors {bar|context [anonymous] 1:4 attribute name isn't defined
|bar})
 )
)
("TestCoreBasics-testOr"
((classname hello)
 (template_s "<if(name||notThere)>works<else>fail<endif>")
 (attributes ((name (SV (STRING Ter)))))
 (groupfile ())
 (output "works")
 (errors {bar|context [anonymous] 1:10 attribute notThere isn't defined
|bar})
 )
)
("TestCoreBasics-testTrueCondWithElse"
((classname hello)
 (template_s "<if(name)>works<else>fail<endif>")
 (attributes ((name (SV (STRING Ter)))
             ))
 (groupfile ())
 (output "works"))
)
("TestCoreBasics-testAndNot"
((classname hello)
 (template_s "<if(name&&!notThere)>works<else>fail<endif>")
 (attributes ((name (SV (STRING Ter)))))
 (groupfile ())
 (output "works")
 (errors {bar|context [anonymous] 1:11 attribute notThere isn't defined
|bar})
 )
)
("TestCoreBasics-testAnd"
((classname hello)
 (template_s "<if(name&&notThere)>fail<else>works<endif>")
 (attributes ((name (SV (STRING Ter)))))
 (groupfile ())
 (output "works")
 (errors {bar|context [anonymous] 1:10 attribute notThere isn't defined
|bar})
 )
)
("TestCoreBasics-testCharLiterals2"
((classname hello)
 (template_s "Foo <\\n><\\t> bar\n")
 (attributes ())
 (groupfile ())
 (output "Foo \n\t bar\n"))
)
("TestCoreBasics-testCharLiterals3"
((classname hello)
 (template_s "Foo<\\ >bar<\\n>")
 (attributes ())
 (groupfile ())
 (output "Foo bar\n"))
)
("TestCoreBasics-testCharLiterals"
((classname hello)
 (template_s "Foo <\\n><\\n><\\t> bar\n")
 (attributes ())
 (groupfile ())
 (output "Foo \n\n\t bar\n"))
)
("TestCoreBasics-testMapConditionAndEscapeInside"
((classname hello)
 (template_s "<if(m.name)>works \\\\<endif>")
 (attributes ((m (SV (DICT ((name (STRING Ter))))))))
 (groupfile ())
 (output "works \\"))
)
("TestCoreBasics-testOr"
((classname hello)
 (template_s "<if(name||notThere)>works<else>fail<endif>")
 (attributes ((name (SV (STRING Ter)))))
 (groupfile ())
 (output "works")
 (errors {bar|context [anonymous] 1:10 attribute notThere isn't defined
|bar})
 )
)
("TestCoreBasics-testSeparatorInIntList"
((classname hello)
 (template_s "<test(names)>")
 (attributes ((names (SV (LIST ((INT 0) (INT 1)))))))
   (groupfile (("a.stg" 
                {| 
test(names) ::= "<names:{n | case <n>}; separator=\", \">"
|})))
 (output "case 0, case 1"))
)
("TestCoreBasics-testSeparatorInList2"
((classname hello)
 (template_s "<test(names)>")
 (attributes ((names (MV ((STRING Ter) (LIST ((STRING Tom) (STRING Sriram))))))))
   (groupfile (("a.stg" 
                {| 
test(names) ::= "<names:{n | case <n>}; separator=\", \">"
|})))
 (output "case Ter, case Tom, case Sriram"))
)
("TestCoreBasics-testSeparatorInList"
((classname hello)
 (template_s "<test(names)>")
 (attributes ((names (SV (LIST ((STRING Ter) (STRING Tom)))))))
   (groupfile (("a.stg" 
                {| 
test(names) ::= "<names:{n | case <n>}; separator=\", \">"
|})))
 (output "case Ter, case Tom"))
)
("TestCoreBasics-testSeparator"
((classname hello)
 (template_s "<test(names)>")
 (attributes ((names (MV ((STRING Ter) (STRING Tom))))))
   (groupfile (("a.stg" 
                {| 
test(names) ::= "<names:{n | case <n>}; separator=\", \">"
|})))
 (output "case Ter, case Tom"))
)
("TestCoreBasics-testSubtemplateExpr"
((classname hello)
 (template_s "<{name\n}>")
 (attributes ())
 (groupfile ())
 (output "name\n"))
)
("TestCoreBasics-testUnicodeLiterals2"
((classname hello)
 (template_s "Foo <\\uFEA5><\\n><\\u00C2> bar\n")
 (attributes ())
 (groupfile ())
 (output "Foo \u{fea5}\n\u{00C2} bar\n"))
)
("TestCoreBasics-testUnicodeLiterals3"
((classname hello)
 (template_s "Foo<\\ >bar<\\n>")
 (attributes ())
 (groupfile ())
 (output "Foo bar\n"))
)
("TestCoreBasics-testUnicodeLiterals"
((classname hello)
 (template_s "Foo <\\uFEA5><\\n><\\u00C2> bar\n")
 (attributes ())
 (groupfile ())
 (output "Foo \u{fea5}\n\u{00C2} bar\n"))
)
("TestCoreBasics-testEarlyEvalIndent"
((classname hello)
 (template_s "<main()>")
 (attributes ())
   (groupfile (("t.stg" 
                {| 
t() ::= <<  abc>>
main() ::= <<
<t()>
<(t())>
  <t()>
  <(t())>
>>

|})))
 (output "  abc\n  abc\n    abc\n    abc"))
)
("TestCoreBasics-testEarlyEvalNoIndent"
((classname hello)
 (template_s "<main()>")
 (attributes ())
   (groupfile (("t.stg" 
                {| 
t() ::= <<  abc>>
main() ::= <<
<t()>
<(t())>
  <t()>
  <(t())>
>>

|})))
 (output "abc\nabc\nabc\nabc")
 (indent false)
)
)
("TestCoreBasics-testSeparatorInIntList2"
((classname hello)
 (template_s "<test(names)>")
 (attributes ((names (MV ((INT 0) (LIST ((INT 1) (INT 2))))))))
   (groupfile (("a.stg" 
                {| 
test(names) ::= "<names:{n | case <n>}; separator=\", \">"
|})))
 (output "case 0, case 1, case 2"))
)

 )

