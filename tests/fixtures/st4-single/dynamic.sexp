((classname hello)
 (groupfile (("t.stg" {|
t1(x,y={<name>}) ::= "<x><g(y)>"
g(z,name="Baz") ::= "<z>"
brackets(arg) ::= "[<arg>]"


|})))
   (runs
    (
     ((input {|
<t1("a")>
|})
      (output "\naBaz\n")
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
t1() -> g(), and g shadows "name", so t1's default argument evaluates to g's shadowed binding.
Default args are evaluated by-name/lazily.
|}
       )
      )
     ((input {|
<g(name)>
|})
      (output "\nFooBar\n")
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
in call to g, UNNAMED args are evaluated by-value
|}
       )
      )
     ((input {|
<g({<name>})>
|})
      (output "\nBaz\n")
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
in call to g, UNNAMED SUBTEMPLATE args are evaluated lazily by-naame
|}
       )
      )
     ((input {|
<g(name:brackets())>
|})
      (output "\n[Foo][Bar]\n")
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
in call to g, UNNAMED map-expression args are evaluated by-value
|}
       )
      )
     ((input {|
<g(brackets(name))>
|})
      (output "\n[FooBar]\n")
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
in call to g, function-call args are evaluated by-value
|}
       )
      )
     ((input {|
<g(z=name)>
|})
      (output "\nFooBar\n")
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
in call to g, NAMED args are evaluated by-value
|}
       )
      )
     ((input {|
<g(name,"")>
|})
      (output "\nFooBar\n")
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
in call to g, UNNAMED args are evaluated by-value, so shadowing doesn't affect them.
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