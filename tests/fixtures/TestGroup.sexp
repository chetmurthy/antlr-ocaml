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
   (groupfile (("subdir/b.st" 
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
   (groupfile (("subdir/b.st" 
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
   (groupfile (("subdir/a.st" 
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
   (groupfile (("subdir/a.st" 
                {| 

a(x) ::= "<x:{y|<y>}>"

|})))
 (output "ab")
)
)
)
