((classname hello)
 (groupfile (("g.stg" {|
t(x) ::= "[<x>]"
u(name) ::= "[<name>]"

|})))
   (runs
    (
     ((input {|<"Hello">, <name>!|})
      (output {bar|Hello, FooBar!|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
basic, basic, basic
|}
       )
      )
     ((input {|
  <"Hello">, <name>!
|})
      (output {|
  Hello, FooBar!
|})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
basic, basic, basic
|}
       )
      )
     ((input {|
  <"Hello">, <t(name)>!
|})
      (output {|
  Hello, [FooBar]!
|})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
basic, basic, basic
|}
       )
      (name "simple function-application")
      )
     ((input {|
  <"Hello">, <u({<name>})>!
|})
      (output {|
  Hello, [FooBar]!
|})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
basic, basic, basic
|}
       )
      )
     ((input {|
  <"Hello">, <name:t()>!
|})
      (output {|
  Hello, [Foo][Bar]!
|})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
basic, basic, basic
|}
       )
      )
     )
    )
   )