((classname hello)
 (groupfile (("t.stg" {|
t1a(x) ::= "<x>"
t1b(x) ::= << <x> >>
t1c(x) ::= <%<x>%>
t1d(x) ::= <<
  <x>
>>
t1e(x) ::= <<
  <x>
>>
t1(x) ::= <% <t1a(x)> %>
t2(x) ::= <% <t2a(x)> %>
t2a(x) ::= <<
  
|  <x>
  
>>
t2b(x) ::= <<
a
<x>
b
>>
t2c(x) ::= <<
  c
  <x>
  d
>>
t3(x) ::= <<
  \<!<x>!>
>>
t4(x) ::= <<
  <x>
>>
t5() ::= <<
Ter<\n>Tom<\n>Sumana
>>
t6() ::= <<
Ter
Tom
Sumana
>>
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
     ((input {|
name:t1b()
<{<name:t1b()>}>
|})
      (output {bar|
name:t1b()
 Foo Bar 
|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      )
     ((input {|
name:t1c()
<{<name:t1c()>}>
|})
      (output {bar|
name:t1c()
FooBar
|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      )
     ((input {|
name:t1d()
<{<name:t1d()>}>
|})
      (output {bar|
name:t1d()
  FooBar
|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      )
     ((input {|
name:t1e()
<{<name:t1e()>}>
|})
      (output {bar|
name:t1e()
  FooBar
|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      )
     )
    )
   )