(
("testEscapeJavaRightShift2"
((classname hello)
 (template_s "<a(x)>")
 (attributes ((x (SV (STRING parrt)))))
   (groupfile (("test.stg" 
                {| 

a(x) ::= << >\> >>

|})))
 (output " >> ")
)
)
("testEscapeJavaRightShiftAtRightEdge2"
((classname hello)
 (template_s "<a(x)>")
 (attributes ((x (SV (STRING parrt)))))
   (groupfile (("test.stg" 
                {| 

a(x) ::= <<>\>>>

|})))
 (output ">>")
)
)
("testEscapeJavaRightShiftAtRightEdge"
((classname hello)
 (template_s "<a(x)>")
 (attributes ((x (SV (STRING parrt)))))
   (groupfile (("test.stg" 
                {| 

a(x) ::= <<\>>>

|})))
 (output "\\>")
)
)
("testEscapeJavaRightShift"
((classname hello)
 (template_s "<a(x)>")
 (attributes ((x (SV (STRING parrt)))))
   (groupfile (("test.stg" 
                {| 

a(x) ::= << \>> >>

|})))
 (output " >> ")
)
)
("testEscapeOneRightAngle2"
((classname hello)
 (template_s "<a(x)>")
 (attributes ((x (SV (STRING parrt)))))
   (groupfile (("test.stg" 
                {| 

a(x) ::= << \> >>

|})))
 (output " > ")
)
)
("testEscapeOneRightAngle"
((classname hello)
 (template_s "<a(x)>")
 (attributes ((x (SV (STRING parrt)))))
   (groupfile (("test.stg" 
                {| 

a(x) ::= << > >>

|})))
 (output " > ")
)
)
("testGroupWithTwoTemplates"
((classname hello)
 (template_s "<a(x)><b()>")
 (attributes ((x (SV (STRING parrt)))))
   (groupfile (("test.stg" 
                {| 

a(x) ::= <<foo>>
b() ::= "bar"

|})))
 (output "foobar")
)
)
("testSimpleGroupFromString"
((classname hello)
 (template_s "<a(x)>")
 (attributes ((x (SV (STRING parrt)))))
   (groupfile (("test.stg" 
                {| 

a(x) ::= <<foo>>
b() ::= <<bar>>

|})))
 (output "foo")
)
)
("testSimpleGroup"
((classname hello)
 (template_s "<a()>")
 (attributes ())
   (groupfile (("test.stg" 
                {| 

a(x) ::= <<foo>>

|})))
 (output "foo")
 (errors {bar|context [anonymous] 1:1 passed 0 arg(s) to template /a with 1 declared arg(s)
|bar})
)
)
("testSubdir2"
((classname hello)
 (template_s "<subdir/b()>")
 (attributes ())
   (groupfiles (("subdir/b.st" 
                {| 

b() ::= "bar"

|})))
 (output "bar")
)
)
("testSubdir"
((classname hello)
 (template_s "</subdir/b()>")
 (attributes ())
   (groupfiles (("subdir/b.st" 
                {| 

b() ::= "bar"

|})))
 (output "bar")
)
)
("testSubdirWithSubtemplate2"
((classname hello)
 (template_s "<x:/subdir/a()>")
 (attributes ((x (SV (LIST ((STRING "a") (STRING "b")))))))
   (groupfiles (("subdir/a.st" 
                {| 

a(x) ::= "<x:{y|<y>}>"

|})))
 (output "ab")
)
)
("testSubdirWithSubtemplate"
((classname hello)
 (template_s "</subdir/a(x)>")
 (attributes ((x (SV (LIST ((STRING "a") (STRING "b")))))))
   (groupfiles (("subdir/a.st" 
                {| 

a(x) ::= "<x:{y|<y>}>"

|})))
 (output "ab")
)
)

("testAlias"
((classname hello)
 (template_s {foo|<b()>|foo})
 (attributes ())
   (groupfile (("group.stg"
                {| 
a() ::= "bar"
b ::= a
|})))
 (output "bar")
)
)
("testAliasWithArgs"
((classname hello)
 (template_s {foo|<a(x,y)>|foo})
 (attributes ((x (SV (INT 1))) (y (SV (INT 2)))))
   (groupfile (("group.stg"
                {| 
a(x,y) ::= "<x><y>"
b ::= a
|})))
 (output "12")
)
)
("testBooleanDefaultArguments"
((classname hello)
 (template_s {foo|<method(name)>|foo})
 (attributes ((name (SV (STRING foo)))))
   (groupfile (("group.stg"
                {| 
method(name) ::= <<
<stat(name)>
>>
stat(name,x=true,y=false) ::= "<name>; <x> <y>"

|})))
 (output "foo; true false")
)
)
("testCantSeeGroupDirIfGroupFileOfSameName"
((classname hello)
 (template_s {foo|<a()>|foo})
 (attributes ())
   (groupfiles (
     ("./group.stg" {|
"b() ::= "group file b"
|})
("group/a.st"
                {| 
a() ::= <<dir1 a>>
|})
    ))
 (output "")
 (errors {bar|context [anonymous] 1:1 no such template: /a
|bar})
)
)
("testDefaultArgument2"
((classname hello)
 (template_s {foo|<stat(name)>|foo})
 (attributes ((name (SV (STRING foo)))))
   (groupfile (("group.stg"
                {| 
stat(name,value="99") ::= "x=<value>; // <name>"
|})))
 (output "x=99; // foo")
)
)
("testDefaultArgumentAsSimpleTemplate"
((classname hello)
 (template_s {foo|<stat(name)>|foo})
 (attributes ((name (SV (STRING foo)))))
   (groupfile (("group.stg"
                {| 
stat(name,value={99}) ::= "x=<value>; // <name>"
|})))
 (output "x=99; // foo")
)
)
("testDefaultArgumentAsTemplate2"
((classname hello)
 (template_s {foo|<method(name,size)>|foo})
 (attributes ((name (SV (STRING foo))) (size (SV (STRING 2)))))
   (groupfile (("group.stg"
                {| 
method(name,size) ::= <<
<stat(name)>
>>
stat(name,value={ [<name>] }) ::= "x=<value>; // <name>"
|})))
 (output "x=[foo] ; // foo")
)
)
("testDefaultArgumentAsTemplate"
((classname hello)
 (template_s {foo|<method(name,size)>|foo})
 (attributes ((name (SV (STRING foo))) (size (SV (STRING 2)))))
   (groupfile (("group.stg"
                {| 
method(name,size) ::= <<
<stat(name)>
>>
stat(name,value={<name>}) ::= "x=<value>; // <name>"
|})))
 (output "x=foo; // foo")
)
)
("testDefaultArgumentManuallySet"
((classname hello)
 (template_s {foo|<stat(fields)>|foo})
 (attributes ((fields (SV (DICT ((name (STRING parrt)) (n (STRING 0))))))))
   (groupfile (("group.stg"
                {| 
method(fields) ::= <<
<fields:{f | <stat(f)>}>
>>
stat(f,value={<f.name>}) ::= "x=<value>; // <f.name>"
|})))
 (output "x=parrt; // parrt")
)
)
("testDefaultArgumentSeesVarFromDynamicScoping"
((classname hello)
 (template_s {foo|<method(fields)>|foo})
 (attributes ((fields (SV (DICT ((name (STRING parrt)) (n (STRING 0))))))))
   (groupfile (("group.stg"
                {| 
method(f) ::= <<
<stat()>
>>
stat(value={<f.name>}) ::= "x=<value>; // <f.name>"
|})))
 (output "x=parrt; // parrt")
)
)
("testDefaultArgument"
((classname hello)
 (template_s {foo|<method(name)>|foo})
 (attributes ((name (SV (STRING foo)))))
   (groupfile (("group.stg"
                {| 
method(name) ::= <<
<stat(name)>
>>
stat(name,value="99") ::= "x=<value>; // <name>"
|})))
 (output "x=99; // foo")
)
)
("testDoNotUseDefaultArgument"
((classname hello)
 (template_s {foo|<method(name)>|foo})
 (attributes ((name (SV (STRING foo)))))
   (groupfile (("group.stg"
                {| 
method(name) ::= <<
<stat(name,"34")>
>>
stat(name,value="99") ::= "x=<value>; // <name>"
|})))
 (output "x=34; // foo")
)
)
("testDupDef"
((classname hello)
 (template_s {foo||foo})
 (attributes ())
   (groupfile (("group.stg"
                {| 
b() ::= "bar"
b() ::= "duh"
|})))
 (output "")
 (errors {bar|group.stg 3:0: redefinition of template b
|bar})
)
)
("testEarlyEvalOfDefaultArgs"
((classname hello)
 (template_s {foo|<s(x)>|foo})
 (attributes ((x (SV (STRING a)))))
   (groupfile (("group.stg"
                {| 
s(x,y={<(x)>}) ::= "<x><y>"
|})))
 (output "aa")
)
)
("testGroupFileInDir2"
((classname hello)
 (template_s {foo|</group/b()>|foo})
 (attributes ((x (SV (LIST ((STRING a) (STRING b)))))))
     (groupfiles (
     ("./group.stg" {|
b() ::= "bar"
c() ::= "duh"
|})
("a.st" 
                {| 
a(x) ::= <<foo>>
|})
    ))
 (output "bar")
)
)
("testGroupFileInDir3"
((classname hello)
 (template_s {foo|</group/c()>|foo})
 (attributes ((x (SV (LIST ((STRING a) (STRING b)))))))
     (groupfiles (
     ("./group.stg" {|
b() ::= "bar"
c() ::= "duh"
|})
("a.st" 
                {| 
a(x) ::= <<foo>>
|})
    ))
 (output "duh")
)
)
("testGroupFileInDir"
((classname hello)
 (template_s {foo|<"":a()>|foo})
 (attributes ((x (SV (LIST ((STRING a) (STRING b)))))))
     (groupfiles (
     ("./group.st" {|
b() ::= "bar"
c() ::= "duh"
|})
("a.st" 
                {| 
a(x) ::= <<foo>>
|})
    ))
 (output "foo")
)
)
("testGroupFileInSubDir"
((classname hello)
 (template_s {foo|<"":a()><subdir/group/b()><subdir/group/c()>|foo})
 (attributes ())
     (groupfiles (
     ("subdir/group.stg" {|
b() ::= "bar"
c() ::= "duh"
|})
("./a.st" 
                {| 
a(x) ::= <<foo>>
|})
    ))
 (output "foobarduh")
)
)
("testMissingNamedArg"
((classname hello)
 (template_s {foo||foo})
 (attributes ())
 (groupfile (("group.stg"
                {| 
f(x,y) ::= "<x><y>"
g() ::= "<f(x={a},{b})>"
|})))
 (output "")
 (errors {bar|group.stg 3:18: mismatched input '{' expecting ELLIPSIS
|bar})
)
)
("testNamedArgsInOrder"
((classname hello)
 (template_s {foo|<g()>|foo})
 (attributes ())
   (groupfile (("group.stg"
                {| 
f(x,y) ::= "<x><y>"
g() ::= "<f(x={a},y={b})>"
|})))
 (output "ab")
)
)
("testNamedArgsNotAllowInIndirectInclude"
((classname hello)
 (template_s {foo||foo})
 (attributes ())
 (groupfile (("group.stg"
                {| 
f(x,y) ::= "<x><y>"
g(name) ::= "<(name)(x={a},y={b})>"
|})))
 (output "")
 (errors {bar|group.stg 3:22: '=' came as a complete surprise to me
|bar})
)
)
("testNamedArgsOutOfOrder"
((classname hello)
 (template_s {foo|<g()>|foo})
 (attributes ())
 (groupfile (("group.stg"
                {| 
f(x,y) ::= "<x><y>"
g() ::= "<f(y={b},x={a})>"
|})))
 (output "ab")
)
)
("testSimpleDefaultArg"
((classname hello)
 (template_s {foo|<a()>|foo})
 (attributes ())
     (groupfiles (
     ("./b.st" {|
b(x="foo") ::= "<x>"
|})
("./a.st"
                {| 
a() ::= << <b()> >>
|})
    ))
 (output " foo ")
)
)
("testSubdir3"
((classname hello)
 (template_s {foo|<subdir/b()>|foo})
 (attributes ())
     (groupfiles (
     ("subdir/b.st" {|
b() ::= "bar"
|})
("./a.st" 
                {| 
a(x) ::= <<foo>>
|})
    ))
 (output "bar")
)
)
("testSubSubdir"
((classname hello)
 (template_s {foo|<"":a()></sub1/sub2/b()>|foo})
 (attributes ())
     (groupfiles (
     ("sub1/sub2/b.st" {|
b() ::= "bar"
|})
("./a.st" 
                {| 
a(x) ::= <<foo>>
|})
    ))
 (output "foobar")
)
)
("testSubtemplateAsDefaultArgSeesOtherArgs"
((classname hello)
 (template_s {foo|<t(x)>|foo})
 (attributes ((x (SV (STRING a)))))
   (groupfile (("group.stg"
                {| 
t(x,y={<x:{s|<s><z>}>},z="foo") ::= <<
x: <x>
y: <y>
>>
|})))
 (output "x: a\ny: afoo")
)
)
("testTrueFalseArgs"
((classname hello)
 (template_s {foo|<g()>|foo})
 (attributes ())
   (groupfile (("group.stg"
                {| 
f(x,y) ::= "<x><y>"
g() ::= "<f(true,{a})>"
|})))
 (output "truea")
)
)
("testUnknownNamedArg"
((classname hello)
 (template_s {foo|<g()>|foo})
 (attributes ())
 (groupfile (("group.stg"
                {| 
f(x,y) ::= "<x><y>"
g() ::= "<f(x={a},z={b})>"
|})))
 (output "a")
 (errors {bar|context [anonymous /g] 1:1 attribute z isn't defined
|bar})
)
)
)

