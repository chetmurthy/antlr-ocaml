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
   )
  )
 )