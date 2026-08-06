((classname hello)
 (template_s {|<x>:<names>!|})
 (attributes
   ((names (MV ((STRING Ter) (STRING Tom))))
    (x (SV (STRING "1")))
   )
  )
 (groupfile ())
 (expected {bar|1:TerTom!|bar}))