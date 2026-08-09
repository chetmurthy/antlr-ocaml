(
("testAttrSeparator"
((classname hello)
 (groupfile (("t.stg" {|
test(name,sep) ::= "hi <name; separator=sep>!"
|})))
 (runs
  (
   ((input "<test(name,sep)>")
    (output "hi Ter, Tom, Sumana!")
    (attributes ((name (MV ((STRING Ter) (STRING Tom) (STRING Sumana))))
    		 (sep (SV (STRING ", ")))))
    )
   )
  )
 ))
("testDoubleListApplyWithNullValueAndNullOption"
((classname hello)
 (groupfile (("t.stg" {|
test(name) ::= "<name:{n | <n>}:{n | [<n>]}; null=\"n/a\">"
|})))
 (runs
  (
   ((input "<test(name)>")
    (output "[Ter]n/a[Sumana]")
    (attributes ((name (MV ((STRING Ter) NULL (STRING Sumana))))))
    )
   )
  )
 ))
("testIllegalOption"
((classname hello)
 (groupfile (("t.stg" {|
test(name) ::= "<name; bad=\"ugly\">"
|})))
 (runs
  (
   ((input "<test(name)>")
    (output "Ter")
    (attributes ((name (SV (STRING Ter)))))
    )
   )
  )
 (errors {bar|t.stg 2:23: no such option: bad
|bar})
 ))
("testIncludeSeparator"
((classname hello)
 (groupfile (("t.stg" {|
foo() ::= "|"
test(name,sep) ::= "hi <name; separator=foo()>!"
|})))
 (runs
  (
   ((input "<test(name,sep)>")
    (output "hi Ter|Tom|Sumana!")
    (attributes ((name (MV ((STRING Ter) (STRING Tom) (STRING Sumana))))
    		 (sep (SV (STRING ", ")))))
    )
   )
  )
 ))
("testListApplyWithNullValueAndNullOption"
((classname hello)
 (groupfile (("t.stg" {|
test(name) ::= "<name:{n | <n>}; null=\"n/a\">"
|})))
 (runs
  (
   ((input "<test(name)>")
    (output "Tern/aSumana")
    (attributes ((name (MV ((STRING Ter) NULL (STRING Sumana))))))
    )
   )
  )
 ))
("testMissingValueAndNullOption"
((classname hello)
 (groupfile (("t.stg" {|
test(name) ::= "<name; null=\"n/a\">"
|})))
 (runs
  (
   ((input "<test(name)>")
    (output "n/a")
    )
   )
  )
 (errors {bar|context [anonymous] 1:6 attribute name isn't defined
|bar})
 ))
("testNullValueAndNullOption"
((classname hello)
 (groupfile (("t.stg" {|
test(name) ::= "<name; null=\"n/a\">"
|})))
 (runs
  (
   ((input "<test(name)>")
    (output "n/a")
    (attributes ((name (SV NULL))))
    )
   )
  )
 ))
("testOptionDoesntApplyToNestedTemplate"
((classname hello)
 (groupfile (("t.stg" {|
foo() ::= "<zippo>"
test(zippo) ::= "<foo(); null=\"n/a\">"
|})))
 (runs
  (
   ((input "<test(zippo)>")
    (output "")
    (attributes ((zippo (SV NULL))))
    )
   )
  )
 ))
("testSeparator"
((classname hello)
 (groupfile (("t.stg" {|
test(name) ::= "hi <name; separator=\", \">!"
|})))
 (runs
  (
   ((input "<test(name)>")
    (output "hi Ter, Tom, Sumana!")
    (attributes ((name (MV ((STRING Ter) (STRING Tom) (STRING Sumana))))))
    )
   )
  )
 ))
("testSeparatorWithNull2ndValueAndNullOption"
((classname hello)
 (groupfile (("t.stg" {|
test(name) ::= "hi <name; null=\"n/a\", separator=\", \">!"
|})))
 (runs
  (
   ((input "<test(name)>")
    (output "hi Ter, n/a, Sumana!")
    (attributes ((name (MV ((STRING Ter) NULL (STRING Sumana))))))
    )
   )
  )
 ))
("testSeparatorWithNullFirstValueAndNullOption"
((classname hello)
 (groupfile (("t.stg" {|
test(name) ::= "hi <name; null=\"n/a\", separator=\", \">!"
|})))
 (runs
  (
   ((input "<test(name)>")
    (output "hi n/a, Tom, Sumana!")
    (attributes ((name (MV (NULL (STRING Tom) (STRING Sumana))))))
    )
   )
  )
 ))
("testSeparatorWithSpaces"
((classname hello)
 (groupfile (("t.stg" {|
test(name) ::= "hi <name; separator= \", \">!"
|})))
 (runs
  (
   ((input "<test(name)>")
    (output "hi Ter, Tom, Sumana!")
    (attributes ((name (MV ((STRING Ter) (STRING Tom) (STRING Sumana))))))
    )
   )
  )
 ))
("testSubtemplateSeparator"
((classname hello)
 (groupfile (("t.stg" {|
test(name,sep) ::= "hi <name; separator={<sep> _}>!"
|})))
 (runs
  (
   ((input "<test(name,sep)>")
    (output "hi Ter, _Tom, _Sumana!")
    (attributes ((name (MV ((STRING Ter) (STRING Tom) (STRING Sumana))))
    		 (sep (SV (STRING ",")))))
    )
   )
  )
 ))
)
