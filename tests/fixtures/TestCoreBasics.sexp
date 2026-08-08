((hello
  ((classname hello)
   (runs
    (((input "<{Hello, <name>!}>")
      (output "Hello, World!")
      (attributes ((name (SV (STRING World)))))
      ))
    )
   )
  )
 (testNullAttr
  ((classname testNullAttr)
   (runs (((input "hi <name>!") (output "hi !"))))
   (errors {|context [anonymous] 1:4 attribute name isn't defined
|})
   )
  )
 (testAttrIsList
  ((classname hello)
   (runs
    (((input "hi <name>!")
      (output "hi TerTomSumana!")
      (attributes
       ((name (MV ((LIST ((STRING Ter) (STRING Tom))) (STRING Sumana)))))
       )
      ))
    )
   )
  )
 (testAttr
  ((classname hello)
   (runs
    (((input "hi <name>!")
      (output "hi Ter!")
      (attributes ((name (SV (STRING Ter)))))
      ))
    )
   )
  )
 (testBoolean1
  ((classname hello)
   (runs
    (((input "<{Hello, <name>!}>")
      (output "Hello, true!")
      (attributes ((name (SV (BOOL true)))))
      ))
    )
   )
  )
 (testChainAttr
  ((classname hello)
   (runs
    (((input "<x>:<names>!")
      (output "1:TerTom!")
      (attributes
       ((names (MV ((STRING Ter) (STRING Tom)))) (x (SV (STRING 1))))
       )
      ))
    )
   )
  )
 (testSetUnknownAttr
  ((classname hello)
   (groupfile (("a.stg" {|
t() ::= <<hi <name>!>>
 |})))
   (runs (((input "<t()>") (output "hi !"))))
   (errors {|context [anonymous /t] 1:4 attribute name isn't defined
|})
   )
  )
 (testInclude
  ((classname hello)
   (groupfile (("a.stg" {| box() ::= "kewl
daddy" |})))
   (runs (((input "load <box()>;") (output {|load kewl
daddy;|}))))
   (errors {|a.stg 1:16: \n in string
|})
   )
  )
 (testIncludeWithArg2
  ((classname hello)
   (groupfile
    (("a.stg" {| box(x,y) ::= "kewl <x> <y> daddy"
foo() ::= "blech" |}))
    )
   (runs
    (((input "load <box(\"arg\", foo())>;")
      (output "load kewl arg blech daddy;")
      (attributes ((name (SV (STRING Ter)))))
      ))
    )
   )
  )
 (testIncludeWithArg
  ((classname hello)
   (groupfile (("a.stg" " box(x) ::= \"kewl <x> daddy\" ")))
   (runs
    (((input "load <box(\"arg\")>;")
      (output "load kewl arg daddy;")
      (attributes ((name (SV (STRING Ter)))))
      ))
    )
   )
  )
 (testIncludeWithEmptySubtemplateArg
  ((classname hello)
   (groupfile (("a.stg" " box(x) ::= \"kewl <x> daddy\" ")))
   (runs
    (((input "load <box({})>;")
      (output "load kewl  daddy;")
      (attributes ((name (SV (STRING Ter)))))
      ))
    )
   )
  )
 (testIncludeWithNestedArgs
  ((classname hello)
   (groupfile
    (("a.stg" {| box(y) ::= "kewl <y> daddy"
foo(x) ::= "blech <x>" |}))
    )
   (runs
    (((input "load <box(foo(\"arg\"))>;")
      (output "load kewl blech arg daddy;")
      (attributes ((name (SV (STRING Ter)))))
      ))
    )
   )
  )
 (testMapAcrossDictionaryUsesKeys
  ((classname hello)
   (runs
    (((input "<foo:{f | <f>}>")
      (output ac)
      (attributes ((foo (SV (DICT ((a (STRING b)) (c (STRING d))))))))
      ))
    )
   )
  )
 (testNullAttrProp
  ((classname hello)
   (runs (((input "<u.id>: <u.name>") (output ": "))))
   (errors
    {|context [anonymous] 1:1 attribute u isn't defined
context [anonymous] 1:9 attribute u isn't defined
|}
    )
   )
  )
 (testNullAttr
  ((classname testNullAttr)
   (runs (((input "hi <name>!") (output "hi !"))))
   (errors {|context [anonymous] 1:4 attribute name isn't defined
|})
   )
  )
 (testPassThru
  ((classname hello)
   (groupfile (("a.stg" {| 
a(x,y) ::= "<b(...)>"
b(x,y) ::= "<x><y>"
|})))
   (runs (((input "<a(\"x\",\"y\")>") (output xy))))
   )
  )
 (testPassThruWithDefaultValue
  ((classname hello)
   (groupfile
    (("a.stg" {| 
a(x,y) ::= "<b(...)>"
b(x,y={99}) ::= "<x><y>"
|}))
    )
   (runs (((input "<a(x=\"x\")>") (output x99))))
   (errors
    {|context [anonymous] 1:1 passed 1 arg(s) to template /a with 2 declared arg(s)
|}
    )
   )
  )
 (testProp
  ((classname hello)
   (groupfile (("a.stg" " u ::= [ \"id\":\"1\", \"name\": \"parrt\" ] ")))
   (runs (((input "<u.id>: <u.name>") (output "1: parrt"))))
   )
  )
 (testPropWithNoAttr
  ((classname hello)
   (groupfile (("a.stg" " foo ::= [ \"a\":\"b\" ] ")))
   (runs (((input "<foo.a>: <ick>") (output "b: "))))
   (errors {|context [anonymous] 1:10 attribute ick isn't defined
|})
   )
  )
 (testDefineTemplate
  ((classname hello)
   (groupfile
    (("a.stg" {| 
   inc(x) ::= "<x>+1"
   test(name) ::= "hi <name>!"
 |}))
    )
   (runs
    (((input "<test(name)>")
      (output "hi TerTomSumana!")
      (attributes ((name (MV ((STRING Ter) (STRING Tom) (STRING Sumana))))))
      ))
    )
   )
  )
 (testMap
  ((classname hello)
   (groupfile
    (("a.stg"
      {| 
   inc(x) ::= "[<x>]"
   test(name) ::= "hi <name:inc()>!"
 |}
      ))
    )
   (runs
    (((input "<test(name)>")
      (output "hi [Ter][Tom][Sumana]!")
      (attributes ((name (MV ((STRING Ter) (STRING Tom) (STRING Sumana))))))
      ))
    )
   )
  )
 (testPassThruNoMissingArgs
  ((classname hello)
   (groupfile
    (("a.stg"
      {| 
   a(x,y) ::= "<b(y={99},x={1},...)>"
   b(x,y) ::= "<x><y>"
 |}
      ))
    )
   (runs (((input "<a(x=\"x\",y=\"y\")>") (output 199))))
   )
  )
 (testPassThruPartialArgs
  ((classname hello)
   (groupfile
    (("a.stg" {| 
  a(x,y) ::= "<b(y={99},...)>"
  b(x,y) ::= "<x><y>"
 |}))
    )
   (runs (((input "<a(x=\"x\",y=\"y\")>") (output x99))))
   )
  )
 (testPassThruWithDefaultValueThatLacksDefinitionAbove
  ((classname hello)
   (groupfile
    (("a.stg" {| 
  a(x) ::= "<b(...)>"
  b(x,y={99}) ::= "<x><y>"
 |}))
    )
   (runs (((input "<a(x=\"x\")>") (output x99))))
   )
  )
 (testIndirectMap
  ((classname hello)
   (groupfile
    (("a.stg"
      {| 
   inc(x) ::= "[<x>]"
   test(t,name) ::= "<name:(t)()>!"
 |}
      ))
    )
   (runs
    (((input "<test(t=\"inc\",name=name)>")
      (output "[Ter][Tom][Sumana]!")
      (attributes ((name (MV ((STRING Ter) (STRING Tom) (STRING Sumana))))))
      ))
    )
   )
  )
 (testMapThenParallelMap
  ((classname hello)
   (groupfile
    (("a.stg"
      {| 
  bold(x) ::= "[<x>]"
  test(name,phones) ::= "hi <[names:bold()],phones:{n,p | <n>:<p>;}>"

 |}
      ))
    )
   (runs
    (((input "<test(names,phones)>")
      (output "hi [Ter]:x5001;[Tom]:x5002;[Sumana]:;")
      (attributes
       ((names (MV ((STRING Ter) (STRING Tom) (STRING Sumana))))
        (phones (MV ((STRING x5001) (STRING x5002))))
        )
       )
      ))
    )
   )
  )
 (testMapWithExprAsTemplateName
  ((classname hello)
   (groupfile
    (("a.stg"
      {| 
 d ::= ["foo":"bold"]
 test(name) ::= "<name:(d.foo)()>"
 bold(x) ::= <<*<x>*>>
 |}
      ))
    )
   (runs
    (((input "<test(name)>")
      (output "*Ter**Tom**Sumana*")
      (attributes ((name (MV ((STRING Ter) (STRING Tom) (STRING Sumana))))))
      ))
    )
   )
  )
 (testParallelMap
  ((classname hello)
   (groupfile
    (("a.stg"
      {| 
  test(name,phones) ::= "hi <names,phones:{n,p | <n>:<p>;}>"

  |}
      ))
    )
   (runs
    (((input "<test(names,phones)>")
      (output "hi Ter:x5001;Tom:x5002;Sumana:x5003;")
      (attributes
       ((names (MV ((STRING Ter) (STRING Tom) (STRING Sumana))))
        (phones (MV ((STRING x5001) (STRING x5002) (STRING x5003))))
        )
       )
      ))
    )
   )
  )
 (testParallelMapThenMap
  ((classname hello)
   (groupfile
    (("a.stg"
      {| 
  bold(x) ::= "[<x>]"
  test(name,phones) ::= "hi <names,phones:{n,p | <n>:<p>;}:bold()>"

 |}
      ))
    )
   (runs
    (((input "<test(names,phones)>")
      (output "hi [Ter:x5001;][Tom:x5002;][Sumana:;]")
      (attributes
       ((names (MV ((STRING Ter) (STRING Tom) (STRING Sumana))))
        (phones (MV ((STRING x5001) (STRING x5002))))
        )
       )
      ))
    )
   )
  )
 (testParallelMapWith3Versus2Elements
  ((classname hello)
   (groupfile
    (("a.stg"
      {| 
  test(name,phones) ::= "hi <names,phones:{n,p | <n>:<p>;}>"

 |}
      ))
    )
   (runs
    (((input "<test(names,phones)>")
      (output "hi Ter:x5001;Tom:x5002;Sumana:;")
      (attributes
       ((names (MV ((STRING Ter) (STRING Tom) (STRING Sumana))))
        (phones (MV ((STRING x5001) (STRING x5002))))
        )
       )
      ))
    )
   )
  )
 (testMapIndexes2
  ((classname hello)
   (groupfile
    (("a.stg"
      {| 
   test(name) ::= "<name:{n | <i>:<n>}; separator=\", \">"
 |}
      ))
    )
   (runs
    (((input "<test(name)>")
      (output "1:Ter, 2:Tom, 3:Sumana")
      (attributes
       ((name (MV ((STRING Ter) (STRING Tom) NULL (STRING Sumana)))))
       )
      ))
    )
   )
  )
 (testMapIndexes
  ((classname hello)
   (groupfile
    (("a.stg"
      {| 
   inc(x,i) ::= "<i>:<x>"
   test(name) ::= "<name:{n|<inc(n,i)>}; separator=\", \">"
 |}
      ))
    )
   (runs
    (((input "<test(name)>")
      (output "1:Ter, 2:Tom, 3:Sumana")
      (attributes
       ((name (MV ((STRING Ter) (STRING Tom) NULL (STRING Sumana)))))
       )
      ))
    )
   )
  )
 (testMapNullValueInList
  ((classname hello)
   (groupfile
    (("a.stg" {| 
   test(name) ::= "<name; separator=\", \">"
 |}))
    )
   (runs
    (((input "<test(name)>")
      (output "Ter, Tom, Sumana")
      (attributes
       ((name (MV ((STRING Ter) (STRING Tom) NULL (STRING Sumana)))))
       )
      ))
    )
   )
  )
 (testMapNullValue
  ((classname hello)
   (groupfile
    (("a.stg" {| 
   a(x) ::= "[<x>]"
   test(name) ::= "hi <name:a()>!"
 |}))
    )
   (runs (((input "<test()>") (output "hi !"))))
   (errors
    {|context [anonymous] 1:1 passed 0 arg(s) to template /test with 1 declared arg(s)
|}
    )
   )
  )
 (testMapSingleValue
  ((classname hello)
   (groupfile
    (("a.stg" {| 
   a(x) ::= "[<x>]"
   test(name) ::= "hi <name:a()>!"
 |}))
    )
   (runs
    (((input "<test(name)>")
      (output "hi [Ter]!")
      (attributes ((name (SV (STRING Ter)))))
      ))
    )
   )
  )
 (testRepeatedMap
  ((classname hello)
   (groupfile
    (("a.stg"
      {| 
   a(x) ::= "[<x>]"
   b(x) ::= "(<x>)"
   test(name) ::= "hi <name:a():b()>!"
 |}
      ))
    )
   (runs
    (((input "<test(name)>")
      (output "hi ([Ter])([Tom])([Sumana])!")
      (attributes ((name (MV ((STRING Ter) (STRING Tom) (STRING Sumana))))))
      ))
    )
   )
  )
 (testRepeatedMapWithNullValueAndNullOption
  ((classname hello)
   (groupfile
    (("a.stg"
      {| 
   a(x) ::= "[<x>]"
   b(x) ::= "(<x>)"
   test(name) ::= "hi <name:a():b(); null={x}>!"
 |}
      ))
    )
   (runs
    (((input "<test(name)>")
      (output "hi ([Ter])x([Sumana])!")
      (attributes ((name (MV ((STRING Ter) NULL (STRING Sumana))))))
      ))
    )
   )
  )
 (testRepeatedMapWithNullValue
  ((classname hello)
   (groupfile
    (("a.stg"
      {| 
   a(x) ::= "[<x>]"
   b(x) ::= "(<x>)"
   test(name) ::= "hi <name:a():b()>!"
 |}
      ))
    )
   (runs
    (((input "<test(name)>")
      (output "hi ([Ter])([Sumana])!")
      (attributes ((name (MV ((STRING Ter) NULL (STRING Sumana))))))
      ))
    )
   )
  )
 (testRoundRobinMap
  ((classname hello)
   (groupfile
    (("a.stg"
      {| 
   a(x) ::= "[<x>]"
   b(x) ::= "(<x>)"
   test(name) ::= "hi <name:a(),b()>!"
 |}
      ))
    )
   (runs
    (((input "<test(name)>")
      (output "hi [Ter](Tom)[Sumana]!")
      (attributes ((name (MV ((STRING Ter) (STRING Tom) (STRING Sumana))))))
      ))
    )
   )
  )
 (testTrueCond
  ((classname hello)
   (runs
    (((input "<if(name)>works<endif>")
      (output works)
      (attributes ((name (SV (STRING Ter)))))
      ))
    )
   )
  )
 (testCondParens
  ((classname hello)
   (runs (((input "<if(!(x||y)&&!z)>works<endif>") (output works))))
   (errors
    {|context [anonymous] 1:6 attribute x isn't defined
context [anonymous] 1:9 attribute y isn't defined
context [anonymous] 1:14 attribute z isn't defined
|}
    )
   )
  )
 (testElseIf2
  ((classname hello)
   (runs
    (((input
       "<if(x)>fail1<elseif(y)>fail2<elseif(z)>works<else>fail3<endif>"
       )
      (output works)
      (attributes ((z (SV (STRING blort)))))
      ))
    )
   (errors
    {|context [anonymous] 1:4 attribute x isn't defined
context [anonymous] 1:20 attribute y isn't defined
|}
    )
   )
  )
 (testElseIf3
  ((classname hello)
   (runs
    (((input "<if(x)><elseif(y)><elseif(z)>works<else><endif>")
      (output works)
      (attributes ((z (SV (STRING blort)))))
      ))
    )
   (errors
    {|context [anonymous] 1:4 attribute x isn't defined
context [anonymous] 1:15 attribute y isn't defined
|}
    )
   )
  )
 (testEmptyIFTemplate
  ((classname hello)
   (runs
    (((input "<if(x)>fail<elseif(name)><endif>")
      (attributes ((name (SV (STRING Ter)))))
      ))
    )
   (errors {|context [anonymous] 1:4 attribute x isn't defined
|})
   )
  )
 (testFalseCond2
  ((classname hello)
   (runs
    (((input "<if(name)>works<endif>") (attributes ((name (SV NULL))))))
    )
   )
  )
 (testFalseCond
  ((classname hello)
   (runs (((input "<if(name)>works<endif>"))))
   (errors {|context [anonymous] 1:4 attribute name isn't defined
|})
   )
  )
 (testFalseCondWithFormalArgs
  ((classname hello)
   (groupfile
    (("group.stg"
      {| 
   a(scope) ::= <<
foo
    <if(scope)>oops<endif>
bar
>>
 |}
      ))
    )
   (runs
    (((input "<a()>") (output "foo\nbar") (attributes ((name (SV NULL))))))
    )
   (errors
    {|context [anonymous] 1:1 passed 0 arg(s) to template /a with 1 declared arg(s)
|}
    )
   )
  )
 (testNotFalseCond
  ((classname hello)
   (runs (((input "<if(!name)>works<endif>") (output works))))
   (errors {|context [anonymous] 1:5 attribute name isn't defined
|})
   )
  )
 (testNotTrueCond
  ((classname hello)
   (runs
    (((input "<if(!name)>works<endif>")
      (attributes ((name (SV (STRING Ter)))))
      ))
    )
   )
  )
 (testParensInConditonal2
  ((classname hello)
   (runs
    (((input "<if((!a||b)&&!(c||d))>broken<else>works<endif>")
      (output works)
      (attributes
       ((a (SV (BOOL true)))
        (b (SV (BOOL true)))
        (c (SV (BOOL true)))
        (d (SV (BOOL true)))
        )
       )
      ))
    )
   )
  )
 (testParensInConditonal
  ((classname hello)
   (runs
    (((input "<if((a||b)&&(c||d))>works<endif>")
      (output works)
      (attributes
       ((a (SV (BOOL true)))
        (b (SV (BOOL true)))
        (c (SV (BOOL true)))
        (d (SV (BOOL true)))
        )
       )
      ))
    )
   )
  )
 (testElseIfAllExprFalse
  ((classname hello)
   (runs
    (((input "<if(name)>fail<elseif(id)>fail<else>works<endif>")
      (output works)
      ))
    )
   (errors
    {|context [anonymous] 1:4 attribute name isn't defined
context [anonymous] 1:22 attribute id isn't defined
|}
    )
   )
  )
 (testElseIfNoElseAllFalse
  ((classname hello)
   (runs (((input "<if(name)>fail<elseif(id)>fail<endif>"))))
   (errors
    {|context [anonymous] 1:4 attribute name isn't defined
context [anonymous] 1:22 attribute id isn't defined
|}
    )
   )
  )
 (testElseIf
  ((classname hello)
   (runs
    (((input "<if(name)>fail<elseif(id)>works<else>fail<endif>")
      (output works)
      (attributes ((id (SV (STRING "2DF3DF")))))
      ))
    )
   (errors {|context [anonymous] 1:4 attribute name isn't defined
|})
   )
  )
 (testFalseCondWithElse
  ((classname hello)
   (runs (((input "<if(name)>fail<else>works<endif>") (output works))))
   (errors {|context [anonymous] 1:4 attribute name isn't defined
|})
   )
  )
 (testOr
  ((classname hello)
   (runs
    (((input "<if(name||notThere)>works<else>fail<endif>")
      (output works)
      (attributes ((name (SV (STRING Ter)))))
      ))
    )
   (errors {|context [anonymous] 1:10 attribute notThere isn't defined
|})
   )
  )
 (testTrueCondWithElse
  ((classname hello)
   (runs
    (((input "<if(name)>works<else>fail<endif>")
      (output works)
      (attributes ((name (SV (STRING Ter)))))
      ))
    )
   )
  )
 (testAndNot
  ((classname hello)
   (runs
    (((input "<if(name&&!notThere)>works<else>fail<endif>")
      (output works)
      (attributes ((name (SV (STRING Ter)))))
      ))
    )
   (errors {|context [anonymous] 1:11 attribute notThere isn't defined
|})
   )
  )
 (testAnd
  ((classname hello)
   (runs
    (((input "<if(name&&notThere)>fail<else>works<endif>")
      (output works)
      (attributes ((name (SV (STRING Ter)))))
      ))
    )
   (errors {|context [anonymous] 1:10 attribute notThere isn't defined
|})
   )
  )
 (testCharLiterals2
  ((classname hello)
   (runs (((input {|Foo <\n><\t> bar
|}) (output {|Foo 
	 bar
|}))))
   )
  )
 (testCharLiterals3
  ((classname hello)
   (runs (((input "Foo<\\ >bar<\\n>") (output "Foo bar\n"))))
   )
  )
 (testCharLiterals
  ((classname hello)
   (runs (((input {|Foo <\n><\n><\t> bar
|}) (output {|Foo 

	 bar
|}))))
   )
  )
 (testMapConditionAndEscapeInside
  ((classname hello)
   (runs
    (((input "<if(m.name)>works \\\\<endif>")
      (output "works \\")
      (attributes ((m (SV (DICT ((name (STRING Ter))))))))
      ))
    )
   )
  )
 (testOr
  ((classname hello)
   (runs
    (((input "<if(name||notThere)>works<else>fail<endif>")
      (output works)
      (attributes ((name (SV (STRING Ter)))))
      ))
    )
   (errors {|context [anonymous] 1:10 attribute notThere isn't defined
|})
   )
  )
 (testSeparatorInIntList
  ((classname hello)
   (groupfile
    (("a.stg"
      {| 
test(names) ::= "<names:{n | case <n>}; separator=\", \">"
|}
      ))
    )
   (runs
    (((input "<test(names)>")
      (output "case 0, case 1")
      (attributes ((names (SV (LIST ((INT 0) (INT 1)))))))
      ))
    )
   )
  )
 (testSeparatorInList2
  ((classname hello)
   (groupfile
    (("a.stg"
      {| 
test(names) ::= "<names:{n | case <n>}; separator=\", \">"
|}
      ))
    )
   (runs
    (((input "<test(names)>")
      (output "case Ter, case Tom, case Sriram")
      (attributes
       ((names (MV ((STRING Ter) (LIST ((STRING Tom) (STRING Sriram)))))))
       )
      ))
    )
   )
  )
 (testSeparatorInList
  ((classname hello)
   (groupfile
    (("a.stg"
      {| 
test(names) ::= "<names:{n | case <n>}; separator=\", \">"
|}
      ))
    )
   (runs
    (((input "<test(names)>")
      (output "case Ter, case Tom")
      (attributes ((names (SV (LIST ((STRING Ter) (STRING Tom)))))))
      ))
    )
   )
  )
 (testSeparator
  ((classname hello)
   (groupfile
    (("a.stg"
      {| 
test(names) ::= "<names:{n | case <n>}; separator=\", \">"
|}
      ))
    )
   (runs
    (((input "<test(names)>")
      (output "case Ter, case Tom")
      (attributes ((names (MV ((STRING Ter) (STRING Tom))))))
      ))
    )
   )
  )
 (testSubtemplateExpr
  ((classname hello) (runs (((input "<{name\n}>") (output "name\n")))))
  )
 (testUnicodeLiterals2
  ((classname hello)
   (runs
    (((input {|Foo <\uFEA5><\n><\u00C2> bar
|}) (output {|Foo ﺥ
Â bar
|})))
    )
   )
  )
 (testUnicodeLiterals3
  ((classname hello)
   (runs (((input "Foo<\\ >bar<\\n>") (output "Foo bar\n"))))
   )
  )
 (testUnicodeLiterals
  ((classname hello)
   (runs
    (((input {|Foo <\uFEA5><\n><\u00C2> bar
|}) (output {|Foo ﺥ
Â bar
|})))
    )
   )
  )
 (testEarlyEvalIndent
  ((classname hello)
   (groupfile
    (("t.stg"
      {| 
t() ::= <<  abc>>
main() ::= <<
<t()>
<(t())>
  <t()>
  <(t())>
>>

|}
      ))
    )
   (runs (((input "<main()>") (output {|  abc
  abc
    abc
    abc|}))))
   )
  )
 (testEarlyEvalNoIndent
  ((classname hello)
   (groupfile
    (("t.stg"
      {| 
t() ::= <<  abc>>
main() ::= <<
<t()>
<(t())>
  <t()>
  <(t())>
>>

|}
      ))
    )
   (indent false)
   (runs (((input "<main()>") (output {|abc
abc
abc
abc|}))))
   )
  )
 (testSeparatorInIntList2
  ((classname hello)
   (groupfile
    (("a.stg"
      {| 
test(names) ::= "<names:{n | case <n>}; separator=\", \">"
|}
      ))
    )
   (runs
    (((input "<test(names)>")
      (output "case 0, case 1, case 2")
      (attributes ((names (MV ((INT 0) (LIST ((INT 1) (INT 2))))))))
      ))
    )
   )
  )
 )