((classname hello)
 (groupfile (("g.stg" {|
t(x) ::= "[<x>]"
two(p,x) ::= "[<p> <x>]"
twonamed(p="1",x="36") ::= "[<p> <x>]"
three(p,x,y) ::= "[<p> <x> <y>]"
threenamed(p="foo",x="1",y="2") ::= "[<p> <x> <y>]"
u(x) ::= << <x> >>
v(y) ::= << <y> >>

|})))
   (runs
    (
     ((input {|<[]:t()>|})
      (output {bar||bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
two inputs, one two-arg receiver: in subtemplate, it works
|}
       )
      (name "two inputs, one two-arg receiver subtemplate")
      )
     ((input {|<[,,]:t()>|})
      (output {bar||bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
two inputs, one two-arg receiver: in subtemplate, it works
|}
       )
      (name "two inputs, one two-arg receiver subtemplate")
      )
     ((input {|<[],[]:{x,y|<two(x,y)>}>|})
      (output {bar||bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
two inputs, one two-arg receiver: in subtemplate, it works
|}
       )
      (name "two inputs, one two-arg receiver subtemplate")
      )
     ((input {|<[,,],[,,]:{x,y|<two(x,y)>}>|})
      (output {bar|[ ][ ][ ]|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
two inputs, one two-arg receiver: in subtemplate, it works
|}
       )
      (name "two inputs, one two-arg receiver subtemplate")
      )
     ((input {|<[,,],[,,]:{x,y|<i> <two(x,y)>}>|})
      (output {bar|1 [ ]2 [ ]3 [ ]|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
two inputs, one two-arg receiver: in subtemplate, it works
|}
       )
      (name "two inputs, one two-arg receiver subtemplate")
      )
     ((input {|<[],[,,]:{x,y|<two(x,y)>}>|})
      (output {bar|[ ][ ][ ]|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
two inputs, one two-arg receiver: in subtemplate, it works
|}
       )
      (name "two inputs, one two-arg receiver subtemplate")
      )
     ((input {|<"a",[]:{x,y|<two(x,y)>}>|})
      (output {bar|[a ]|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
two inputs, one two-arg receiver: in subtemplate, it works
|}
       )
      (name "two inputs, one two-arg receiver subtemplate")
      )
     ((input {|<"a",["d"]:{x,y|<two(x,y)>}>|})
      (output {bar|[a d]|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
two inputs, one two-arg receiver: in subtemplate, it works
|}
       )
      (name "two inputs, one two-arg receiver subtemplate")
      )
     ((input {|<["a"],["d"]:{x,y|<two(x,y)>}>|})
      (output {bar|[a d]|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
two inputs, one two-arg receiver: in subtemplate, it works
|}
       )
      (name "two inputs, one two-arg receiver subtemplate")
      )
     ((input {|<["a","b","c"],["d","e","f"]:{x,y|<two(x,y)>}>|})
      (output {bar|[a d][b e][c f]|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
two inputs, one two-arg receiver: in subtemplate, it works
|}
       )
      (name "two inputs, one two-arg receiver subtemplate")
      )
     )
    )
   )