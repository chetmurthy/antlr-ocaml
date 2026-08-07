(
("testDictDefaultValue"
((classname hello)
 (template_s "<var(type,name)>")
 (attributes ((type (SV (STRING UserRecord))) (name (SV (STRING x)))))
   (groupfile (("test.stg" 
                {| 
typeInit ::= ["int":"0", default:"null"] 
var(type,name) ::= "<type> <name> = <typeInit.(type)>;"
|})))
 (output "UserRecord x = null;")
)
 )
("testDictEmptyDefaultValue"
((classname hello)
 (template_s "<var(type=null,name=name)>")
 (attributes ((type (SV (STRING UserRecord))) (name (SV (STRING x)))))
   (groupfile (("test.stg" 
                {| 
typeInit ::= ["int":"0", default:] 
var(type,name) ::= "<type> <name> = <typeInit.(type)>;"
|})))
 (output " x = ;")
 (errors {bar|test.stg 2:33: missing value for key at ']'
context [anonymous] 1:10 attribute null isn't defined
|bar})
)
)
("testDictEmptyValueAndAngleBracketStrings"
((classname hello)
 (template_s "<var(type,name)>")
 (attributes ((type (SV (STRING float))) (name (SV (STRING x)))))
   (groupfile (("test.stg" 
                {| 
typeInit ::= ["int":"0", "float":, "double":<<0.0L>>] 
var(type,name) ::= "<type> <name> = <typeInit.(type)>;"
|})))
 (output "float x = ;")
 (errors {bar|test.stg 2:33: missing value for key at ','
|bar})
)
 )
("testDictHiddenByFormalArg"
((classname hello)
 (template_s "<var(typeInit=null,type=type,name=name)>")
 (attributes ((type (SV (STRING int))) (name (SV (STRING x)))))
   (groupfile (("test.stg" 
                {| 
typeInit ::= ["int":"0", "float":"0.0"] 
var(typeInit,type,name) ::= "<type> <name> = <typeInit.(type)>;"
|})))
 (output "int x = ;")
 (errors {bar|context [anonymous] 1:14 attribute null isn't defined
|bar})
)
 )
("testDictMissingDefaultValueIsEmptyForNullKey"
((classname hello)
 (template_s "<var(type,w,name)>")
 (attributes ((w (SV (STRING L))) (type (SV NULL)) (name (SV (STRING x)))))
   (groupfile (("test.stg" 
                {| 
typeInit ::= ["int":"0", "float":"0.0"] 
var(type,w,name) ::= "<type> <name> = <typeInit.(type)>;"

|})))
 (output " x = ;")
)
 )
("testDictMissingDefaultValueIsEmpty"
((classname hello)
 (template_s "<var(type,w,name)>")
 (attributes ((w (SV (STRING L))) (type (SV (STRING double))) (name (SV (STRING x)))))
   (groupfile (("test.stg" 
                {| 
typeInit ::= ["int":{0<w>}, "float":{0.0<w>}]
var(type,w,name) ::= "<type> <name> = <typeInit.(type)>;"

|})))
 (output "double x = ;")
)
 )
("testDictNullKeyGetsDefaultValue"
((classname hello)
 (template_s "<var(type=null,name=name)>")
 (attributes ((type (SV (STRING UserRecord))) (name (SV (STRING x)))))
   (groupfile (("test.stg" 
                {| 
typeInit ::= ["int":"0", default:"null"] 
var(type,name) ::= "<type> <name> = <typeInit.(type)>;"
|})))
 (output " x = null;")
 (errors {bar|context [anonymous] 1:10 attribute null isn't defined
|bar})
)
 )
("testDict"
((classname hello)
 (template_s "<var(type,name)>")
 (attributes ((type (SV (STRING int))) (name (SV (STRING x)))))
   (groupfile (("test.stg" 
                {| 
typeInit ::= ["int":"0", "float":"0.0"] 
var(type,name) ::= "<type> <name> = <typeInit.(type)>;"

|})))
 (output "int x = 0;")
)
 )
("testDictValuesAreTemplates"
((classname hello)
 (template_s "<var(type,w,name)>")
 (attributes ((w (SV (STRING L))) (type (SV (STRING int))) (name (SV (STRING x)))))
   (groupfile (("test.stg" 
                {| 
typeInit ::= ["int":{0<w>}, "float":{0.0<w>}]
var(type,w,name) ::= "<type> <name> = <typeInit.(type)>;"

|})))
 (output "int x = 0L;")
)
 )
("testDictDefaultIsDefaultString"
((classname hello)
 (template_s "<t()>")
 (attributes ((type (SV (STRING UserRecord))) (name (SV (STRING x)))))
   (groupfile (("test.stg" 
                {| 
map ::= [default: "default"] 
t() ::= << <map.("1")> >>

|})))
 (output " default ")
)
)
("testDictDefaultStringAsKey"
((classname hello)
 (template_s "<var(type,name)>")
 (attributes ((type (SV (STRING default))) (name (SV (STRING x)))))
   (groupfile (("test.stg" 
                {| 
typeInit ::= ["default":"foo"] 
var(type,name) ::= "<type> <name> = <typeInit.(type)>;"
|})))
 (output "default x = foo;")
)
)
("testDictDefaultValueIsKey"
((classname hello)
 (template_s "<var(type,name)>")
 (attributes ((type (SV (STRING UserRecord))) (name (SV (STRING x)))))
   (groupfile (("test.stg" 
                {| 
typeInit ::= ["int":"0", default:key] 
var(type,name) ::= "<type> <name> = <typeInit.(type)>;"

|})))
 (output "UserRecord x = UserRecord;")
)
)
("testDictViaEnclosingTemplates2"
((classname hello)
 (template_s "<intermediate(var(type,name))>")
 (attributes ((type (SV (STRING int))) (name (SV (STRING x)))))
   (groupfile (("test.stg" 
                {| 
typeInit ::= ["int":"0", "float":"0.0"] 
intermediate(stuff) ::= "<stuff>"
var(type,name) ::= "<type> <name> = <typeInit.(type)>;"

|})))
 (output "int x = 0;")
)
)
("testDictViaEnclosingTemplates"
((classname hello)
 (template_s "<intermediate(type,name)>")
 (attributes ((type (SV (STRING int))) (name (SV (STRING x)))))
   (groupfile (("test.stg" 
                {| 
typeInit ::= ["int":"0", "float":"0.0"] 
intermediate(type,name) ::= "<var(type,name)>"
var(type,name) ::= "<type> <name> = <typeInit.(type)>;"

|})))
 (output "int x = 0;")
)
)

("testDictionaryBehaviorEmptyList"
((classname hello)
 (template_s "<t()>")
 (attributes ())
   (groupfile (("test.stg" 
                {| 
d ::= [
   "x" : [],
   default : false
]

t() ::= <<
<d.("x")><if(d.("x"))>+<else>-<endif>
>>

|})))
 (output "-")
)
)
("testDictionaryBehaviorEmptyTemplate"
((classname hello)
 (template_s "<t()>")
 (attributes ())
   (groupfile (("test.stg" 
                {| 
d ::= [
   "x" : {},
   default : false,
]

t() ::= <<
<d.("x")><if(d.("x"))>+<else>-<endif>
>>

|})))
 (output "+")
 (errors {bar|test.stg 4:18: extraneous input ',' expecting RBRACK
|bar})
)
)
("testDictionaryBehaviorFalse"
((classname hello)
 (template_s "<t()>")
 (attributes ())
   (groupfile (("test.stg" 
                {| 
d ::= [
   "x" : false,
   default : false,
]

t() ::= <<
<d.("x")><if(d.("x"))>+<else>-<endif>
>>

|})))
 (output "false-")
 (errors {bar|test.stg 4:18: extraneous input ',' expecting RBRACK
|bar})
)
)
("testDictionaryBehaviorNoNewlineTemplate"
((classname hello)
 (template_s "<t()>")
 (attributes ())
   (groupfile (("test.stg" 
                {| 
d ::= [
   "x" : <%hi%>
]

t() ::= <<
<d.x>
>>

|})))
 (output "hi")
)
)
("testDictionaryBehaviorTrue"
((classname hello)
 (template_s "<t()>")
 (attributes ())
   (groupfile (("test.stg" 
                {| 
d ::= [
   "x" : true,
   default : false,
]

t() ::= <<
<d.("x")><if(d.("x"))>+<else>-<endif>
>>

|})))
 (output "true+")
 (errors {bar|test.stg 4:18: extraneous input ',' expecting RBRACK
|bar})
)
)
("testDictionarySpecialValues2"
((classname hello)
 (template_s "<t(id)>")
 (attributes ((id (SV (STRING nonkeyword)))))
   (groupfile (("test.stg" 
                {| 
t(id) ::= <<
<identifier.(id)>
>>

identifier ::= [
   "keyword" : "@keyword",
   default : key
]

|})))
 (output "nonkeyword")
)
)
("testDictionarySpecialValues3"
((classname hello)
 (template_s "<t(id)>")
 (attributes ((id (SV (STRING default)))))
   (groupfile (("test.stg" 
                {| 
t(id) ::= <<
<identifier.(id)>
>>

identifier ::= [
   "keyword" : "@keyword",
   default : key
]

|})))
 (output "default")
)
)
("testDictionarySpecialValues4"
((classname hello)
 (template_s "<t(id)>")
 (attributes ((id (SV (STRING keys)))))
   (groupfile (("test.stg" 
                {| 
t(id) ::= <<
<identifier.(id)>
>>

identifier ::= [
   "keyword" : "@keyword",
   default : key
]

|})))
 (output "keyworddefault")
)
)
("testDictionarySpecialValues5"
((classname hello)
 (template_s "<t(id)>")
 (attributes ((id (SV (STRING values)))))
   (groupfile (("test.stg" 
                {| 
t(id) ::= <<
<identifier.(id)>
>>

identifier ::= [
   "keyword" : "@keyword",
   default : key
]

|})))
 (output "@keywordkey")
)
)
("testDictionarySpecialValuesOverride2"
((classname hello)
 (template_s "<t(id)>")
 (attributes ((id (SV (STRING nonkeyword)))))
   (groupfile (("test.stg" 
                {| 
t(id) ::= <<
<identifier.(id)>
>>

identifier ::= [
   "keyword" : "@keyword",
   "keys" : "keys",
   "values" : "values",
   default : key
]

|})))
 (output "nonkeyword")
)
)
("testDictionarySpecialValuesOverride3"
((classname hello)
 (template_s "<t(id)>")
 (attributes ((id (SV (STRING default)))))
   (groupfile (("test.stg" 
                {| 
t(id) ::= <<
<identifier.(id)>
>>

identifier ::= [
   "keyword" : "@keyword",
   "keys" : "keys",
   "values" : "values",
   default : key
]

|})))
 (output "default")
)
)
("testDictionarySpecialValuesOverride4"
((classname hello)
 (template_s "<t(id)>")
 (attributes ((id (SV (STRING keys)))))
   (groupfile (("test.stg" 
                {| 
t(id) ::= <<
<identifier.(id)>
>>

identifier ::= [
   "keyword" : "@keyword",
   "keys" : "keys",
   "values" : "values",
   default : key
]

|})))
 (output "keys")
)
)
("testDictionarySpecialValuesOverride5"
((classname hello)
 (template_s "<t(id)>")
 (attributes ((id (SV (STRING values)))))
   (groupfile (("test.stg" 
                {| 
t(id) ::= <<
<identifier.(id)>
>>

identifier ::= [
   "keyword" : "@keyword",
   "keys" : "keys",
   "values" : "values",
   default : key
]

|})))
 (output "values")
)
)
("testDictionarySpecialValuesOverride"
((classname hello)
 (template_s "<t(id)>")
 (attributes ((id (SV (STRING keyword)))))
   (groupfile (("test.stg" 
                {| 
t(id) ::= <<
<identifier.(id)>
>>

identifier ::= [
   "keyword" : "@keyword",
   "keys" : "keys",
   "values" : "values",
   default : key
]

|})))
 (output "@keyword")
)
)
("testDictionarySpecialValues"
((classname hello)
 (template_s "<t(id)>")
 (attributes ((id (SV (STRING keyword)))))
   (groupfile (("test.stg" 
                {| 
t(id) ::= <<
<identifier.(id)>
>>

identifier ::= [
   "keyword" : "@keyword",
   default : key
]

|})))
 (output "@keyword")
)
)
)


