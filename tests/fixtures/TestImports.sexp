(
("testEmptyGroupImportGroupFileSameDir"
((classname hello)
 (template_s {foo|<c()>|foo})
 (attributes ())
 (groupfile (("group1.stg"
                {| 
import "group2.stg"
|})
    ))
 (groupfiles (
   ("group2.stg" "c() ::= \"g2 c\"\n")
 ))
 (output "g2 c")
 (errors "")
)
)
("testGroupFileInDirImportsAGroupDir"
((classname hello)
 (template_s {foo|<a()>|foo})
 (attributes ())
 (groupfile (("g.stg" {|
import "subdir"
a() ::= "a: <b()>"
|})))
 (groupfiles (
   ("subdir/b.st" "b() ::= \"b: <c()>\"\n")
   ("subdir/c.st" "c() ::= <<subdir c>>\n")
 ))
 (output "a: b: subdir c")
)
)
("testGroupFileInDirImportsAnotherGroupFile"
((classname hello)
 (template_s {foo|</group/a()>|foo})
 (attributes ())
 (groupfiles (
   ("group.stg" {|
import "imported.stg"
a() ::= "a: <b()>"
|})
   ("imported.stg" "b() ::= \"b\"\n")
 ))
 (output "")
 (errorsContains "import illegal in group files embedded in STGroupDirs; import \"imported.stg\" in STGroupDir")
)
)
("testImportDir"
((classname hello)
 (template_s {foo|<b()>|foo})
 (attributes ())
 (groupfile (("root/dir1/g.stg"
                {| 
import "root/dir2"
a() ::= <<dir1 a>>

|})
    ))
 (groupfiles (
   ("root/dir2/a.st" "a() ::= <<dir2 a>>\n")
   ("root/dir2/b.st" "b() ::= <<dir2 b>>\n")
 ))
 (output "dir2 b")
 (errors "")
)
)
("testImportGroupFileSameDir"
((classname hello)
 (template_s {foo|<c()>|foo})
 (attributes ())
 (groupfile (("group1.stg"
                {| 
import "group2.stg"
a() ::= "g1 a"
b() ::= "<c()>"
|})
    ))
 (groupfiles (
   ("group2.stg" "c() ::= \"g2 c\"\n")
 ))
 (output "g2 c")
 (errors "")
)
)
("testImportRelativeDir2"
((classname hello)
 (template_s {foo|<c()>|foo})
 (attributes ())
 (groupfile (("root/g.stg"
                {| 
import "subdir"
a() ::= <<dir1 a>>
|})
    ))
 (groupfiles (
   ("root/subdir/a.st" "a() ::= <<subdir a>>\n")
   ("root/subdir/b.st" "b() ::= <<subdir b>>\n")
   ("root/subdir/c.st" "c() ::= <<subdir c>>\n")
 ))
 (output "subdir c")
 (errors "")
)
)
("testImportRelativeDir"
((classname hello)
 (template_s {foo|<b()>|foo})
 (attributes ())
 (groupfile (("root/g.stg"
                {| 
import "subdir"
a() ::= <<dir1 a>>
|})
    ))
 (groupfiles (
   ("root/subdir/a.st" "a() ::= <<subdir a>>\n")
   ("root/subdir/b.st" "b() ::= <<subdir b>>\n")
   ("root/subdir/c.st" "c() ::= <<subdir c>>\n")
 ))
 (output "subdir b")
 (errors "")
)
)
("testImportRelativeGroupFile"
((classname hello)
 (template_s {foo|<c()>|foo})
 (attributes ())
 (groupfile (("group1.stg"
                {| 
import "subdir/group2.stg"
a() ::= "g1 a"
b() ::= "<c()>"

|})
    ))
 (groupfiles (
   ("subdir/group2.stg" "c() ::= \"g2 c\"\n")
 ))
 (output "g2 c")
 (errors "")
)
)
("testImportRelativeTemplateFile"
((classname hello)
 (template_s {foo|<c()>|foo})
 (attributes ())
 (groupfile (("group1.stg"
                {| 
import "subdir/c.st"
a() ::= "g1 a"
b() ::= "<c()>"

|})
    ))
 (groupfiles (
   ("subdir/c.st" "c() ::= \"c\"\n")
 ))
 (output "c")
 (errors "")
)
)
("testImportTemplateFileSameDir"
((classname hello)
 (template_s {foo|<c()>|foo})
 (attributes ())
 (groupfile (("group1.stg"
                {| 
import "c.st"
a() ::= "g1 a"
b() ::= "<c()>"

|})
    ))
 (groupfiles (
   ("c.st" "c() ::= \"c\"\n")
 ))
 (output "c")
 (errors "")
)
)
("testImportUtfTemplateFileSameDir"
((classname hello)
 (template_s {foo|<c()>|foo})
 (attributes ())
 (groupfile (("group.stg" {|
import "c.st"
b() ::= "foo"
|})))
 (groupfiles (
   ("c.st" "c() ::= \"2∏r\"\n")
 ))
 (output "2∏r")
)
)
)
