((classname hello)
   (groupfiles
    (("group.stg" {|
b() ::= "group file group.stg"
|})
     ("group2.stg" {|
b() ::= "group file group2.stg"
|})
     ("group/a.st" {| 
a() ::= <<dir1 a>>
|})
     )
    )
   (runs (
    ((input "<group/b()>")
     (output {bar|group file group.stg|bar})
     )
    ((input "<group2/b()>")
     (output {bar|group file group2.stg|bar})
     )
    ((input "<a()>")
     )
    ))
   (errors {|context [anonymous] 1:1 no such template: /a
|})
   )