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
basic variable-reference
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
bool true
|}
       )
      )
     ((input {|
  <"Hello">, <true>!
|})
      (output {|
  Hello, true!
|})
      (comments {|
basic variable-reference with whitespace but no separator.
|}
       )
      (name "simple boolean")
      )
     ((input {|
  <"Hello">, <false>!
|})
      (output {|
  Hello, false!
|})
      (comments {|
bool false
|}
       )
      (name "simple boolean(2)")
      )
     ((input {|
  <"Hello">, <["1",,"2"]>!
|})
      (output {|
  Hello, 12!
|})
      (comments {|
a simple list with a null
|}
       )
      (name "simple list")
      )
     ((input {|
  <"Hello">, <t(name)>!
|})
      (output {|
  Hello, [FooBar]!
|})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
simplest function-application
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
infinite loop name -> <{name}> (b/c dynamic binding, and
name -> {<name>} is not detected by ST4 interpreter where
name -> name would be.
|}
       )
       (disabled true)
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