((classname hello)
 (groupfile (("b.stg" {| 
import "a.stg"
t(x) ::= "<x>"
typeInit ::= ["int":"0", default:"null"] 
|})))
 (groupfiles (("a.stg" {| 
typeInit ::= ["int":"1", default:"something"] 
t(x) ::= "[<x>]"
|})))
   (runs
    (
     ((input {|
  <name:{x|<typeInit.(x)>}>
|})
      (output {bar|
  0null
|bar})
      (attributes ((name (MV ((STRING int) (STRING bool))))))
      )
     ((input {|
  <t(name)>
|})
      (output {bar|
  TerTomSumana
|bar})
      (attributes ((name (MV ((STRING Ter) (STRING Tom) NULL (STRING Sumana))))))
      )
     )
    )
   )