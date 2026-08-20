((classname hello)
 (groupfile (("t.stg" {|
t2(x,y={<z>},z={<y>}) ::= "<x><y>"

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
     )
    )
   )