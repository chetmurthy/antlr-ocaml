  ((classname hello)
   (groupfiles (("subdir/g.stg" {| 

b() ::= "bar"

|})))
   (runs (
    ((input "<subdir/g/b()>") (output bar))
    ((input "<subdir/b()>") (output ""))
    ((input "<b()>") (output ""))
    ))
   (errors {bar|context [anonymous] 1:1 no such template: /subdir/b
context [anonymous] 1:1 no such template: /b
|bar})
   )