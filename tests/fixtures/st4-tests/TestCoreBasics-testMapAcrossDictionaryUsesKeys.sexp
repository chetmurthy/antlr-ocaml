((classname hello)
 (template_s {|<foo:{f | <f>}>|})
 (attributes ((foo (SV (DICT ((a (STRING b)) (c (STRING d))))))))
 (groupfile ())
 (expected {bar|ac|bar}))
 