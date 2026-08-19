((classname hello)
 (groupfile (("t.stg" {| 
t1() ::= <<
<name; separator="\n">
>>
t2() ::= <<
<name; separator={<"\n">}>
>>
t3() ::= <<
<name; separator={<\n>}>
>>
t4() ::= <<
Ter<\n>Tom<\n>Sumana
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
  <t1()>
|})
      (output {bar|
  Ter
  Tom
  Sumana
|bar})
      (attributes ((name (MV ((STRING Ter) (STRING Tom) NULL (STRING Sumana))))))
      )
     ((input {|
  <t2()>
|})
      (output {bar|
  Ter
  Tom
  Sumana
|bar})
      (attributes ((name (MV ((STRING Ter) (STRING Tom) NULL (STRING Sumana))))))
      )
     ((input {|
  <t3()>
|})
      (output {bar|
  Ter
  Tom
  Sumana
|bar})
      (attributes ((name (MV ((STRING Ter) (STRING Tom) NULL (STRING Sumana))))))
      )
     ((input {|
  <t4()>
|})
      (output {bar|
  Ter
  Tom
  Sumana
|bar})
      (attributes ((name (MV ((STRING Ter) (STRING Tom) NULL (STRING Sumana))))))
      )
     ((input {|
  <t5()>
|})
      (output {bar|
  Ter
  Tom
  Sumana
|bar})
      (attributes ((name (MV ((STRING Ter) (STRING Tom) NULL (STRING Sumana))))))
      )
     ((input {|
  <t6()>
|})
      (output {bar|
  Ter
  Tom
  Sumana
|bar})
      (attributes ((name (MV ((STRING Ter) (STRING Tom) NULL (STRING Sumana))))))
      )
     ((input {|
  <name; separator="\n">
|})
      (output {bar|
  Ter
  Tom
  Sumana
|bar})
      (attributes ((name (MV ((STRING Ter) (STRING Tom) NULL (STRING Sumana))))))
      )
     ((input {|
  Ter<\n>Tom<\n>Sumana
|})
      (output {bar|
  Ter
Tom
Sumana
|bar})
      )
     ((input {|
  Ter<"\n">Tom<"\n">Sumana
|})
      (output {bar|
  Ter
Tom
Sumana
|bar})
      )
     ((input {|
  <\ ><name; separator="\n">
|})
      (output {bar|
   Ter
Tom
Sumana
|bar})
      (attributes ((name (MV ((STRING Ter) (STRING Tom) NULL (STRING Sumana))))))
      )
     ((input {|
  <name; separator="\n  ">
|})
      (output {bar|
  Ter
    Tom
    Sumana
|bar})
      (attributes ((name (MV ((STRING Ter) (STRING Tom) NULL (STRING Sumana))))))
      )
     ((input {|
  <name; separator={<"\n">}>
|})
      (output {bar|
  Ter
  Tom
  Sumana
|bar})
      (attributes ((name (MV ((STRING Ter) (STRING Tom) NULL (STRING Sumana))))))
      )
     ((input {|
  <name; separator={<\n>}>
|})
      (output {bar|
  Ter
  Tom
  Sumana
|bar})
      (attributes ((name (MV ((STRING Ter) (STRING Tom) NULL (STRING Sumana))))))
      )
     )
    )
   )