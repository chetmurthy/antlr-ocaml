((classname hello)
 (groupfile (("g.stg" {|
t(x) ::= "[<x>]"
prepend(p,x) ::= "[<p> <x>]"
u(x) ::= << <x> >>
v(y) ::= << <y> >>

|})))
   (runs
    (
     ((input {|<["a","b"]:t()>|})
      (output {bar|[a][b]|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
simple map
|}
       )
      )
     ((input {|<["a","b"]:prepend("1")>|})
      (output {bar|[a 1][b 1]|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
map supplies the -first- argument, not last
|}
       )
      )
     ((input {|<["a","b","c","d","e","f"]:prepend("1"),prepend("2")>|})
      (output {bar|[a 1][b 2][c 1][d 2][e 1][f 2]|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
round-robin alternation of map receiver
|}
       )
      )
     ((input {|<["a","b","c","d","e","f"]:prepend("1"),prepend("2"):prepend("4"),prepend("5"),prepend("6")>|})
      (output {bar|[[a 1] 4][[b 2] 5][[c 1] 6][[d 2] 4][[e 1] 5][[f 2] 6]|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
and it can be more than two stages
|}
       )
      )
     ((input {|<["a","b","c"],["d","e","f"]:{x,y|<prepend(x,y)>}>|})
      (output {bar|[a d][b e][c f]|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
round-robin alternation of map receiver
|}
       )
      )
     ((input {|<["a","b","c"],["d","e","f","g"]:{x,y|<prepend(x,y)>}>|})
      (output {bar|[a d][b e][c f][ g]|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
round-robin alternation of map receiver
|}
       )
      )
     ((input {|<["a","b","c"],["d","e","f"]:prepend()>|})
      (output {bar|[a 1][b 2][c 1][d 2][e 1][f 2]|bar})
      (attributes ((name (MV ((STRING Foo) (STRING Bar))))))
      (comments {|
somehow prepend() (takes two args) doesn't work, but wrapping it in a subtemplate does.
|}
       )
      (name "this-fails")
      (disabled false)
      )
     ((input {|<u,v:{x,y|<prepend(x,y)>}>|})
      (output {bar|[a d][b e][c f]|bar})
      (attributes ((u (MV ((STRING a) (STRING b) (STRING c))))
      		   (v (MV ((STRING d) (STRING e) (STRING f))))
      		    ))
      (comments {|
use vars instead of lists
|}
       )
      )
     ((input {|<{<u:u()>}>,<{<v:v()>}>:{x,y|<prepend(x,y)>}>|})
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