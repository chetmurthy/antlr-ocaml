(
 ("hello"
  ((classname hello) (template_s "<{Hello, <name>!}>")
   (attributes ((name (SV (STRING World))))) (groupfile ())
   (expected "Hello, World!"))
  )
 ("TestCoreBasics-testNullAttr"
  ((classname testNullAttr)
   (template_s {|hi <name>!|})
   (attributes ())
   (groupfile ())
   (expected {bar|hi !|bar}))
  )
 )
