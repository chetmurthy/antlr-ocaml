((classname hello)
 (groupfile (("g.stg" {|
writeln(s) ::= "std::cout \<\< <s> \<\< std::endl;"
|})))
   (runs
    (
     ((input {|{<writeln("\"I\"")>}|})
      (output {bar|{std::cout << "I" << std::endl;}|bar})
      (comments {|
basic variable-reference
|}
       )
      )

     )
    )
   )