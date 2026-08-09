(
("testEvalSTIteratingSubtemplateInSTFromAnotherGroup"
((classname hello)
 (groupfile (("group1.stg" {| 
test(m) ::= "<m:samegroup()>"
samegroup(x) ::= "hi "
errorMessage(x) ::= "<x>"
|})))
 (runs
  (
   ((input "<test(m):errorMessage()>")
    (output "hi hi hi ")
    (attributes ((m (SV (LIST ((INT 1) (INT 2) (INT 3)))))))
    )
   )
  )
 ))
("testEvalSTIteratingSubtemplateInSTFromAnotherGroupSingleValue"
((classname hello)
 (groupfile (("group1.stg" {| 
test(m) ::= "<m:samegroup()>"
samegroup(x) ::= "hi "
errorMessage(x) ::= "<x>"
|})))
 (runs
  (
   ((input "<test(m):errorMessage()>")
    (output "hi ")
    (attributes ((m (SV (INT 10)))))
    )
   )
  )
 ))
("testMapIterationIsByKeys"
((classname hello)
 (groupfile (("t.stg" {|
test(emails) ::= "<emails:{n|<n>}>!"
|})))
 (runs
  (
   ((input "<test(emails)>")
    (output "parrttombudmose!")
    (attributes ((emails (SV (DICT ((parrt (STRING Ter)) (tombu (STRING Tom)) (dmose (STRING Dan))))))))
    )
   )
  )
 ))
("testNestedIterationWithArg"
((classname hello)
 (groupfile (("t.stg" {|
test(users) ::= "<users:{u | <u.id:{id | <id>=}><u.name>}>!"
|})))
 (runs
  (
   ((input "<test(users)>")
    (output "1=parrt2=tombu3=sri!")
    (attributes ((users (MV ((DICT ((id (STRING 1)) (name (STRING parrt))))
    			     (DICT ((id (STRING 2)) (name (STRING tombu))))
    			     (DICT ((id (STRING 3)) (name (STRING sri)))))))))
    )
   )
  )
 ))
("testParallelAttributeIterationHasI"
((classname hello)
 (runs
  (
   ((input "<names,phones,salaries:{n,p,s | <i0>. <n>@<p>: <s>\n}>")
    (output "0. Ter@1: big\n1. Tom@2: huge\n")
    (attributes ((names (MV ((STRING "Ter") (STRING "Tom"))))
    		 (phones (MV ((STRING "1") (STRING "2"))))
    		 (salaries (MV ((STRING "big") (STRING "huge"))))
    		 ))
    )
   )
  )
 ))
("testParallelAttributeIteration"
((classname hello)
 (runs
  (
   ((input "<names,phones,salaries:{n,p,s | <n>@<p>: <s>\n}>")
    (output "Ter@1: big\nTom@2: huge\n")
    (attributes ((names (MV ((STRING "Ter") (STRING "Tom"))))
    		 (phones (MV ((STRING "1") (STRING "2"))))
    		 (salaries (MV ((STRING "big") (STRING "huge"))))
    		 ))
    )
   )
  )
 ))
("testParallelAttributeIterationWithDifferentSizes"
((classname hello)
 (runs
  (
   ((input "<names,phones,salaries:{n,p,s | <n>@<p>: <s>}; separator=\", \">")
    (output "Ter@1: big, Tom@2: , Sriram@: ")
    (attributes ((names (MV ((STRING "Ter") (STRING "Tom") (STRING "Sriram"))))
    		 (phones (MV ((STRING "1") (STRING "2"))))
    		 (salaries (MV ((STRING "big"))))
    		 ))
    )
   )
  )
 ))
("testParallelAttributeIterationWithDifferentSizesTemplateRefInsideToo"
((classname hello)
 (groupfile (("group1.stg" {| 
page(names,phones,salaries) ::= 
   << <names,phones,salaries:{n,p,s | <value(n)>@<value(p)>: <value(s)>}; separator=", "> >>
value(x) ::= "<if(!x)>n/a<else><x><endif>"
|})))
 (runs
  (
   ((input "<page(names,phones,salaries)>")
    (output " Ter@1: big, Tom@2: n/a, Sriram@n/a: n/a ")
    (attributes ((names (MV ((STRING "Ter") (STRING "Tom") (STRING "Sriram"))))
    		 (phones (MV ((STRING "1") (STRING "2"))))
    		 (salaries (MV ((STRING "big"))))
    		 ))
    )
   )
  )
 ))
("testParallelAttributeIterationWithNullValue"
((classname hello)
 (runs
  (
   ((input "<names,phones,salaries:{n,p,s | <n>@<p>: <s>\n}>")
    (output "Ter@1: big\nTom@: huge\nSriram@3: enormous\n")
    (attributes ((names (MV ((STRING "Ter") (STRING "Tom") (STRING "Sriram"))))
    		 (phones (SV (LIST ((STRING "1") NULL (STRING "3")))))
    		 (salaries (MV ((STRING "big") (STRING "huge") (STRING "enormous"))))
    		 ))
    )
   )
  )
 ))
("testParallelAttributeIterationWithSingletons"
((classname hello)
 (runs
  (
   ((input "<names,phones,salaries:{n,p,s | <n>@<p>: <s>}; separator=\", \">")
    (output "Ter@1: big")
    (attributes ((names (MV ((STRING "Ter"))))
    		 (phones (MV ((STRING "1"))))
    		 (salaries (MV ((STRING "big"))))
    		 ))
    )
   )
  )
 ))
("testSimpleIteration"
((classname hello)
 (groupfile (("t.stg" {|
test(names) ::= "<names:{n|<n>}>!"
|})))
 (runs
  (
   ((input "<test(names)>")
    (output "TerTomSumana!")
    (attributes ((names (MV ((STRING Ter) (STRING Tom) (STRING Sumana))))))
    )
   )
  )
 ))
("testSimpleIterationWithArg"
((classname hello)
 (groupfile (("t.stg" {|
test(names) ::= "<names:{n | <n>}>!"
|})))
 (runs
  (
   ((input "<test(names)>")
    (output "TerTomSumana!")
    (attributes ((names (MV ((STRING Ter) (STRING Tom) (STRING Sumana))))))
    )
   )
  )
 ))
("testSubtemplateAsDefaultArg"
((classname hello)
 (groupfile (("t.stg" {|
t(x,y={<x:{s|<s><s>}>}) ::= <<
x: <x>
y: <y>
>>
|})))
 (runs
  (
   ((input "<t(x)>")
    (output "x: a\ny: aa")
    (attributes ((x (SV (STRING a)))))
    )
   )
  )
 ))
)
