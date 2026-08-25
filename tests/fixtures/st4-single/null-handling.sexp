((classname hello)
   (runs
    (
     ((input {|
  <x; separator="\n", null="*">
|})
      (output {bar|
  *
|bar})
      (attributes ((x (SV NULL))))
      )
     ((input {|
  <x; null="*">
|})
      (output {bar|
  *
|bar})
      (attributes ((x (SV NULL))))
      )
     ((input {|
  <x>
|})
      (output {bar|
|bar})
      (attributes ((x (SV NULL))))
      )
     ((input {|
  <x>
|})
      (output {bar|
|bar})
      (attributes ((x (MV (NULL NULL)))))
      )
     ((input {|
  <["a",,"b"]; separator="\n", null="*">
|})
      (output {bar|
  a
  *
  b
|bar})
      )
     ((input {|
  <["a",,"b"]; separator="\n">
|})
      (output {bar|
  a
  b
|bar})
      )
     ((input {|<["a",,"b"]; separator=",">|})
      (output {bar|a,b|bar})
      )

     ((input {|<["b",]; separator=",">|})
      (output {bar|b|bar})
      )

     ((input {|<[,"b"]; separator=",">|})
      (output {bar|b|bar})
      )


     ((input {|
  <["a",,"b"]; null="*">
|})
      (output {bar|
  a*b
|bar})
      )
     ((input {|
  <["a",,"b"]>
|})
      (output {bar|
  ab
|bar})
      )
     )
    )
   )