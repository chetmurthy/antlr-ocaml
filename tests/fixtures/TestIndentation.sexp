(
("testIFInSubtemplate"
((classname hello)
 (runs
  (((input {|<names:{n |
   <if(x)>
   <x>
   <else>
   <y>
   <endif>
}>
|})
    (output "   y\n\n")
    (attributes ((names (SV (STRING Ter))) (y (SV (STRING y)))))
    ))
  )
 (errors {bar|context [anonymous /_sub1] 2:7 attribute x isn't defined
|bar})
 ))
("testIFWithIndentAndExprOnMultipleLines"
((classname hello)
 (runs
  (((input {|begin
   <if(x)>
   <x>
   <else>
   <y>
   <endif>
end
|})
    (output "begin\n   y\nend\n")
    (attributes ((y (SV (STRING y)))))
    ))
  )
 (errors {bar|context [anonymous] 2:7 attribute x isn't defined
|bar})
 ))
("testIFWithIndentAndExprWithIndentOnMultipleLines"
((classname hello)
 (runs
  (((input {|begin
   <if(x)>
     <x>
   <else>
     <y>
   <endif>
end
|})
    (output "begin\n     y\nend\n")
    (attributes ((y (SV (STRING y)))))
    ))
  )
 (errors {bar|context [anonymous] 2:7 attribute x isn't defined
|bar})
 ))
("testIFWithIndentOnMultipleLines"
((classname hello)
 (runs
  (((input {|begin
   <if(x)>
   foo
   <else>
   bar
   <endif>
end
|})
    (output "begin\n   bar\nend\n")
    ))
  )
 (errors {bar|context [anonymous] 2:7 attribute x isn't defined
|bar})
 ))
("testIndentBetweenLeftJustifiedLiterals"
((classname hello)
 (groupfile
  (("t.stg"
    {| 
list(names) ::= <<
Before:
  <names; separator="\n">
after
>>

|}
    ))
  )
 (runs
  (((input "<list(names)>")
    (output {|Before:
  Terence
  Jim
  Sriram
after|})
    (attributes
     ((names (MV ((STRING Terence) (STRING Jim) (STRING Sriram)))))
     )
    ))
  )
 ))
("testIndentedIFWithElse2"
((classname hello)
 (runs
  (((input {|begin
    <if(x)>foo<else>bar<endif>
end
|})
    (output "begin\n    bar\nend\n")
    (attributes ((x (SV (BOOL false)))))
    ))
  )
 ))
("testIndentedIFWithElse"
((classname hello)
 (runs
  (((input {|begin
    <if(x)>foo<else>bar<endif>
end
|})
    (output "begin\n    foo\nend\n")
    (attributes ((x (SV (STRING x)))))
    ))
  )
 ))
("testIndentedIFWithEndifNextLine"
((classname hello)
 (runs
  (((input {|begin
    <if(x)>foo
    <endif>
end
|})
    (output "begin\n    foo\nend\n")
    (attributes ((x (SV (STRING x)))))
    ))
  )
 ))
("testIndentedIFWithNewlineBeforeText"
((classname hello)
 (runs
  (((input {|begin
    <if(x)>
foo
    <endif>
end
|})
    (output "begin\nfoo\nend\n")
    (attributes ((x (SV (STRING x)))))
    ))
  )
 ))
("testIndentedIFWithValueExpr"
((classname hello)
 (runs
  (((input {|begin
    <if(x)>foo<endif>
end
|})
    (output "begin\n    foo\nend\n")
    (attributes ((x (SV (STRING x)))))
    ))
  )
 ))
("testIndentInFrontOfTwoExpr"
((classname hello)
 (groupfile (("t.stg" {| 
list(a,b) ::= <<
  <a><b>
>>

|})))
 (runs
  (((input "<list(a,b)>")
    (output "  TerenceJim")
    (attributes ((a (SV (STRING Terence))) (b (SV (STRING Jim)))))
    ))
  )
 ))
("testIndentOfMultilineAttributes"
((classname hello)
 (groupfile
  (("t.stg" {| 
list(names) ::= <<
  <names; separator="\n">
>>

|}))
  )
 (runs
  (((input "<list(names)>")
    (output {|  Terence
  is
  a
  maniac
  Jim
  Sriram
  is
  cool|})
    (attributes
     ((names
       (MV
        ((STRING {|Terence
is
a
maniac|})
         (STRING Jim)
         (STRING {|Sriram
is
cool|})
         )
        )
       ))
     )
    ))
  )
 ))
("testIndentOfMultipleBlankLines"
((classname hello)
 (groupfile (("t.stg" {| 
list(names) ::= <<
  <names>
>>
|})))
 (runs
  (((input "<list(names)>")
    (output {|  Terence

  is a maniac|})
    (attributes ((names (SV (STRING {|Terence

is a maniac|})))))
    ))
  )
 ))
("testNestedIFWithIndentOnMultipleLines"
((classname hello)
 (runs
  (((input {|begin
   <if(x)>
      <if(y)>
      foo
      <endif>
   <else>
      <if(z)>
      foo
      <endif>
   <endif>
end
|})
    (output "begin\n      foo\nend\n")
    (attributes ((x (SV (STRING x))) (y (SV (STRING y)))))
    ))
  )
 ))
("testNestedIndent"
((classname hello)
 (groupfile
  (("t.stg"
    {| 
method(name,stats) ::= <<
void <name>() {
	<stats; separator="\n">
}
>>
ifstat(expr,stats) ::= <<
if (<expr>) {
  <stats; separator="\n">
}
>>
assign(lhs,expr) ::= "<lhs>=<expr>;"

|}
    ))
  )
 (runs
  (((input
     {|<method(name="foo",stats=[assign(lhs="x", expr="0"),ifstat(expr="x>0",stats=[assign(lhs="y",expr="x+y"), assign(lhs="z", expr="4")])])>|}
     )
    (output {|void foo() {
	x=0;
	if (x>0) {
	  y=x+y;
	  z=4;
	}
}|})
    )
  )
  )
 ))
("testSimpleIndentOfAttributeList"
((classname hello)
 (groupfile
  (("t.stg" {| 
list(names) ::= <<
  <names; separator="\n">
>>

|}))
  )
 (runs
  (((input "<list(names)>")
    (output {|  Terence
  Jim
  Sriram|})
    (attributes
     ((names (MV ((STRING Terence) (STRING Jim) (STRING Sriram)))))
     )
    ))
  )
 ))
)
