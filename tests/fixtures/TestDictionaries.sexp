((testDictDefaultValue
  ((classname hello)
   (groupfile
    (("test.stg"
      {| 
typeInit ::= ["int":"0", default:"null"] 
var(type,name) ::= "<type> <name> = <typeInit.(type)>;"
|}
      ))
    )
   (runs
    (((input "<var(type,name)>")
      (output "UserRecord x = null;")
      (attributes ((type (SV (STRING UserRecord))) (name (SV (STRING x)))))
      ))
    )
   )
  )
 (testDictEmptyDefaultValue
  ((classname hello)
   (groupfile
    (("test.stg"
      {| 
typeInit ::= ["int":"0", default:] 
var(type,name) ::= "<type> <name> = <typeInit.(type)>;"
|}
      ))
    )
   (runs
    (((input "<var(type=null,name=name)>")
      (output " x = ;")
      (attributes ((type (SV (STRING UserRecord))) (name (SV (STRING x)))))
      ))
    )
   (errors
    {|test.stg 2:33: missing value for key at ']'
context [anonymous] 1:10 attribute null isn't defined
|}
    )
   )
  )
 (testDictEmptyValueAndAngleBracketStrings
  ((classname hello)
   (groupfile
    (("test.stg"
      {| 
typeInit ::= ["int":"0", "float":, "double":<<0.0L>>] 
var(type,name) ::= "<type> <name> = <typeInit.(type)>;"
|}
      ))
    )
   (runs
    (((input "<var(type,name)>")
      (output "float x = ;")
      (attributes ((type (SV (STRING float))) (name (SV (STRING x)))))
      ))
    )
   (errors {|test.stg 2:33: missing value for key at ','
|})
   )
  )
 (testDictHiddenByFormalArg
  ((classname hello)
   (groupfile
    (("test.stg"
      {| 
typeInit ::= ["int":"0", "float":"0.0"] 
var(typeInit,type,name) ::= "<type> <name> = <typeInit.(type)>;"
|}
      ))
    )
   (runs
    (((input "<var(typeInit=null,type=type,name=name)>")
      (output "int x = ;")
      (attributes ((type (SV (STRING int))) (name (SV (STRING x)))))
      ))
    )
   (errors {|context [anonymous] 1:14 attribute null isn't defined
|})
   )
  )
 (testDictMissingDefaultValueIsEmptyForNullKey
  ((classname hello)
   (groupfile
    (("test.stg"
      {| 
typeInit ::= ["int":"0", "float":"0.0"] 
var(type,w,name) ::= "<type> <name> = <typeInit.(type)>;"

|}
      ))
    )
   (runs
    (((input "<var(type,w,name)>")
      (output " x = ;")
      (attributes
       ((w (SV (STRING L))) (type (SV NULL)) (name (SV (STRING x))))
       )
      ))
    )
   )
  )
 (testDictMissingDefaultValueIsEmpty
  ((classname hello)
   (groupfile
    (("test.stg"
      {| 
typeInit ::= ["int":{0<w>}, "float":{0.0<w>}]
var(type,w,name) ::= "<type> <name> = <typeInit.(type)>;"

|}
      ))
    )
   (runs
    (((input "<var(type,w,name)>")
      (output "double x = ;")
      (attributes
       ((w (SV (STRING L)))
        (type (SV (STRING double)))
        (name (SV (STRING x)))
        )
       )
      ))
    )
   )
  )
 (testDictNullKeyGetsDefaultValue
  ((classname hello)
   (groupfile
    (("test.stg"
      {| 
typeInit ::= ["int":"0", default:"null"] 
var(type,name) ::= "<type> <name> = <typeInit.(type)>;"
|}
      ))
    )
   (runs
    (((input "<var(type=null,name=name)>")
      (output " x = null;")
      (attributes ((type (SV (STRING UserRecord))) (name (SV (STRING x)))))
      ))
    )
   (errors {|context [anonymous] 1:10 attribute null isn't defined
|})
   )
  )
 (testDict
  ((classname hello)
   (groupfile
    (("test.stg"
      {| 
typeInit ::= ["int":"0", "float":"0.0"] 
var(type,name) ::= "<type> <name> = <typeInit.(type)>;"

|}
      ))
    )
   (runs
    (((input "<var(type,name)>")
      (output "int x = 0;")
      (attributes ((type (SV (STRING int))) (name (SV (STRING x)))))
      ))
    )
   )
  )
 (testDictValuesAreTemplates
  ((classname hello)
   (groupfile
    (("test.stg"
      {| 
typeInit ::= ["int":{0<w>}, "float":{0.0<w>}]
var(type,w,name) ::= "<type> <name> = <typeInit.(type)>;"

|}
      ))
    )
   (runs
    (((input "<var(type,w,name)>")
      (output "int x = 0L;")
      (attributes
       ((w (SV (STRING L))) (type (SV (STRING int))) (name (SV (STRING x))))
       )
      ))
    )
   )
  )
 (testDictDefaultIsDefaultString
  ((classname hello)
   (groupfile
    (("test.stg"
      {| 
map ::= [default: "default"] 
t() ::= << <map.("1")> >>

|}
      ))
    )
   (runs
    (((input "<t()>")
      (output " default ")
      (attributes ((type (SV (STRING UserRecord))) (name (SV (STRING x)))))
      ))
    )
   )
  )
 (testDictDefaultStringAsKey
  ((classname hello)
   (groupfile
    (("test.stg"
      {| 
typeInit ::= ["default":"foo"] 
var(type,name) ::= "<type> <name> = <typeInit.(type)>;"
|}
      ))
    )
   (runs
    (((input "<var(type,name)>")
      (output "default x = foo;")
      (attributes ((type (SV (STRING default))) (name (SV (STRING x)))))
      ))
    )
   )
  )
 (testDictDefaultValueIsKey
  ((classname hello)
   (groupfile
    (("test.stg"
      {| 
typeInit ::= ["int":"0", default:key] 
var(type,name) ::= "<type> <name> = <typeInit.(type)>;"

|}
      ))
    )
   (runs
    (((input "<var(type,name)>")
      (output "UserRecord x = UserRecord;")
      (attributes ((type (SV (STRING UserRecord))) (name (SV (STRING x)))))
      ))
    )
   )
  )
 (testDictViaEnclosingTemplates2
  ((classname hello)
   (groupfile
    (("test.stg"
      {| 
typeInit ::= ["int":"0", "float":"0.0"] 
intermediate(stuff) ::= "<stuff>"
var(type,name) ::= "<type> <name> = <typeInit.(type)>;"

|}
      ))
    )
   (runs
    (((input "<intermediate(var(type,name))>")
      (output "int x = 0;")
      (attributes ((type (SV (STRING int))) (name (SV (STRING x)))))
      ))
    )
   )
  )
 (testDictViaEnclosingTemplates
  ((classname hello)
   (groupfile
    (("test.stg"
      {| 
typeInit ::= ["int":"0", "float":"0.0"] 
intermediate(type,name) ::= "<var(type,name)>"
var(type,name) ::= "<type> <name> = <typeInit.(type)>;"

|}
      ))
    )
   (runs
    (((input "<intermediate(type,name)>")
      (output "int x = 0;")
      (attributes ((type (SV (STRING int))) (name (SV (STRING x)))))
      ))
    )
   )
  )
 (testDictionaryBehaviorEmptyList
  ((classname hello)
   (groupfile
    (("test.stg"
      {| 
d ::= [
   "x" : [],
   default : false
]

t() ::= <<
<d.("x")><if(d.("x"))>+<else>-<endif>
>>

|}
      ))
    )
   (runs (((input "<t()>") (output "-"))))
   )
  )
 (testDictionaryBehaviorEmptyTemplate
  ((classname hello)
   (groupfile
    (("test.stg"
      {| 
d ::= [
   "x" : {},
   default : false,
]

t() ::= <<
<d.("x")><if(d.("x"))>+<else>-<endif>
>>

|}
      ))
    )
   (runs (((input "<t()>") (output "+"))))
   (errors {|test.stg 4:18: extraneous input ',' expecting RBRACK
|})
   )
  )
 (testDictionaryBehaviorFalse
  ((classname hello)
   (groupfile
    (("test.stg"
      {| 
d ::= [
   "x" : false,
   default : false,
]

t() ::= <<
<d.("x")><if(d.("x"))>+<else>-<endif>
>>

|}
      ))
    )
   (runs (((input "<t()>") (output "false-"))))
   (errors {|test.stg 4:18: extraneous input ',' expecting RBRACK
|})
   )
  )
 (testDictionaryBehaviorNoNewlineTemplate
  ((classname hello)
   (groupfile
    (("test.stg" {| 
d ::= [
   "x" : <%hi%>
]

t() ::= <<
<d.x>
>>

|}))
    )
   (runs (((input "<t()>") (output hi))))
   )
  )
 (testDictionaryBehaviorTrue
  ((classname hello)
   (groupfile
    (("test.stg"
      {| 
d ::= [
   "x" : true,
   default : false,
]

t() ::= <<
<d.("x")><if(d.("x"))>+<else>-<endif>
>>

|}
      ))
    )
   (runs (((input "<t()>") (output "true+"))))
   (errors {|test.stg 4:18: extraneous input ',' expecting RBRACK
|})
   )
  )
 (testDictionarySpecialValues2
  ((classname hello)
   (groupfile
    (("test.stg"
      {| 
t(id) ::= <<
<identifier.(id)>
>>

identifier ::= [
   "keyword" : "@keyword",
   default : key
]

|}
      ))
    )
   (runs
    (((input "<t(id)>")
      (output nonkeyword)
      (attributes ((id (SV (STRING nonkeyword)))))
      ))
    )
   )
  )
 (testDictionarySpecialValues3
  ((classname hello)
   (groupfile
    (("test.stg"
      {| 
t(id) ::= <<
<identifier.(id)>
>>

identifier ::= [
   "keyword" : "@keyword",
   default : key
]

|}
      ))
    )
   (runs
    (((input "<t(id)>")
      (output default)
      (attributes ((id (SV (STRING default)))))
      ))
    )
   )
  )
 (testDictionarySpecialValues4
  ((classname hello)
   (groupfile
    (("test.stg"
      {| 
t(id) ::= <<
<identifier.(id)>
>>

identifier ::= [
   "keyword" : "@keyword",
   default : key
]

|}
      ))
    )
   (runs
    (((input "<t(id)>")
      (output keyworddefault)
      (attributes ((id (SV (STRING keys)))))
      ))
    )
   )
  )
 (testDictionarySpecialValues5
  ((classname hello)
   (groupfile
    (("test.stg"
      {| 
t(id) ::= <<
<identifier.(id)>
>>

identifier ::= [
   "keyword" : "@keyword",
   default : key
]

|}
      ))
    )
   (runs
    (((input "<t(id)>")
      (output "@keywordkey")
      (attributes ((id (SV (STRING values)))))
      ))
    )
   )
  )
 (testDictionarySpecialValuesOverride2
  ((classname hello)
   (groupfile
    (("test.stg"
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

|}
      ))
    )
   (runs
    (((input "<t(id)>")
      (output nonkeyword)
      (attributes ((id (SV (STRING nonkeyword)))))
      ))
    )
   )
  )
 (testDictionarySpecialValuesOverride3
  ((classname hello)
   (groupfile
    (("test.stg"
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

|}
      ))
    )
   (runs
    (((input "<t(id)>")
      (output default)
      (attributes ((id (SV (STRING default)))))
      ))
    )
   )
  )
 (testDictionarySpecialValuesOverride4
  ((classname hello)
   (groupfile
    (("test.stg"
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

|}
      ))
    )
   (runs
    (((input "<t(id)>") (output keys) (attributes ((id (SV (STRING keys)))))))
    )
   )
  )
 (testDictionarySpecialValuesOverride5
  ((classname hello)
   (groupfile
    (("test.stg"
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

|}
      ))
    )
   (runs
    (((input "<t(id)>")
      (output values)
      (attributes ((id (SV (STRING values)))))
      ))
    )
   )
  )
 (testDictionarySpecialValuesOverride
  ((classname hello)
   (groupfile
    (("test.stg"
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

|}
      ))
    )
   (runs
    (((input "<t(id)>")
      (output "@keyword")
      (attributes ((id (SV (STRING keyword)))))
      ))
    )
   )
  )
 (testDictionarySpecialValues
  ((classname hello)
   (groupfile
    (("test.stg"
      {| 
t(id) ::= <<
<identifier.(id)>
>>

identifier ::= [
   "keyword" : "@keyword",
   default : key
]

|}
      ))
    )
   (runs
    (((input "<t(id)>")
      (output "@keyword")
      (attributes ((id (SV (STRING keyword)))))
      ))
    )
   )
  )
 )