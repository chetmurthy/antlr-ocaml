((classname hello)
 (runs
  (
   ((input "Foo <\\\\>       \n  \t  bar\n")
    (output "Foo bar\n")
    )
   ((input "Foo <\\\\>\nbar\n")
    (output "Foo bar\n")
    )
   ((input "Foo <\\\\>\n  \t  bar\n")
    (output "Foo bar\n")
    )
   ((input "Foo <\\\\>Bar\n")
    (output "Foo ar\n")
    )
   ((input "Foo <\\\\>   Bar")
    (output "Foo ar")
    )
   ((input "Foo <\\\\>")
    (output "Foo ")
    )
   ((input {|Foo <\\>
  bar
|})
    (output "Foo bar\n")
    )
   ((input {|Foo \
  bar
|})
    (output {bar|Foo \
  bar
|bar})
    )
   ((input {|
    stream = CommonTokenStream(lexer)<\\>
<if(parserName)>
    ParseTreeWalker.DEFAULT.walk(TreeShapeListener(), tree)
<else>
    stream.fill()
<endif>
|})
    (output {bar|
    stream = CommonTokenStream(lexer)
    stream.fill()
|bar})
    )


   )
  )
  (errors {bar|1:8: expecting '
', found 'B'
1:11: expecting '
', found 'B'
1:8: Missing newline after newline escape <\\>
context [anonymous] 3:4 attribute parserName isn't defined
|bar})
 )