((classname hello)
   (groupfile (("a.stg" {| 
u ::= ["id":"0", "name": "Ter"] 
v ::= ["a":"b", "c": "d"] 
t(x) ::= "<x>"
t2(x,y) ::= "<x><y>"
|})))
   (runs (
    (
     (input "<foo:{f | <f>}>")
     (output ac)
     (attributes ((foo (SV (DICT ((a (STRING b)) (c (STRING d))))))))
     )
    (
     (input "<foo:t()>")
     (output ac)
     (attributes ((foo (SV (DICT ((a (STRING b)) (c (STRING d))))))))
     )
    (
     (input {|<foo:t2(".")>|})
     (output "a.c.")
     (attributes ((foo (SV (DICT ((a (STRING b)) (c (STRING d))))))))
     )
    (
     (input "<u.id>: <u.name>")
     (output "0: Ter")
     )
    (
     (input "<v>")
     (output "ac")
     )
    (
     (input "<foo>")
     (output "ac")
     (attributes ((foo (SV (DICT ((a (STRING b)) (c (STRING d))))))))
     )
    ((input "<if(m.name)>works \\\\<endif>")
     (output "works \\")
     (attributes ((m (SV (DICT ((name (STRING Ter))))))))
     )
    ((input "<if(u.id)>works \\\\<endif>")
     (output "works \\")
     (attributes ((m (SV (DICT ((name (STRING Ter))))))))
     )
    ((input "<if(u.argle)>works \\\\<endif>")
     (output "")
     (attributes ((m (SV (DICT ((name (STRING Ter))))))))
     )
    ((input "<if(w.argle)>works \\\\<endif>")
     (output "")
     (attributes ((m (SV (DICT ((name (STRING Ter))))))))
     )
  ))
  (errors {bar|context [anonymous] 1:4 attribute w isn't defined
|bar})
 )