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
 ("TestCoreBasics-testIndirectMap"
  ((classname hello)
   (template_s {|<test(t="inc",name=name)>|})
   (attributes ((name (MV ((STRING Ter) (STRING Tom) (STRING Sumana))))))
   (groupfile (("a.stg" 
                {| 
   inc(x) ::= "[<x>]"
   test(t,name) ::= "<name:(t)()>!"
 |})))
   (expected "[Ter][Tom][Sumana]!"))
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
 (expected "hi [Ter]:x5001;[Tom]:x5002;[Sumana]:;"))
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
 (expected "*Ter**Tom**Sumana*"))
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
 (expected "hi Ter:x5001;Tom:x5002;Sumana:x5003;"))
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
 (expected "hi [Ter:x5001;][Tom:x5002;][Sumana:;]"))
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
  (expected "hi Ter:x5001;Tom:x5002;Sumana:;"))
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
 (expected "1:Ter, 2:Tom, 3:Sumana"))
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
 (expected "1:Ter, 2:Tom, 3:Sumana"))
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
 (expected "Ter, Tom, Sumana"))
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
 (expected "hi !"))
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
 (expected "hi [Ter]!"))
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
 (expected "hi ([Ter])([Tom])([Sumana])!"))
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
 (expected "hi ([Ter])x([Sumana])!"))
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
 (expected "hi ([Ter])([Sumana])!"))
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
 (expected "hi [Ter](Tom)[Sumana]!"))
)
("TestCoreBasics-testTrueCond"
((classname hello)
 (template_s "<if(name)>works<endif>")
 (attributes ((name (SV (STRING Ter)))
             ))
 (groupfile ())
 (expected "works"))
)
("TestCoreBasics-testCondParens"
((classname hello)
 (template_s "<if(!(x||y)&&!z)>works<endif>")
 (attributes ())
 (groupfile ())
 (expected "works"))
)
("TestCoreBasics-testElseIf2"
((classname hello)
 (template_s "<if(x)>fail1<elseif(y)>fail2<elseif(z)>works<else>fail3<endif>")
 (attributes ((z (SV (STRING blort)))))
 (groupfile ())
 (expected "works"))
)
("TestCoreBasics-testElseIf3"
((classname hello)
 (template_s "<if(x)><elseif(y)><elseif(z)>works<else><endif>")
 (attributes ((z (SV (STRING blort)))))
 (groupfile ())
 (expected "works"))
)
("TestCoreBasics-testEmptyIFTemplate"
((classname hello)
 (template_s "<if(x)>fail<elseif(name)><endif>")
 (attributes ((name (SV (STRING Ter)))
             ))
 (groupfile ())
 (expected ""))
)
("TestCoreBasics-testFalseCond2"
((classname hello)
 (template_s "<if(name)>works<endif>")
 (attributes ((name (SV NULL))))
 (groupfile ())
 (expected ""))
)
("TestCoreBasics-testFalseCond"
((classname hello)
 (template_s "<if(name)>works<endif>")
 (attributes ())
 (groupfile ())
 (expected ""))
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

 (expected "foo\nbar"))
)
("TestCoreBasics-testNotFalseCond"
((classname hello)
 (template_s "<if(!name)>works<endif>")
 (attributes ())
 (groupfile ())
 (expected "works"))
)
("TestCoreBasics-testNotTrueCond"
((classname hello)
 (template_s "<if(!name)>works<endif>")
 (attributes ((name (SV (STRING Ter)))))
 (groupfile ())
 (expected ""))
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
 (expected "works"))
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
 (expected "works"))
)
("TestCoreBasics-testElseIfAllExprFalse"
((classname hello)
 (template_s "<if(name)>fail<elseif(id)>fail<else>works<endif>")
 (attributes ())
 (groupfile ())
 (expected "works"))
)
("TestCoreBasics-testElseIfNoElseAllFalse"
((classname hello)
 (template_s "<if(name)>fail<elseif(id)>fail<endif>")
 (attributes ())
 (groupfile ())
 (expected ""))
)
("TestCoreBasics-testElseIf"
((classname hello)
 (template_s "<if(name)>fail<elseif(id)>works<else>fail<endif>")
 (attributes ((id (SV (STRING "2DF3DF")))
             ))
 (groupfile ())
 (expected "works"))
)
("TestCoreBasics-testFalseCondWithElse"
((classname hello)
 (template_s "<if(name)>fail<else>works<endif>")
 (attributes ())
 (groupfile ())
 (expected "works"))
)
("TestCoreBasics-testOr"
((classname hello)
 (template_s "<if(name||notThere)>works<else>fail<endif>")
 (attributes ((name (SV (STRING Ter)))))
 (groupfile ())
 (expected "works"))
)
("TestCoreBasics-testTrueCondWithElse"
((classname hello)
 (template_s "<if(name)>works<else>fail<endif>")
 (attributes ((name (SV (STRING Ter)))
             ))
 (groupfile ())
 (expected "works"))
)
("TestCoreBasics-testAndNot"
((classname hello)
 (template_s "<if(name&&!notThere)>works<else>fail<endif>")
 (attributes ((name (SV (STRING Ter)))))
 (groupfile ())
 (expected "works"))
)
("TestCoreBasics-testAnd"
((classname hello)
 (template_s "<if(name&&notThere)>fail<else>works<endif>")
 (attributes ((name (SV (STRING Ter)))))
 (groupfile ())
 (expected "works"))
)
("TestCoreBasics-testCharLiterals2"
((classname hello)
 (template_s "Foo <\\n><\\t> bar\n")
 (attributes ())
 (groupfile ())
 (expected "Foo \n\t bar\n"))
)
("TestCoreBasics-testCharLiterals3"
((classname hello)
 (template_s "Foo<\\ >bar<\\n>")
 (attributes ())
 (groupfile ())
 (expected "Foo bar\n"))
)
("TestCoreBasics-testCharLiterals"
((classname hello)
 (template_s "Foo <\\n><\\n><\\t> bar\n")
 (attributes ())
 (groupfile ())
 (expected "Foo \n\n\t bar\n"))
)
("TestCoreBasics-testMapConditionAndEscapeInside"
((classname hello)
 (template_s "<if(m.name)>works \\\\<endif>")
 (attributes ((m (SV (DICT ((name (STRING Ter))))))))
 (groupfile ())
 (expected "works \\"))
)
("TestCoreBasics-testOr"
((classname hello)
 (template_s "<if(name||notThere)>works<else>fail<endif>")
 (attributes ((name (SV (STRING Ter)))))
 (groupfile ())
 (expected "works"))
)
("TestCoreBasics-testSeparatorInIntList"
((classname hello)
 (template_s "<test(names)>")
 (attributes ((names (SV (LIST ((INT 0) (INT 1)))))))
   (groupfile (("a.stg" 
                {| 
test(names) ::= "<names:{n | case <n>}; separator=\", \">"
|})))
 (expected "case 0, case 1"))
)
("TestCoreBasics-testSeparatorInList2"
((classname hello)
 (template_s "<test(names)>")
 (attributes ((names (MV ((STRING Ter) (LIST ((STRING Tom) (STRING Sriram))))))))
   (groupfile (("a.stg" 
                {| 
test(names) ::= "<names:{n | case <n>}; separator=\", \">"
|})))
 (expected "case Ter, case Tom, case Sriram"))
)
("TestCoreBasics-testSeparatorInList"
((classname hello)
 (template_s "<test(names)>")
 (attributes ((names (SV (LIST ((STRING Ter) (STRING Tom)))))))
   (groupfile (("a.stg" 
                {| 
test(names) ::= "<names:{n | case <n>}; separator=\", \">"
|})))
 (expected "case Ter, case Tom"))
)
("TestCoreBasics-testSeparator"
((classname hello)
 (template_s "<test(names)>")
 (attributes ((names (MV ((STRING Ter) (STRING Tom))))))
   (groupfile (("a.stg" 
                {| 
test(names) ::= "<names:{n | case <n>}; separator=\", \">"
|})))
 (expected "case Ter, case Tom"))
)
("TestCoreBasics-testSubtemplateExpr"
((classname hello)
 (template_s "<{name\n}>")
 (attributes ())
 (groupfile ())
 (expected "name\n"))
)
("TestCoreBasics-testUnicodeLiterals2"
((classname hello)
 (template_s "Foo <\\uFEA5><\\n><\\u00C2> bar\n")
 (attributes ())
 (groupfile ())
 (expected "Foo \u{fea5}\n\u{00C2} bar\n"))
)
("TestCoreBasics-testUnicodeLiterals3"
((classname hello)
 (template_s "Foo<\\ >bar<\\n>")
 (attributes ())
 (groupfile ())
 (expected "Foo bar\n"))
)
("TestCoreBasics-testUnicodeLiterals"
((classname hello)
 (template_s "Foo <\\uFEA5><\\n><\\u00C2> bar\n")
 (attributes ())
 (groupfile ())
 (expected "Foo \u{fea5}\n\u{00C2} bar\n"))
)

 )

