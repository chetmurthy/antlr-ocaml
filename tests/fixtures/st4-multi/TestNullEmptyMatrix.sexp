((single00
  ((classname hello)
   (groupfile
    (("t.stg" {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x>"
|}))
    )
   (runs (((input "<test(x)>"))))
   (errors {|context [anonymous] 1:6 attribute x isn't defined
|})
   )
  )
 (single01
  ((classname hello)
   (groupfile
    (("t.stg" {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x>"
|}))
    )
   (runs (((input "<test(x)>") (attributes ((x (SV NULL)))))))
   )
  )
 (single02
  ((classname hello)
   (groupfile
    (("t.stg" {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x>"
|}))
    )
   (runs (((input "<test(x)>") (attributes ((x (SV (STRING ""))))))))
   )
  )
 (single03
  ((classname hello)
   (groupfile
    (("t.stg" {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x>"
|}))
    )
   (runs (((input "<test(x)>") (attributes ((x (SV (LIST ()))))))))
   )
  )
 (single04
  ((classname hello)
   (groupfile
    (("t.stg" {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:t()>"
|}))
    )
   (runs (((input "<test(x)>"))))
   (errors {|context [anonymous] 1:6 attribute x isn't defined
|})
   )
  )
 (single05
  ((classname hello)
   (groupfile
    (("t.stg" {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:t()>"
|}))
    )
   (runs (((input "<test(x)>") (attributes ((x (SV NULL)))))))
   )
  )
 (single06
  ((classname hello)
   (groupfile
    (("t.stg" {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:t()>"
|}))
    )
   (runs (((input "<test(x)>") (attributes ((x (SV (STRING ""))))))))
   )
  )
 (single07
  ((classname hello)
   (groupfile
    (("t.stg" {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:t()>"
|}))
    )
   (runs (((input "<test(x)>") (attributes ((x (SV (LIST ()))))))))
   )
  )
 (single08
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x; null={y}>"
|}
      ))
    )
   (runs (((input "<test(x)>") (output y))))
   (errors {|context [anonymous] 1:6 attribute x isn't defined
|})
   )
  )
 (single09
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x; null={y}>"
|}
      ))
    )
   (runs (((input "<test(x)>") (output y) (attributes ((x (SV NULL)))))))
   )
  )
 (single10
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x; null={y}>"
|}
      ))
    )
   (runs (((input "<test(x)>") (attributes ((x (SV (STRING ""))))))))
   )
  )
 (single11
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x; null={y}>"
|}
      ))
    )
   (runs (((input "<test(x)>") (attributes ((x (SV (LIST ()))))))))
   )
  )
 (single12
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:t(); null={y}>"
|}
      ))
    )
   (runs (((input "<test(x)>") (output y))))
   (errors {|context [anonymous] 1:6 attribute x isn't defined
|})
   )
  )
 (single13
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:t(); null={y}>"
|}
      ))
    )
   (runs (((input "<test(x)>") (output y) (attributes ((x (SV NULL)))))))
   )
  )
 (single14
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:t(); null={y}>"
|}
      ))
    )
   (runs (((input "<test(x)>") (attributes ((x (SV (STRING ""))))))))
   )
  )
 (single15
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:t(); null={y}>"
|}
      ))
    )
   (runs (((input "<test(x)>") (attributes ((x (SV (LIST ()))))))))
   )
  )
 (single16
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<if(x)>y<endif>"
|}
      ))
    )
   (runs (((input "<test(x)>"))))
   (errors {|context [anonymous] 1:6 attribute x isn't defined
|})
   )
  )
 (single17
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<if(x)>y<endif>"
|}
      ))
    )
   (runs (((input "<test(x)>") (attributes ((x (SV NULL)))))))
   )
  )
 (single18
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<if(x)>y<endif>"
|}
      ))
    )
   (runs
    (((input "<test(x)>") (output y) (attributes ((x (SV (STRING "")))))))
    )
   )
  )
 (single19
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<if(x)>y<endif>"
|}
      ))
    )
   (runs (((input "<test(x)>") (attributes ((x (SV (LIST ()))))))))
   )
  )
 (single20
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<if(x)>y<else>z<endif>"
|}
      ))
    )
   (runs (((input "<test(x)>") (output z))))
   (errors {|context [anonymous] 1:6 attribute x isn't defined
|})
   )
  )
 (single21
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<if(x)>y<else>z<endif>"
|}
      ))
    )
   (runs (((input "<test(x)>") (output z) (attributes ((x (SV NULL)))))))
   )
  )
 (single22
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<if(x)>y<else>z<endif>"
|}
      ))
    )
   (runs
    (((input "<test(x)>") (output y) (attributes ((x (SV (STRING "")))))))
    )
   )
  )
 (single23
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<if(x)>y<else>z<endif>"
|}
      ))
    )
   (runs
    (((input "<test(x)>") (output z) (attributes ((x (SV (LIST ())))))))
    )
   )
  )
 (multi00
  ((classname hello)
   (groupfile
    (("t.stg" {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x>"
|}))
    )
   (runs (((input "<test(x)>") (attributes ((x (SV (LIST ()))))))))
   )
  )
 (multi01
  ((classname hello)
   (groupfile
    (("t.stg" {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x>"
|}))
    )
   (runs
    (((input "<test(x)>")
      (output a)
      (attributes ((x (SV (LIST ((STRING a)))))))
      ))
    )
   )
  )
 (multi02
  ((classname hello)
   (groupfile
    (("t.stg" {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x>"
|}))
    )
   (runs
    (((input "<test(x)>")
      (output ab)
      (attributes ((x (SV (LIST ((STRING a) (STRING b)))))))
      ))
    )
   )
  )
 (multi03
  ((classname hello)
   (groupfile
    (("t.stg" {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x>"
|}))
    )
   (runs (((input "<test(x)>") (attributes ((x (SV (LIST (NULL)))))))))
   )
  )
 (multi04
  ((classname hello)
   (groupfile
    (("t.stg" {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x>"
|}))
    )
   (runs
    (((input "<test(x)>")
      (output b)
      (attributes ((x (SV (LIST (NULL (STRING b)))))))
      ))
    )
   )
  )
 (multi05
  ((classname hello)
   (groupfile
    (("t.stg" {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x>"
|}))
    )
   (runs
    (((input "<test(x)>")
      (output a)
      (attributes ((x (SV (LIST ((STRING a) NULL))))))
      ))
    )
   )
  )
 (multi06
  ((classname hello)
   (groupfile
    (("t.stg" {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x>"
|}))
    )
   (runs
    (((input "<test(x)>")
      (output ab)
      (attributes ((x (SV (LIST ((STRING a) NULL (STRING b)))))))
      ))
    )
   )
  )
 (multi07
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x; null={y}>"
|}
      ))
    )
   (runs (((input "<test(x)>") (attributes ((x (SV (LIST ()))))))))
   )
  )
 (multi08
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x; null={y}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output a)
      (attributes ((x (SV (LIST ((STRING a)))))))
      ))
    )
   )
  )
 (multi09
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x; null={y}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output ab)
      (attributes ((x (SV (LIST ((STRING a) (STRING b)))))))
      ))
    )
   )
  )
 (multi10
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x; null={y}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>") (output y) (attributes ((x (SV (LIST (NULL))))))))
    )
   )
  )
 (multi11
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x; null={y}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output yb)
      (attributes ((x (SV (LIST (NULL (STRING b)))))))
      ))
    )
   )
  )
 (multi12
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x; null={y}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output ay)
      (attributes ((x (SV (LIST ((STRING a) NULL))))))
      ))
    )
   )
  )
 (multi13
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x; null={y}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output ayb)
      (attributes ((x (SV (LIST ((STRING a) NULL (STRING b)))))))
      ))
    )
   )
  )
 (multi14
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x; separator={,}>"
|}
      ))
    )
   (runs (((input "<test(x)>") (attributes ((x (SV (LIST ()))))))))
   )
  )
 (multi15
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x; separator={,}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output a)
      (attributes ((x (SV (LIST ((STRING a)))))))
      ))
    )
   )
  )
 (multi16
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x; separator={,}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output "a,b")
      (attributes ((x (SV (LIST ((STRING a) (STRING b)))))))
      ))
    )
   )
  )
 (multi17
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x; separator={,}>"
|}
      ))
    )
   (runs (((input "<test(x)>") (attributes ((x (SV (LIST (NULL)))))))))
   )
  )
 (multi18
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x; separator={,}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output b)
      (attributes ((x (SV (LIST (NULL (STRING b)))))))
      ))
    )
   )
  )
 (multi19
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x; separator={,}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output a)
      (attributes ((x (SV (LIST ((STRING a) NULL))))))
      ))
    )
   )
  )
 (multi20
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x; separator={,}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output "a,b")
      (attributes ((x (SV (LIST ((STRING a) NULL (STRING b)))))))
      ))
    )
   )
  )
 (multi21
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x; null={y}, separator={,}>"
|}
      ))
    )
   (runs (((input "<test(x)>") (attributes ((x (SV (LIST ()))))))))
   )
  )
 (multi22
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x; null={y}, separator={,}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output a)
      (attributes ((x (SV (LIST ((STRING a)))))))
      ))
    )
   )
  )
 (multi23
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x; null={y}, separator={,}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output "a,b")
      (attributes ((x (SV (LIST ((STRING a) (STRING b)))))))
      ))
    )
   )
  )
 (multi24
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x; null={y}, separator={,}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>") (output y) (attributes ((x (SV (LIST (NULL))))))))
    )
   )
  )
 (multi25
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x; null={y}, separator={,}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output "y,b")
      (attributes ((x (SV (LIST (NULL (STRING b)))))))
      ))
    )
   )
  )
 (multi26
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x; null={y}, separator={,}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output "a,y")
      (attributes ((x (SV (LIST ((STRING a) NULL))))))
      ))
    )
   )
  )
 (multi27
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x; null={y}, separator={,}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output "a,y,b")
      (attributes ((x (SV (LIST ((STRING a) NULL (STRING b)))))))
      ))
    )
   )
  )
 (multi28
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<if(x)>y<endif>"
|}
      ))
    )
   (runs (((input "<test(x)>") (attributes ((x (SV (LIST ()))))))))
   )
  )
 (multi29
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<if(x)>y<endif>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output y)
      (attributes ((x (SV (LIST ((STRING a)))))))
      ))
    )
   )
  )
 (multi30
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<if(x)>y<endif>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output y)
      (attributes ((x (SV (LIST ((STRING a) (STRING b)))))))
      ))
    )
   )
  )
 (multi31
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<if(x)>y<endif>"
|}
      ))
    )
   (runs
    (((input "<test(x)>") (output y) (attributes ((x (SV (LIST (NULL))))))))
    )
   )
  )
 (multi32
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<if(x)>y<endif>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output y)
      (attributes ((x (SV (LIST (NULL (STRING b)))))))
      ))
    )
   )
  )
 (multi33
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<if(x)>y<endif>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output y)
      (attributes ((x (SV (LIST ((STRING a) NULL))))))
      ))
    )
   )
  )
 (multi34
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<if(x)>y<endif>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output y)
      (attributes ((x (SV (LIST ((STRING a) NULL (STRING b)))))))
      ))
    )
   )
  )
 (multi35
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | <it>}>"
|}
      ))
    )
   (runs (((input "<test(x)>") (attributes ((x (SV (LIST ()))))))))
   )
  )
 (multi36
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | <it>}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output a)
      (attributes ((x (SV (LIST ((STRING a)))))))
      ))
    )
   )
  )
 (multi37
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | <it>}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output ab)
      (attributes ((x (SV (LIST ((STRING a) (STRING b)))))))
      ))
    )
   )
  )
 (multi38
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | <it>}>"
|}
      ))
    )
   (runs (((input "<test(x)>") (attributes ((x (SV (LIST (NULL)))))))))
   )
  )
 (multi39
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | <it>}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output b)
      (attributes ((x (SV (LIST (NULL (STRING b)))))))
      ))
    )
   )
  )
 (multi40
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | <it>}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output a)
      (attributes ((x (SV (LIST ((STRING a) NULL))))))
      ))
    )
   )
  )
 (multi41
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | <it>}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output ab)
      (attributes ((x (SV (LIST ((STRING a) NULL (STRING b)))))))
      ))
    )
   )
  )
 (multi42
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | <it>}; null={y}>"
|}
      ))
    )
   (runs (((input "<test(x)>") (attributes ((x (SV (LIST ()))))))))
   )
  )
 (multi43
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | <it>}; null={y}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output a)
      (attributes ((x (SV (LIST ((STRING a)))))))
      ))
    )
   )
  )
 (multi44
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | <it>}; null={y}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output ab)
      (attributes ((x (SV (LIST ((STRING a) (STRING b)))))))
      ))
    )
   )
  )
 (multi45
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | <it>}; null={y}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>") (output y) (attributes ((x (SV (LIST (NULL))))))))
    )
   )
  )
 (multi46
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | <it>}; null={y}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output yb)
      (attributes ((x (SV (LIST (NULL (STRING b)))))))
      ))
    )
   )
  )
 (multi47
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | <it>}; null={y}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output ay)
      (attributes ((x (SV (LIST ((STRING a) NULL))))))
      ))
    )
   )
  )
 (multi48
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | <it>}; null={y}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output ayb)
      (attributes ((x (SV (LIST ((STRING a) NULL (STRING b)))))))
      ))
    )
   )
  )
 (multi49
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | <i>.<it>}>"
|}
      ))
    )
   (runs (((input "<test(x)>") (attributes ((x (SV (LIST ()))))))))
   )
  )
 (multi50
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | <i>.<it>}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output "1.a")
      (attributes ((x (SV (LIST ((STRING a)))))))
      ))
    )
   )
  )
 (multi51
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | <i>.<it>}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output "1.a2.b")
      (attributes ((x (SV (LIST ((STRING a) (STRING b)))))))
      ))
    )
   )
  )
 (multi52
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | <i>.<it>}>"
|}
      ))
    )
   (runs (((input "<test(x)>") (attributes ((x (SV (LIST (NULL)))))))))
   )
  )
 (multi53
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | <i>.<it>}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output "1.b")
      (attributes ((x (SV (LIST (NULL (STRING b)))))))
      ))
    )
   )
  )
 (multi54
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | <i>.<it>}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output "1.a")
      (attributes ((x (SV (LIST ((STRING a) NULL))))))
      ))
    )
   )
  )
 (multi55
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | <i>.<it>}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output "1.a2.b")
      (attributes ((x (SV (LIST ((STRING a) NULL (STRING b)))))))
      ))
    )
   )
  )
 (multi56
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | <i>.<it>}; null={y}>"
|}
      ))
    )
   (runs (((input "<test(x)>") (attributes ((x (SV (LIST ()))))))))
   )
  )
 (multi57
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | <i>.<it>}; null={y}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output "1.a")
      (attributes ((x (SV (LIST ((STRING a)))))))
      ))
    )
   )
  )
 (multi58
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | <i>.<it>}; null={y}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output "1.a2.b")
      (attributes ((x (SV (LIST ((STRING a) (STRING b)))))))
      ))
    )
   )
  )
 (multi59
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | <i>.<it>}; null={y}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>") (output y) (attributes ((x (SV (LIST (NULL))))))))
    )
   )
  )
 (multi60
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | <i>.<it>}; null={y}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output "y1.b")
      (attributes ((x (SV (LIST (NULL (STRING b)))))))
      ))
    )
   )
  )
 (multi61
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | <i>.<it>}; null={y}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output "1.ay")
      (attributes ((x (SV (LIST ((STRING a) NULL))))))
      ))
    )
   )
  )
 (multi62
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | <i>.<it>}; null={y}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output "1.ay2.b")
      (attributes ((x (SV (LIST ((STRING a) NULL (STRING b)))))))
      ))
    )
   )
  )
 (multi63
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | x<if(!it)>y<endif>}; null={z}>"
|}
      ))
    )
   (runs (((input "<test(x)>") (attributes ((x (SV (LIST ()))))))))
   )
  )
 (multi64
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | x<if(!it)>y<endif>}; null={z}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output x)
      (attributes ((x (SV (LIST ((STRING a)))))))
      ))
    )
   )
  )
 (multi65
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | x<if(!it)>y<endif>}; null={z}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output xx)
      (attributes ((x (SV (LIST ((STRING a) (STRING b)))))))
      ))
    )
   )
  )
 (multi66
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | x<if(!it)>y<endif>}; null={z}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>") (output z) (attributes ((x (SV (LIST (NULL))))))))
    )
   )
  )
 (multi67
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | x<if(!it)>y<endif>}; null={z}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output zx)
      (attributes ((x (SV (LIST (NULL (STRING b)))))))
      ))
    )
   )
  )
 (multi68
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | x<if(!it)>y<endif>}; null={z}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output xz)
      (attributes ((x (SV (LIST ((STRING a) NULL))))))
      ))
    )
   )
  )
 (multi69
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:{it | x<if(!it)>y<endif>}; null={z}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output xzx)
      (attributes ((x (SV (LIST ((STRING a) NULL (STRING b)))))))
      ))
    )
   )
  )
 (multi70
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:t():u(); null={y}>"
|}
      ))
    )
   (runs (((input "<test(x)>") (attributes ((x (SV (LIST ()))))))))
   )
  )
 (multi71
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:t():u(); null={y}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output a)
      (attributes ((x (SV (LIST ((STRING a)))))))
      ))
    )
   )
  )
 (multi72
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:t():u(); null={y}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output ab)
      (attributes ((x (SV (LIST ((STRING a) (STRING b)))))))
      ))
    )
   )
  )
 (multi73
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:t():u(); null={y}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>") (output y) (attributes ((x (SV (LIST (NULL))))))))
    )
   )
  )
 (multi74
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:t():u(); null={y}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output yb)
      (attributes ((x (SV (LIST (NULL (STRING b)))))))
      ))
    )
   )
  )
 (multi75
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:t():u(); null={y}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output ay)
      (attributes ((x (SV (LIST ((STRING a) NULL))))))
      ))
    )
   )
  )
 (multi76
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<x:t():u(); null={y}>"
|}
      ))
    )
   (runs
    (((input "<test(x)>")
      (output ayb)
      (attributes ((x (SV (LIST ((STRING a) NULL (STRING b)))))))
      ))
    )
   )
  )
 (list00
  ((classname hello)
   (groupfile
    (("t.stg" {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<[]>"
|}))
    )
   (runs (((input "<test(x)>"))))
   (errors {|context [anonymous] 1:6 attribute x isn't defined
|})
   )
  )
 (list01
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<[]; null={x}>"
|}
      ))
    )
   (runs (((input "<test(x)>"))))
   (errors {|context [anonymous] 1:6 attribute x isn't defined
|})
   )
  )
 (list02
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<[]:{it | x}>"
|}
      ))
    )
   (runs (((input "<test(x)>"))))
   (errors {|context [anonymous] 1:6 attribute x isn't defined
|})
   )
  )
 (list03
  ((classname hello)
   (groupfile
    (("t.stg"
      {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<[[],[]]:{it| x}>"
|}
      ))
    )
   (runs (((input "<test(x)>"))))
   (errors {|context [anonymous] 1:6 attribute x isn't defined
|})
   )
  )
 (list04
  ((classname hello)
   (groupfile
    (("t.stg" {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= "<[]:t()>"
|}))
    )
   (runs (((input "<test(x)>"))))
   (errors {|context [anonymous] 1:6 attribute x isn't defined
|})
   )
  )
 )