(
("testDefaultValueBehaviorEmptyList"
((classname hello)
 (groupfile (("t.stg" {| 
t(a=[]) ::= <<
<a><if(a)>+<else>-<endif>
>>
|})))
 (runs
  (
   ((input "<t()>")
    (output "-")
    (attributes ((x (SV (STRING hi)))))
    )
   )
  )
 ))
("testDefaultValueBehaviorEmptyTemplate"
((classname hello)
 (groupfile (("t.stg" {| 
t(a={}) ::= <<
<a><if(a)>+<else>-<endif>
>>
|})))
 (runs
  (
   ((input "<t()>")
    (output "+")
    (attributes ((x (SV (STRING hi)))))
    )
   )
  )
 ))
("testDefaultValueBehaviorFalse"
((classname hello)
 (groupfile (("t.stg" {| 
t(a=false) ::= <<
<a><if(a)>+<else>-<endif>
>>
|})))
 (runs
  (
   ((input "<t()>")
    (output "false-")
    (attributes ((x (SV (STRING hi)))))
    )
   )
  )
 ))
("testDefaultValueBehaviorTrue"
((classname hello)
 (groupfile (("t.stg" {| 
t(a=true) ::= <<
<a><if(a)>+<else>-<endif>
>>
|})))
 (runs
  (
   ((input "<t()>")
    (output "true+")
    (attributes ((x (SV (STRING hi)))))
    )
   )
  )
 ))
("testIndentedComment"
((classname hello)
 (groupfile (("t.stg" {| 
t() ::= <<
  <! a comment !>
>>
|})))
 (runs
  (
   ((input "<t()>")
    (output "")
    )
   )
  )
 ))
("testMessedUpTemplateDoesntCauseRuntimeError"
((classname hello)
 (groupfile (("t.stg" {| 
main(p) ::= <<
<f(x="abc")>
>>

f() ::= <<
<x>
>>
|})))
 (runs
  (
   ((input "<main(p)>")
    (output "")
    )
   )
  )
 (errors {bar|context [anonymous] 1:6 attribute p isn't defined
context [anonymous /main] 1:1 attribute x isn't defined
context [anonymous /main] 1:1 passed 1 arg(s) to template /f with 0 declared arg(s)
context [anonymous /main /f] 1:1 attribute x isn't defined
|bar})
 ))
("testSetDefaultDelimiters"
((classname hello)
 (groupfile (("t.stg" {| 
delimiters "<", ">"
ta(x) ::= "[<x>]"
|})))
 (runs
  (
   ((input "<ta(x)>")
    (output "[hi]")
    (attributes ((x (SV (STRING hi)))))
    )
   )
  )

 ))
("testSetDefaultDelimiters_STGroupString"
((classname hello)
 (groupfile (("t.stg" {| 
delimiters "<", ">"
chapter(title) ::= <<
chapter <title>
>>
|})))
 (runs
  (
   ((input "<chapter(title)>")
    (output "chapter hi")
    (attributes ((title (SV (STRING hi)))))
    )
   )
  )

 ))
("testSetNonDefaultDelimiters"
((classname hello)
 (groupfile (("t.stg" {| 
delimiters "%", "%"
ta(x) ::= "[%x%]"
|})))
 (runs
  (
   ((input "%ta(x)%")
    (output "[hi]")
    (attributes ((x (SV (STRING hi)))))
    )
   )
  )

 ))
("testSetUnsupportedDelimiters_At"
((classname hello)
 (groupfile (("t.stg" {| 
delimiters "@", "@"
ta(x) ::= "[<x>]"
|})))
 (runs
  (
   ((input "@ta(x)@")
    (output "@ta(x)@")
    (attributes ((x (SV (STRING hi)))))
    )
   )
  )
 (errors {bar|t.stg 2:11: unsupported delimiter character: @
t.stg 2:16: unsupported delimiter character: @
|bar})
 ))
)
