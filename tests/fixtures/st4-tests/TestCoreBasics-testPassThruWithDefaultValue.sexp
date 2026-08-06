((classname hello)
 (template_s {|<a(x="x")>|})
 (attributes ())
 (groupfile (("a.stg" 
{| 
  a(x,y) ::= "<b(...)>"
  b(x,y={99}) ::= "<x><y>"
 |})))
 (expected {bar|x99|bar}))
 