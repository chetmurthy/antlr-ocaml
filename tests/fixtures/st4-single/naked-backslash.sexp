((classname hello)
 (runs
  (
((input {|<if(m.name)>works \\<endif>|})
      (output {|works \|})
      (attributes ((m (SV (DICT ((name (STRING Ter))))))))
      )

((input {|Foo \
  bar
|})
    (output {bar|Foo \
  bar
|bar})
    )

((input {|Foo \\
  bar
|})
    (output {bar|Foo \
  bar
|bar})
    )

((input {|foo \\bar|})
      (output {bar|foo \bar|bar})
      )

((input {|foo \bar|})
      (output {bar|foo \bar|bar})
      )

((input {|foo \\|})
      (output {bar|foo \|bar})
      )

((input {|foo \|})
      (output {bar|foo \|bar})
      )
   )
  )
 )