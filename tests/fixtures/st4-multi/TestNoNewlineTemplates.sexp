(
("testDefineRegionInSubgroup"
((classname hello)
   (groupfile (
("g2.stg" {|
import "g1.stg"
@a.r() ::= <%
   foo


%>
|})
))   (groupfiles (("g1.stg" {|
a() ::= <<[<@r()>]>>
|})
))

 (runs
  (
   ((input "<a()>")
    (output "[foo]")
    (attributes ((x (SV (INT 99)))))
    )
   )
  )
 ))
("testEmptyNoNewlineTemplate"
((classname hello)
 (groupfile (("t.stg" {|
t(x) ::= <%%>
|})))
 (runs
  (
   ((input "<t(x)>")
    (output "")
    (attributes ((x (SV (INT 99)))))
    )
   )
  )
 ))
("testIgnoreIndentInIF"
((classname hello)
 (groupfile (("t.stg" {|
t(x) ::= <%
   <if(x)>
       foo
   <endif>
   <x>
%>
|})))
 (runs
  (
   ((input "<t(x)>")
    (output "foo99")
    (attributes ((x (SV (INT 99)))))
    )
   )
  )
 ))
("testIgnoreIndent"
((classname hello)
 (groupfile (("t.stg" {|
t(x) ::= <%
   foo
   <x>
%>
|})))
 (runs
  (
   ((input "<t(x)>")
    (output "foo99")
    (attributes ((x (SV (INT 99)))))
    )
   )
  )
 ))
("testKeepWS"
((classname hello)
 (groupfile (("t.stg" {|
t(x) ::= <%
   <x> <x> hi
%>
|})))
 (runs
  (
   ((input "<t(x)>")
    (output "99 99 hi")
    (attributes ((x (SV (INT 99)))))
    )
   )
  )
 ))
("testNoNewlineTemplate"
((classname hello)
 (groupfile (("t.stg" {|t(x) ::= <%
[  <if(!x)>
<else>
<x>
<endif>


]

%>
|})))
 (runs
  (
   ((input "<t(x)>")
    (output "[  99]")
    (attributes ((x (SV (INT 99)))))
    )
   )
  )
 ))
("testRegion"
((classname hello)
 (groupfile (("t.stg" {|
t(x) ::= <%
<@r>
   Ignore
   newlines and indents
<x>


<@end>
%>

|})))
 (runs
  (
   ((input "<t(x)>")
    (output "Ignorenewlines and indents99")
    (attributes ((x (SV (INT 99)))))
    )
   )
  )
 ))
("testWSNoNewlineTemplate"
((classname hello)
 (groupfile (("t.stg" {|
t(x) ::= <%

%>
|})))
 (runs
  (
   ((input "<t(x)>")
    (output "")
    (attributes ((x (SV (INT 99)))))
    )
   )
  )
 ))
)
