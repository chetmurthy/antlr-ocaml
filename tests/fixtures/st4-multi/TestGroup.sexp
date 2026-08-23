((testEscapeJavaRightShift2
  ((classname hello)
   (groupfile (("test.stg" {| 

a(x) ::= << >\> >>

|})))
   (runs
    (((input "<a(x)>")
      (output " >> ")
      (attributes ((x (SV (STRING parrt)))))
      ))
    )
   )
  )
 (testEscapeJavaRightShiftAtRightEdge2
  ((classname hello)
   (groupfile (("test.stg" {| 

a(x) ::= <<>\>>>

|})))
   (runs
    (((input "<a(x)>") (output ">>") (attributes ((x (SV (STRING parrt)))))))
    )
   )
  )
 (testEscapeJavaRightShiftAtRightEdge
  ((classname hello)
   (groupfile (("test.stg" {| 

a(x) ::= <<\>>>

|})))
   (runs
    (((input "<a(x)>") (output "\\>") (attributes ((x (SV (STRING parrt)))))))
    )
   )
  )
 (testEscapeJavaRightShift
  ((classname hello)
   (groupfile (("test.stg" {| 

a(x) ::= << \>> >>

|})))
   (runs
    (((input "<a(x)>")
      (output " >> ")
      (attributes ((x (SV (STRING parrt)))))
      ))
    )
   )
  )
 (testEscapeOneRightAngle2
  ((classname hello)
   (groupfile (("test.stg" {| 

a(x) ::= << \> >>

|})))
   (runs
    (((input "<a(x)>") (output " > ") (attributes ((x (SV (STRING parrt)))))))
    )
   )
  )
 (testEscapeOneRightAngle
  ((classname hello)
   (groupfile (("test.stg" {| 

a(x) ::= << > >>

|})))
   (runs
    (((input "<a(x)>") (output " > ") (attributes ((x (SV (STRING parrt)))))))
    )
   )
  )
 (testGroupWithTwoTemplates
  ((classname hello)
   (groupfile (("test.stg" {| 

a(x) ::= <<foo>>
b() ::= "bar"

|})))
   (runs
    (((input "<a(x)><b()>")
      (output foobar)
      (attributes ((x (SV (STRING parrt)))))
      ))
    )
   )
  )
 (testSimpleGroupFromString
  ((classname hello)
   (groupfile (("test.stg" {| 

a(x) ::= <<foo>>
b() ::= <<bar>>

|})))
   (runs
    (((input "<a(x)>") (output foo) (attributes ((x (SV (STRING parrt)))))))
    )
   )
  )
 (testSimpleGroup
  ((classname hello)
   (groupfile (("test.stg" {| 

a(x) ::= <<foo>>

|})))
   (runs (((input "<a()>") (output foo))))
   (errors
    {|context [anonymous] 1:1 passed 0 arg(s) to template /a with 1 declared arg(s)
|}
    )
   )
  )
 (testSubdir2
  ((classname hello)
   (groupfiles (("subdir/b.st" {| 

b() ::= "bar"

|})))
   (runs (((input "<subdir/b()>") (output bar))))
   )
  )
 (testSubdir
  ((classname hello)
   (groupfiles (("subdir/b.st" {| 

b() ::= "bar"

|})))
   (runs (((input "</subdir/b()>") (output bar))))
   )
  )
 (testSubdirWithSubtemplate2
  ((classname hello)
   (groupfiles (("subdir/a.st" {| 

a(x) ::= "<x:{y|<y>}>"

|})))
   (runs
    (((input "<x:/subdir/a()>")
      (output ab)
      (attributes ((x (SV (LIST ((STRING a) (STRING b)))))))
      ))
    )
   )
  )
 (testSubdirWithSubtemplate
  ((classname hello)
   (groupfiles (("subdir/a.st" {| 

a(x) ::= "<x:{y|<y>}>"

|})))
   (runs
    (((input "</subdir/a(x)>")
      (output ab)
      (attributes ((x (SV (LIST ((STRING a) (STRING b)))))))
      ))
    )
   )
  )
 (testAlias
  ((classname hello)
   (groupfile (("group.stg" {| 
a() ::= "bar"
b ::= a
|})))
   (runs (((input "<b()>") (output bar))))
   )
  )
 (testAliasWithArgs
  ((classname hello)
   (groupfile (("group.stg" {| 
a(x,y) ::= "<x><y>"
b ::= a
|})))
   (runs
    (((input "<a(x,y)>")
      (output 12)
      (attributes ((x (SV (INT 1))) (y (SV (INT 2)))))
      ))
    )
   )
  )
 (testBooleanDefaultArguments
  ((classname hello)
   (groupfile
    (("group.stg"
      {| 
method(name) ::= <<
<stat(name)>
>>
stat(name,x=true,y=false) ::= "<name>; <x> <y>"

|}
      ))
    )
   (runs
    (((input "<method(name)>")
      (output "foo; true false")
      (attributes ((name (SV (STRING foo)))))
      ))
    )
   )
  )
 (testCantSeeGroupDirIfGroupFileOfSameName
  ((classname hello)
   (groupfiles
    (("group.stg" {|
b() ::= "group file b"
|})
     ("group/a.st" {| 
a() ::= <<dir1 a>>
|})
     )
    )
   (runs (((input "<a()>"))))
   (errors {|context [anonymous] 1:1 no such template: /a
|})
   )
  )
 (testDefaultArgument2
  ((classname hello)
   (groupfile
    (("group.stg" {| 
stat(name,value="99") ::= "x=<value>; // <name>"
|}))
    )
   (runs
    (((input "<stat(name)>")
      (output "x=99; // foo")
      (attributes ((name (SV (STRING foo)))))
      ))
    )
   )
  )
 (testDefaultArgumentAsSimpleTemplate
  ((classname hello)
   (groupfile
    (("group.stg" {| 
stat(name,value={99}) ::= "x=<value>; // <name>"
|}))
    )
   (runs
    (((input "<stat(name)>")
      (output "x=99; // foo")
      (attributes ((name (SV (STRING foo)))))
      ))
    )
   )
  )
 (testDefaultArgumentAsTemplate2
  ((classname hello)
   (groupfile
    (("group.stg"
      {| 
method(name,size) ::= <<
<stat(name)>
>>
stat(name,value={ [<name>] }) ::= "x=<value>; // <name>"
|}
      ))
    )
   (runs
    (((input "<method(name,size)>")
      (output "x=[foo] ; // foo")
      (attributes ((name (SV (STRING foo))) (size (SV (STRING 2)))))
      ))
    )
   )
  )
 (testDefaultArgumentAsTemplate
  ((classname hello)
   (groupfile
    (("group.stg"
      {| 
method(name,size) ::= <<
<stat(name)>
>>
stat(name,value={<name>}) ::= "x=<value>; // <name>"
|}
      ))
    )
   (runs
    (((input "<method(name,size)>")
      (output "x=foo; // foo")
      (attributes ((name (SV (STRING foo))) (size (SV (STRING 2)))))
      ))
    )
   )
  )
 (testDefaultArgumentManuallySet
  ((classname hello)
   (groupfile
    (("group.stg"
      {| 
method(fields) ::= <<
<fields:{f | <stat(f)>}>
>>
stat(f,value={<f.name>}) ::= "x=<value>; // <f.name>"
|}
      ))
    )
   (runs
    (((input "<stat(fields)>")
      (output "x=parrt; // parrt")
      (attributes
       ((fields (SV (DICT ((name (STRING parrt)) (n (STRING 0)))))))
       )
      ))
    )
   )
  )
 (testDefaultArgumentSeesVarFromDynamicScoping
  ((classname hello)
   (groupfile
    (("group.stg"
      {| 
method(f) ::= <<
<stat()>
>>
stat(value={<f.name>}) ::= "x=<value>; // <f.name>"
|}
      ))
    )
   (runs
    (((input "<method(fields)>")
      (output "x=parrt; // parrt")
      (attributes
       ((fields (SV (DICT ((name (STRING parrt)) (n (STRING 0)))))))
       )
      ))
    )
   )
  )
 (testDefaultArgument
  ((classname hello)
   (groupfile
    (("group.stg"
      {| 
method(name) ::= <<
<stat(name)>
>>
stat(name,value="99") ::= "x=<value>; // <name>"
|}
      ))
    )
   (runs
    (((input "<method(name)>")
      (output "x=99; // foo")
      (attributes ((name (SV (STRING foo)))))
      ))
    )
   )
  )
 (testDoNotUseDefaultArgument
  ((classname hello)
   (groupfile
    (("group.stg"
      {| 
method(name) ::= <<
<stat(name,"34")>
>>
stat(name,value="99") ::= "x=<value>; // <name>"
|}
      ))
    )
   (runs
    (((input "<method(name)>")
      (output "x=34; // foo")
      (attributes ((name (SV (STRING foo)))))
      ))
    )
   )
  )
 (testDupDef
  ((classname hello)
   (groupfile (("group.stg" {| 
b() ::= "bar"
b() ::= "duh"
|})))
   (runs (((input ""))))
   (errors {|group.stg 3:0: redefinition of template b
|})
   )
  )
 (testEarlyEvalOfDefaultArgs
  ((classname hello)
   (groupfile (("group.stg" {| 
s(x,y={<(x)>}) ::= "<x><y>"
|})))
   (runs (((input "<s(x)>") (output aa) (attributes ((x (SV (STRING a))))))))
   )
  )
 (testGroupFileInDir2
  ((classname hello)
   (groupfiles
    (("group.stg" {|
b() ::= "bar"
c() ::= "duh"
|})
     ("a.st" {| 
a(x) ::= <<foo>>
|})
     )
    )
   (runs
    (((input "</group/b()>")
      (output bar)
      (attributes ((x (SV (LIST ((STRING a) (STRING b)))))))
      ))
    )
   )
  )
 (testGroupFileInDir3
  ((classname hello)
   (groupfiles
    (("group.stg" {|
b() ::= "bar"
c() ::= "duh"
|})
     ("a.st" {| 
a(x) ::= <<foo>>
|})
     )
    )
   (runs
    (((input "</group/c()>")
      (output duh)
      (attributes ((x (SV (LIST ((STRING a) (STRING b)))))))
      ))
    )
   )
  )
 (testGroupFileInDir
  ((classname hello)
   (groupfiles
    (("group.stg" {|
b() ::= "bar"
c() ::= "duh"
|})
     ("a.st" {| 
a(x) ::= <<foo>>
|})
     )
    )
   (runs
    (((input "<\"\":a()>")
      (output foo)
      (attributes ((x (SV (LIST ((STRING a) (STRING b)))))))
      ))
    )
   )
  )
 (testGroupFileInSubDir
  ((classname hello)
   (groupfiles
    (("subdir/group.stg" {|
b() ::= "bar"
c() ::= "duh"
|})
     ("a.st" {|
a(x) ::= <<foo>>
|})
     )
    )
   (runs
    (((input "<\"\":a()><subdir/group/b()><subdir/group/c()>")
      (output foobarduh)
      ))
    )
   )
  )
 (testMissingNamedArg
  ((classname hello)
   (groupfile
    (("group.stg" {| 
f(x,y) ::= "<x><y>"
g() ::= "<f(x={a},{b})>"
|}))
    )
   (runs (((input ""))))
   (errors {|group.stg 3:18: mismatched input '{' expecting ELLIPSIS
|})
   )
  )
 (testNamedArgsInOrder
  ((classname hello)
   (groupfile
    (("group.stg" {| 
f(x,y) ::= "<x><y>"
g() ::= "<f(x={a},y={b})>"
|}))
    )
   (runs (((input "<g()>") (output ab))))
   )
  )
 (testNamedArgsNotAllowInIndirectInclude
  ((classname hello)
   (groupfile
    (("group.stg"
      {| 
f(x,y) ::= "<x><y>"
g(name) ::= "<(name)(x={a},y={b})>"
|}
      ))
    )
   (runs (((input ""))))
   (errors {|group.stg 3:22: '=' came as a complete surprise to me
|})
   )
  )
 (testNamedArgsOutOfOrder
  ((classname hello)
   (groupfile
    (("group.stg" {| 
f(x,y) ::= "<x><y>"
g() ::= "<f(y={b},x={a})>"
|}))
    )
   (runs (((input "<g()>") (output ab))))
   )
  )
 (testSimpleDefaultArg
  ((classname hello)
   (groupfiles
    (("b.st" {|
b(x="foo") ::= "<x>"
|})
     ("a.st" {|
a() ::= << <b()> >>
|})
     )
    )
   (runs (((input "<a()>") (output " foo "))))
   )
  )
 (testSubdir3
  ((classname hello)
   (groupfiles
    (("subdir/b.st" {|
b() ::= "bar"
|}) ("a.st" {|
a(x) ::= <<foo>>
|}))
    )
   (runs (((input "<subdir/b()>") (output bar))))
   )
  )
 (testSubSubdir
  ((classname hello)
   (groupfiles
    (("sub1/sub2/b.st" {|
b() ::= "bar"
|})
     ("a.st" {|
a(x) ::= <<foo>>
|})
     )
    )
   (runs (((input "<\"\":a()></sub1/sub2/b()>") (output foobar))))
   )
  )
 (testSubtemplateAsDefaultArgSeesOtherArgs
  ((classname hello)
   (groupfile
    (("group.stg"
      {| 
t(x,y={<x:{s|<s><z>}>},z="foo") ::= <<
x: <x>
y: <y>
>>
|}
      ))
    )
   (runs
    (((input "<t(x)>")
      (output {|x: a
y: afoo|})
      (attributes ((x (SV (STRING a)))))
      ))
    )
   )
  )
 (testTrueFalseArgs
  ((classname hello)
   (groupfile
    (("group.stg" {| 
f(x,y) ::= "<x><y>"
g() ::= "<f(true,{a})>"
|}))
    )
   (runs (((input "<g()>") (output truea))))
   )
  )
 (testUnknownNamedArg
  ((classname hello)
   (groupfile
    (("group.stg" {| 
f(x,y) ::= "<x><y>"
g() ::= "<f(x={a},z={b})>"
|}))
    )
   (runs (((input "<g()>") (output a))))
   (errors {|context [anonymous /g] 1:1 attribute z isn't defined
|})
   )
  )
 (testGroupFileImport2
  ((classname hello)
   (groupfile
    (("group1.stg" {|
import "group2.stg"
a(x) ::= <<
foo<b()>
>>
|}))
    )
   (groupfiles (("group2.stg" {|
b() ::= "bar"
|})))
   (runs (((input "<\"\":a()>") (output foobar))))
   )
  )
 (testGroupFileImport
  ((classname hello)
   (groupfile
    (("group1.stg" {|
import "group2.stg"
a(x) ::= <<
foo<b()>
>>
|}))
    )
   (groupfiles (("group2.stg" {|
b() ::= "bar"
|})))
   (runs (((input "<b()>") (output bar))))
   )
  )
 (testLineBreakInGroup2
  ((classname hello)
   (groupfile (("t.stg" {| 
t() ::= <<
Foo <\\>       
  	  bar
>>

|})))
   (runs (((input "<t()>") (output "Foo bar"))))
   )
  )
 (testLineBreakInGroup
  ((classname hello)
   (groupfile (("t.stg" {| 
t() ::= <<
Foo <\\>
  	  bar
>>

|})))
   (runs (((input "<t()>") (output "Foo bar"))))
   )
  )
 (testLineBreakMissingTrailingNewline
  ((classname hello)
   (groupfile (("t.stg" {|a(x) ::= <<<\\>
>>|})))
   (runs (((input "<a(x)>") (attributes ((x (SV (STRING parrt))))))))
   (errors {|t.stg 1:15: Missing newline after newline escape <\\>
|})
   )
  )
 (testLineBreakWithScarfedTrailingNewline
  ((classname hello)
   (groupfile (("t.stg" {|a(x) ::= <<<\\>
>>|})))
   (runs (((input "<a(x)>") (attributes ((x (SV (STRING parrt))))))))
   (errors {|t.stg 1:15: Missing newline after newline escape <\\>
|})
   )
  )
 )