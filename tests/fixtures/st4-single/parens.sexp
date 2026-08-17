((classname hello)
   (runs (((input "<if(!(x||y)&&!z)>works<endif>") (output works))))
   (errors
    {|context [anonymous] 1:6 attribute x isn't defined
context [anonymous] 1:9 attribute y isn't defined
context [anonymous] 1:14 attribute z isn't defined
|}
    )
   )