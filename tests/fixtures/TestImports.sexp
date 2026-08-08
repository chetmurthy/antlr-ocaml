((testEmptyGroupImportGroupFileSameDir
  ((classname hello)
   (groupfile (("group1.stg" {| 
import "group2.stg"
|})))
   (groupfiles (("group2.stg" {|c() ::= "g2 c"
|})))
   (runs (((input "<c()>") (output "g2 c"))))
   )
  )
 (testGroupFileInDirImportsAGroupDir
  ((classname hello)
   (groupfile (("g.stg" {|
import "subdir"
a() ::= "a: <b()>"
|})))
   (groupfiles
    (("subdir/b.st" {|b() ::= "b: <c()>"
|})
     ("subdir/c.st" {|c() ::= <<subdir c>>
|})
     )
    )
   (runs (((input "<a()>") (output "a: b: subdir c"))))
   )
  )
 (testGroupFileInDirImportsAnotherGroupFile
  ((classname hello)
   (groupfiles
    (("group.stg" {|
import "imported.stg"
a() ::= "a: <b()>"
|})
     ("imported.stg" {|b() ::= "b"
|})
     )
    )
   (runs (((input "</group/a()>"))))
   (errorsContains
    "import illegal in group files embedded in STGroupDirs; import \"imported.stg\" in STGroupDir"
    )
   )
  )
 (testImportDir
  ((classname hello)
   (groupfile
    (("root/dir1/g.stg" {| 
import "root/dir2"
a() ::= <<dir1 a>>

|}))
    )
   (groupfiles
    (("root/dir2/a.st" {|a() ::= <<dir2 a>>
|})
     ("root/dir2/b.st" {|b() ::= <<dir2 b>>
|})
     )
    )
   (runs (((input "<b()>") (output "dir2 b"))))
   )
  )
 (testImportGroupFileSameDir
  ((classname hello)
   (groupfile
    (("group1.stg" {| 
import "group2.stg"
a() ::= "g1 a"
b() ::= "<c()>"
|}))
    )
   (groupfiles (("group2.stg" {|c() ::= "g2 c"
|})))
   (runs (((input "<c()>") (output "g2 c"))))
   )
  )
 (testImportRelativeDir2
  ((classname hello)
   (groupfile (("root/g.stg" {| 
import "subdir"
a() ::= <<dir1 a>>
|})))
   (groupfiles
    (("root/subdir/a.st" {|a() ::= <<subdir a>>
|})
     ("root/subdir/b.st" {|b() ::= <<subdir b>>
|})
     ("root/subdir/c.st" {|c() ::= <<subdir c>>
|})
     )
    )
   (runs (((input "<c()>") (output "subdir c"))))
   )
  )
 (testImportRelativeDir
  ((classname hello)
   (groupfile (("root/g.stg" {| 
import "subdir"
a() ::= <<dir1 a>>
|})))
   (groupfiles
    (("root/subdir/a.st" {|a() ::= <<subdir a>>
|})
     ("root/subdir/b.st" {|b() ::= <<subdir b>>
|})
     ("root/subdir/c.st" {|c() ::= <<subdir c>>
|})
     )
    )
   (runs (((input "<b()>") (output "subdir b"))))
   )
  )
 (testImportRelativeGroupFile
  ((classname hello)
   (groupfile
    (("group1.stg"
      {| 
import "subdir/group2.stg"
a() ::= "g1 a"
b() ::= "<c()>"

|}
      ))
    )
   (groupfiles (("subdir/group2.stg" {|c() ::= "g2 c"
|})))
   (runs (((input "<c()>") (output "g2 c"))))
   )
  )
 (testImportRelativeTemplateFile
  ((classname hello)
   (groupfile
    (("group1.stg"
      {| 
import "subdir/c.st"
a() ::= "g1 a"
b() ::= "<c()>"

|}
      ))
    )
   (groupfiles (("subdir/c.st" {|c() ::= "c"
|})))
   (runs (((input "<c()>") (output c))))
   )
  )
 (testImportTemplateFileSameDir
  ((classname hello)
   (groupfile
    (("group1.stg" {| 
import "c.st"
a() ::= "g1 a"
b() ::= "<c()>"

|}))
    )
   (groupfiles (("c.st" {|c() ::= "c"
|})))
   (runs (((input "<c()>") (output c))))
   )
  )
 (testImportUtfTemplateFileSameDir
  ((classname hello)
   (groupfile (("group.stg" {|
import "c.st"
b() ::= "foo"
|})))
   (groupfiles (("c.st" {|c() ::= "2∏r"
|})))
   (runs (((input "<c()>") (output "2\226\136\143r"))))
   )
  )
 )