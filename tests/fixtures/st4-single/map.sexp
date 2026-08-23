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
     ((input {|<"b":t()>|})
      (output {bar|[b]|bar})
      (comments {|
simple map
|}
       )
      )
     ((input {|<["b"]:t()>|})
      (output {bar|[b]|bar})
      (comments {|
simple map
|}
       )
      )
     ((input {|<["a","b"]:t()>|})
      (output {bar|[a][b]|bar})
      (comments {|
simple map
|}
       )
      )
     ((input {|<"b":two("1")>|})
      (output {bar|[b 1]|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
map supplies the -first- argument, not last
|}
       )
      )
     ((input {|<["b"]:two("1")>|})
      (output {bar|[b 1]|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
map supplies the -first- argument, not last
|}
       )
      )
     ((input {|<["a","b"]:two("1")>|})
      (output {bar|[a 1][b 1]|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
map supplies the -first- argument, not last
|}
       )
      )
     ((input {|<["a","b"]:twonamed()>|})
      (output {bar|[a 36][b 36]|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
map supplies the -first- argument, not which can be named w/default
|}
       )
      )
     ((input {|<["a","b"]:three("1","2")>|})
      (output {bar|[a 1 2][b 1 2]|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
map supplies the -first- argument, not 2nd,3rd
|}
       )
      )
     ((input {|<["a","b"]:threenamed()>|})
      (output {bar|[a 1 2][b 1 2]|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
map supplies the -first- argument, not 2nd,3rd, and those can get default values
|}
       )
      )
     ((input {|<["a","b"]:two(x="1")>|})
      (output {bar|[a 1][b 1]|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
map supplies the -first- argument, not last
|}
       )
       (name "map with named arg (second arg)")
       (disabled true)
      )
     ((input {|<["a","b"]:two(p="1")>|})
      (output {bar|[a 1][b 1]|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
map supplies the -first- argument, not last
|}
       )
       (name "map with named arg (first arg)")
       (disabled true)
      )
     ((input {|<["a","b","c","d","e","f"]:two("1"),two("2")>|})
      (output {bar|[a 1][b 2][c 1][d 2][e 1][f 2]|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
round-robin alternation of map receiver
|}
       )
      )
     ((input {|<["a","b","c","d","e","f"]:two("1"),two("2"):two("4"),two("5"),two("6")>|})
      (output {bar|[[a 1] 4][[b 2] 5][[c 1] 6][[d 2] 4][[e 1] 5][[f 2] 6]|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
and it can be more than two stages
|}
       )
      )
     ((input {|<["a","b","c"],["d","e","f"]:{x,y|<two(x,y)>}>|})
      (output {bar|[a d][b e][c f]|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
round-robin alternation of map receiver
|}
       )
      )
     ((input {|<["a","b","c"],["d","e","f","g"]:{x,y|<two(x,y)>}>|})
      (output {bar|[a d][b e][c f][ g]|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
round-robin alternation of map receiver
|}
       )
      )
     ((input {|<["a","b","c"],["d","e","f"]:two()>|})
      (output {bar|[a 1][b 2][c 1][d 2][e 1][f 2]|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
somehow two() (takes two args) doesn't work, but wrapping it in a subtemplate does.
|}
       )
      (name "this-fails")
      (disabled true)
      )
     ((input {|<["a","b","c"],["d","e","f"]:twonamed()>|})
      (output {bar|[a 1][b 2][c 1][d 2][e 1][f 2]|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
somehow two() (takes two args) doesn't work, but wrapping it in a subtemplate does.
|}
       )
      (name "this-fails")
      (disabled true)
      )
     ((input {|<u,v:{x,y|<two(x,y)>}>|})
      (output {bar|[a d][b e][c f]|bar})
      (attributes ((u (MV ((STRING a) (STRING b) (STRING c))))
      		   (v (MV ((STRING d) (STRING e) (STRING f))))
      		    ))
      (comments {|
use vars instead of lists
|}
       )
      )
     ((input {|<{<u:u()>}>,<{<v:v()>}>:{x,y|<two(x,y)>}>|})
      (output {bar|[a d][b e][c f]|bar})
      (attributes ((u (MV ((STRING a) (STRING b) (STRING c))))
      		   (v (MV ((STRING d) (STRING e) (STRING f))))
      		    ))
      (comments {|
use functions instead of lists/vars -- doesn't work
|}
       )
      (disabled true)
      )
     )
    )
   )