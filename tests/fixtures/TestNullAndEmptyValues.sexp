(
("testEmptyListGetsNoOutput"
((classname hello)
 (groupfile (("t.stg" {| 
test(users) ::=
            "begin
<users:{u | name: <u>}; separator=\", \">
end
"
|})))
 (runs
  (
   ((input "<test(users)>")
    (output "begin\nend")
    (attributes ((users (SV (LIST ())))))
    )
   )
  )
 (errors {bar|t.stg 3:18: \n in string
t.stg 4:41: \n in string
t.stg 5:3: \n in string
|bar})
 ))
("testMissingDictionaryValue2"
((classname hello)
 (groupfile (("t.stg" {| 
test(m) ::= "<if(m.foo)>[<m.foo>]<endif>"
|})))
 (runs
  (
   ((input "<test(m)>")
    (output "")
    (attributes ((m (SV (DICT ())))))
    )
   )
  )
 ))
("testMissingDictionaryValue3"
((classname hello)
 (groupfile (("t.stg" {| 
test(m) ::= "<if(m.foo)>[<m.foo>]<endif>"
|})))
 (runs
  (
   ((input "<test(m)>")
    (output "")
    (attributes ((m (SV (DICT ((foo NULL)))))))
    )
   )
  )
 ))
("testMissingDictionaryValue"
((classname hello)
 (groupfile (("t.stg" {| 
test(m) ::= "<m.foo>"
|})))
 (runs
  (
   ((input "<test(m)>")
    (output "")
    (attributes ((m (SV (DICT ())))))
    )
   )
  )
 ))
("testNullListGetsNoOutput"
((classname hello)
 (groupfile (("t.stg" {| 
test(users) ::=
            "begin
<users:{u | name: <u>}; separator=\", \">
end
"
|})))
 (runs
  (
   ((input "<test(users)>")
    (output "begin\nend")
    )
   )
  )
 (errors {bar|t.stg 3:18: \n in string
t.stg 4:41: \n in string
t.stg 5:3: \n in string
context [anonymous] 1:6 attribute users isn't defined
|bar})
 ))
("testNullListItemNotCountedForIteratorIndex"
((classname hello)
 (groupfile (("t.stg" {| 
test(name) ::= "<name:{n | <i>:<n>}>"
|})))
 (runs
  (
   ((input "<test(name)>")
    (output "1:Ter2:Jesse")
    (attributes
     ((name (MV ((STRING Ter) NULL NULL (STRING Jesse)))))
     )
    )
   )
  )
 ))
("TestSeparatorEmittedForEmptyIteratorValu3333e"
((classname hello)
   (groupfile
    (("a.stg"
      {| 
filter ::= ["b":, default: key]
t() ::= <%<["a", "b", "c", "b"]:{it | <filter.(it)>}; separator=",">%>
|}
      ))
    )
 (runs
  (
   ((input "<t()>")
    (output "a,,c,")
    )
   )
  )
 (errors {bar|a.stg 2:16: missing value for key at ','
|bar})
 ))
("TestSeparatorEmittedForEmptyIteratorValue2"
((classname hello)
 (runs
  (
   ((input "<values; separator=\" \">")
    (output "x  y")
    (attributes ((values (SV (LIST ((STRING "x") (STRING "") (STRING "y")))))))
    )
   )
  )
 ))
("TestSeparatorEmittedForEmptyIteratorValue"
((classname hello)
 (runs
  (
   ((input "<values:{v|<if(v)>x<endif>}; separator=\" \">")
    (output "x  x")
    (attributes ((values (SV (LIST ((BOOL true) (BOOL false) (BOOL true)))))))
    )
   )
  )
 ))
("testSeparatorWithNull2ndValue"
((classname hello)
 (groupfile (("t.stg" {| 
test(name) ::= "hi <name; separator=\", \">!"
|})))
 (runs
  (
   ((input "<test(name)>")
    (output "hi Ter, Sumana!")
    (attributes
     ((name (MV ((STRING Ter) NULL (STRING Sumana)))))
     )
    )
   )
  )
 ))
("testSeparatorWithNullFirstValue"
((classname hello)
 (groupfile (("t.stg" {| 
test(name) ::= "hi <name; separator=\", \">!"
|})))
 (runs
  (
   ((input "<test(name)>")
    (output "hi Tom, Sumana!")
    (attributes
     ((name (MV (NULL (STRING Tom) (STRING Sumana)))))
     )
    )
   )
  )
 ))
("testSeparatorWithNullLastValue"
((classname hello)
 (groupfile (("t.stg" {| 
test(name) ::= "hi <name; separator=\", \">!"
|})))
 (runs
  (
   ((input "<test(name)>")
    (output "hi Ter, Tom!")
    (attributes
     ((name (MV ((STRING Ter) (STRING Tom) NULL))))
     )
    )
   )
  )
 ))
("testSeparatorWithTwoNullValuesInRow"
((classname hello)
 (groupfile (("t.stg" {| 
test(name) ::= "hi <name; separator=\", \">!"
|})))
 (runs
  (
   ((input "<test(name)>")
    (output "hi Ter, Tom, Sri!")
    (attributes
     ((name (MV ((STRING Ter) (STRING Tom) NULL NULL (STRING Sri)))))
     )
    )
   )
  )
 ))
("testSizeZeroButNonNullListGetsNoOutput"
((classname hello)
 (groupfile (("t.stg" {| 
test(users) ::= "begin
<users>
end
"
|})))
 (runs
  (
   ((input "<test(users)>")
    (output "begin\nend")
    (attributes
     ((users (SV NULL)))
     )
    )
   )
  )
 (errors {bar|t.stg 2:22: \n in string
t.stg 3:7: \n in string
t.stg 4:3: \n in string
|bar})
 ))
("testTemplateAppliedToMissingValueIsEmpty"
((classname hello)
 (groupfile (("t.stg" {| 
test(name) ::= "<name:t()>"
t(x) ::= "<x>"
|})))
 (runs
  (
   ((input "<test(name)>")
    (output "")
    )
   )
  )
 (errors {bar|context [anonymous] 1:6 attribute name isn't defined
|bar})
 ))
("testTemplateAppliedToNullIsEmpty"
((classname hello)
 (groupfile (("t.stg" {| 
test(name) ::= "<name:t()>"
t(x) ::= "<x>"
|})))
 (runs
  (
   ((input "<test(name)>")
    (output "")
    (attributes
     ((name (SV NULL)))
     )
    )
   )
  )
 ))
("testTwoNullValues"
((classname hello)
 (groupfile (("t.stg" {| 
test(name) ::= "hi <name; null=\"x\">!"
|})))
 (runs
  (
   ((input "<test(name)>")
    (output "hi xx!")
    (attributes
     ((name (MV ( NULL NULL))))
     )
    )
   )
  )
 ))
)
