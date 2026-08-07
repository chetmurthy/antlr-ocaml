(
("TestDictionaries-testDictDefaultValue"
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
("TestDictionaries-testDictEmptyDefaultValue"
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
("TestDictionaries-testDictEmptyValueAndAngleBracketStrings"
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
("TestDictionaries-testDictHiddenByFormalArg"
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
("TestDictionaries-testDictMissingDefaultValueIsEmptyForNullKey"
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
("TestDictionaries-testDictMissingDefaultValueIsEmpty"
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
("TestDictionaries-testDictNullKeyGetsDefaultValue"
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
("TestDictionaries-testDict"
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
("TestDictionaries-testDictValuesAreTemplates"
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
("TestDictionaries-testDictDefaultIsDefaultString"
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
("TestDictionaries-testDictDefaultStringAsKey"
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
("TestDictionaries-testDictDefaultValueIsKey"
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
("TestDictionaries-testDictViaEnclosingTemplates2"
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
("TestDictionaries-testDictViaEnclosingTemplates"
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

("TestDictionaries-testDictionaryBehaviorEmptyList"
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
("TestDictionaries-testDictionaryBehaviorEmptyTemplate"
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
("TestDictionaries-testDictionaryBehaviorFalse"
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
("TestDictionaries-testDictionaryBehaviorNoNewlineTemplate"
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
("TestDictionaries-testDictionaryBehaviorTrue"
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
("TestDictionaries-testDictionarySpecialValues2"
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
("TestDictionaries-testDictionarySpecialValues3"
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
("TestDictionaries-testDictionarySpecialValues4"
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
("TestDictionaries-testDictionarySpecialValues5"
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
("TestDictionaries-testDictionarySpecialValuesOverride2"
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
("TestDictionaries-testDictionarySpecialValuesOverride3"
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
("TestDictionaries-testDictionarySpecialValuesOverride4"
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
("TestDictionaries-testDictionarySpecialValuesOverride5"
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
("TestDictionaries-testDictionarySpecialValuesOverride"
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
("TestDictionaries-testDictionarySpecialValues"
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


