((classname hello)
 (groupfile (("t.stg" {|
t1(x,y={<name>}) ::= "<x><g(y)>"
g(z,name="Baz") ::= "<z>"

t2(x,y={<z>},z={<y>}) ::= "<x><y>"

|})))
   (runs
    (
     ((input {|
<t1("a")>
|})
      (output "\naBaz\n")
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
t1() -> g(), and g shadows "name", so t1's default argument evaluates to g's shadowed binding
|}
       )
      )
     ((input {|
<t1("a",{<x>})>
|})
      (output "\naa\n")
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
t1 shadows "x", and so y->x evaluates to x
|}
       )
      )
     ((input {|
<t1({<x>})>
|})
      (output "\naa\n")
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
t1 binds x->x, so stack overflow
|}
       )
      (disabled true)
      )
     )
    )
   )