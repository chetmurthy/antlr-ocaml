(
("testCommentOnlyLineGivesNoOutput2"
((classname hello)
 (runs
  (
   ((input "begin\n    <! ignore !>\nend\n")
    (output "begin\nend\n")
    )
   )
  )
 ))
("testCommentOnlyLineGivesNoOutput"
((classname hello)
 (runs
  (
   ((input "begin\n<! ignore !>\nend\n")
    (output "begin\nend\n")
    )
   )
  )
 ))
("testDontTrimJustSpaceBeforeAfterInTemplate"
((classname hello)
 (groupfile (("t.stg" {|
a(x) ::= << foo >>
|})))
 (runs
  (
   ((input "<a(x)>")
    (output " foo ")
    )
   )
  )
 (errors {bar|context [anonymous] 1:3 attribute x isn't defined
|bar})
 ))
("testElseIFOnMultipleLines2"
((classname hello)
 (runs
  (
   ((input "begin\n<if(a)>\nfoo\n<elseif(b)>\nbar\n<endif>\nend\n")
    (output "begin\nbar\nend\n")
    (attributes ((b (SV (BOOL true)))))
    )
   )
  )
 (errors {bar|context [anonymous] 2:4 attribute a isn't defined
|bar})
 ))
("testElseIFOnMultipleLines3"
((classname hello)
 (runs
  (
   ((input "begin\n  <if(a)>\n  foo\n  <elseif(b)>\n  bar\n  <endif>\nend\n")
    (output "begin\n  foo\nend\n")
    (attributes ((a (SV (BOOL true)))))
    )
   )
  )
 ))
("testElseIFOnMultipleLines"
((classname hello)
 (runs
  (
   ((input "begin\n<if(a)>\nfoo\n<elseif(b)>\nbar\n<endif>\nend\n")
    (output "begin\nend\n")
    )
   )
  )
 (errors {bar|context [anonymous] 2:4 attribute a isn't defined
context [anonymous] 4:8 attribute b isn't defined
|bar})
 ))
("testEmptyExprAsFirstLineGetsNoOutput"
((classname hello)
 (runs
  (
   ((input "<users>\nend\n")
    (output "end\n")
    )
   )
  )
 (errors {bar|context [anonymous] 1:1 attribute users isn't defined
|bar})
 ))
("testEmptyLineWithIndent"
((classname hello)
 (runs
  (
   ((input "begin\n\nend\n")
    (output "begin\n\nend\n")
    )
   )
  )
 ))
("testEndifNotOnLineAlone"
((classname hello)
 (runs
  (
   ((input "begin\n  <if(users)>\n  foo\n  <else>\n  bar\n  <endif>end\n")
    (output "begin\n  bar\nend\n")
    )
   )
  )
 (errors {bar|context [anonymous] 2:6 attribute users isn't defined
|bar})
 ))
("testIFElseExprOnSingleLine"
((classname hello)
 (runs
  (
   ((input "begin\n<if(users)><else><endif>\nend\n")
    (output "begin\nend\n")
    )
   )
  )
 (errors {bar|context [anonymous] 2:4 attribute users isn't defined
|bar})
 ))
("testIFExpr"
((classname hello)
 (runs
  (
   ((input "begin\n<if(x)><endif>\nend\n")
    (output "begin\nend\n")
    )
   )
  )
 (errors {bar|context [anonymous] 2:4 attribute x isn't defined
|bar})
 ))
("testIFOnMultipleLines"
((classname hello)
 (runs
  (
   ((input "begin\n<if(users)>\nfoo\n<else>\nbar\n<endif>\nend\n")
    (output "begin\nbar\nend\n")
    )
   )
  )
 (errors {bar|context [anonymous] 2:4 attribute users isn't defined
|bar})
 ))
("testIndentedIFExpr"
((classname hello)
 (runs
  (
   ((input "begin\n    <if(x)><endif>\nend\n")
    (output "begin\nend\n")
    )
   )
  )
 (errors {bar|context [anonymous] 2:8 attribute x isn't defined
|bar})
 ))
("testLeaveNewlineOnEndInSubtemplates"
((classname hello)
 (groupfile (("t.stg" {|
test(names) ::= "<names:{n |
<n>
}>!"
|})))
 (runs
  (
   ((input "<test(names)>")
    (output "Ter\nTom\nSumana\n!")
    (attributes
	((names (MV ((STRING Ter) (STRING Tom) (STRING Sumana)))))
     )
    )
   )
  )
 (errors {bar|t.stg 2:28: \n in string
t.stg 3:3: \n in string
|bar})
 ))
("testLineBreak2"
((classname hello)
 (runs
  (
   ((input "Foo <\\\\>       \n  \t  bar\n")
    (output "Foo bar\n")
    )
   )
  )
 ))
("testLineBreakNoWhiteSpace"
((classname hello)
 (runs
  (
   ((input "Foo <\\\\>\nbar\n")
    (output "Foo bar\n")
    )
   )
  )
 ))
("testLineBreak"
((classname hello)
 (runs
  (
   ((input "Foo <\\\\>\n  \t  bar\n")
    (output "Foo bar\n")
    )
   )
  )
 ))
("testNestedIFOnMultipleLines"
((classname hello)
 (runs
  (
   ((input "begin\n<if(x)>\n<if(y)>\nfoo\n<else>\nbar\n<endif>\n<endif>\nend\n")
    (output "begin\nbar\nend\n")
    (attributes ((x (SV (STRING x)))))
    )
   )
  )
 (errors {bar|context [anonymous] 3:4 attribute y isn't defined
|bar})
 ))
("testNewlineNormalizationInAttribute"
((classname hello)
 (runs
  (
   ((input "Foo\r\n<name>\n")
    (output "Foo\na\nb\nc\n")
    (attributes ((name (SV (STRING "a\nb\r\nc")))))
    )
   )
  )
 ))
("testNewlineNormalizationInTemplateStringPC"
((ignore true)
 (classname hello)
 (runs
  (
   ((input "Foo\r\nBar\n")
    (output "Foo\r\nBar\r\n")
    )
   )
  )
 ))
("testNewlineNormalizationInTemplateString"
((classname hello)
 (runs
  (
   ((input "Foo\r\nBar\n")
    (output "Foo\nBar\n")
    )
   )
  )
 ))
("testNoTrimmedNewlinesBeforeAfterInCodedTemplate"
((classname hello)
 (runs
  (
   ((input "\nfoo\n")
    (output "\nfoo\n")
    )
   )
  )
 ))
("testSizeZeroOnLineByItselfGetsNoOutput"
((classname hello)
 (runs
  (
   ((input "begin\n<name>\n<users>\n<users>\nend\n")
    (output "begin\nend\n")
    )
   )
  )
 (errors {bar|context [anonymous] 2:1 attribute name isn't defined
context [anonymous] 3:1 attribute users isn't defined
context [anonymous] 4:1 attribute users isn't defined
|bar})
 ))
("testSizeZeroOnLineWithIndentGetsNoOutput"
((classname hello)
 (runs
  (
   ((input "begin\n  <name>\n   <users>\n   <users>\nend\n")
    (output "begin\nend\n")
    )
   )
  )
 (errors {bar|context [anonymous] 2:3 attribute name isn't defined
context [anonymous] 3:4 attribute users isn't defined
context [anonymous] 4:4 attribute users isn't defined
|bar})
 ))
("testSizeZeroOnLineWithMultipleExpr"
((classname hello)
 (runs
  (
   ((input "begin\n  <name>\n   <users><users>\nend\n")
    (output "begin\nend\n")
    )
   )
  )
 (errors {bar|context [anonymous] 2:3 attribute name isn't defined
context [anonymous] 3:4 attribute users isn't defined
context [anonymous] 3:11 attribute users isn't defined
|bar})
 ))
("testTabBeforeEndInSubtemplates"
((ignore true)
 (classname hello)
 (groupfile (("t.stg" {|
test(names) ::= "  <names:{n |
    <n>
  }>!"
|})))
 (runs
  (
   ((input "<test(names)>")
    (output "    Ter\n    Tom\n    Sumana\n!")
    (attributes
	((names (MV ((STRING Ter) (STRING Tom) (STRING Sumana)))))
     )
    )
   )
  )
 (errors {bar|t.stg 2:30: \n in string
t.stg 3:7: \n in string
|bar})
 ))
("testTrimJustOneWSInSubtemplates"
((classname hello)
 (groupfile (("t.stg" {|
test(names) ::= "<names:{n |  <n> }>!"
|})))
 (runs
  (
   ((input "<test(names)>")
    (output " Ter  Tom  Sumana !")
    (attributes
	((names (MV ((STRING Ter) (LIST ((STRING Tom) (STRING Sumana)))))))
     )
    )
   )
  )
 ))
("testTrimmedNewlinesBeforeAfterInTemplate"
((classname hello)
 (groupfile (("t.stg" {|
a(x) ::= <<
foo
>>
|})))
 (runs
  (
   ((input "<a(x)>")
    (output "foo")
    )
   )
  )
 (errors {bar|context [anonymous] 1:3 attribute x isn't defined
|bar})
 ))
("testTrimmedSubtemplatesArgs"
((classname hello)
 (groupfile (("t.stg" {|
test(names) ::= "<names:{x|  foo }>"
|})))
 (runs
  (
   ((input "<test(names)>")
    (output " foo  foo  foo ")
    (attributes
	((names (MV ((STRING Ter) (LIST ((STRING Tom) (STRING Sumana)))))))
     )
    )
   )
  )
 ))
("testTrimmedSubtemplatesNoArgs"
((classname hello)
 (groupfile (("t.stg" {|
test() ::= "[<foo({ foo })>]"
foo(x) ::= "<x>"
|})))
 (runs
  (
   ((input "<test()>")
    (output "[ foo ]")
    )
   )
  )
 ))
("testTrimmedSubtemplates"
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
("testTrimNewlineInSubtemplates"
((classname hello)
 (groupfile (("t.stg" {|
test(names) ::= "<names:{n |
<n>}>!"
|})))
 (runs
  (
   ((input "<test(names)>")
    (output "TerTomSumana!")
    (attributes
	((names (MV ((STRING Ter) (STRING Tom) (STRING Sumana)))))
     )
    )
   )
  )
 (errors {bar|t.stg 2:28: \n in string
|bar})
 ))
)
