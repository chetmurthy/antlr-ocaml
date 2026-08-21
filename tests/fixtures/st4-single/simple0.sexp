((classname hello)
 (groupfile (("t.stg" {|
t1a(x) ::= "<x>"
t1(x) ::= <% <t1a(x)> %>
|})))
   (runs
    (
     ((input {|
name
<{<name>}>
|})
      (output {bar|
name
FooBar
|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      )
     ((input {|
name:t1()
<{<name:t1()>}>
|})
      (output {bar|
name:t1()
Foo Bar 
|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      )
     ((input {|
name:t1a()
<{<name:t1a()>}>
|})
      (output {bar|
name:t1a()
FooBar
|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      )
     )
    )
   )