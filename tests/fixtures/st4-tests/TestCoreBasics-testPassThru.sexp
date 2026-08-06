((classname hello)
 (template_s {|<a("x","y")>|})
 (attributes ())
 (groupfile (("a.stg" 
{| 
  a(x,y) ::= "<b(...)>"
  b(x,y) ::= "<x><y>"
 |})))
 (expected {bar|xy|bar}))
 