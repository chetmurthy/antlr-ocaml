((classname hello)
   (runs
    (((input {|
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
  <\ ><name; separator="\n">
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