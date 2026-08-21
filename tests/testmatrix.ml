(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.deriving_plugins.std *)

open Pa_ppx_utils
open Pa_ppx_base
open Ppxutil

Pa_ppx_runtime.Exceptions.Ploc.pp_loc_verbose := true ;;

open ST4
open Testharness
open Eval
open Environ
open Value
type std_test_t =
  {
    template : string
  ; x : Value.t
  ; expecting : string
  }

let _UNDEF = STRING "<undefined>"

let generate stt =
  let attributes =
    if stt.x <> _UNDEF then
      [("x", SV stt.x)]
    else [] in
  let groupfile_txt =
    Fmt.(str {|
t(x) ::= "<x>"
u(x) ::= "<x>"
test(x) ::= %a
|}
         Dump.string stt.template
    ) in
  let groupfile = Some ("t.stg", (Ploc.dummy, groupfile_txt)) in
  let errors =
    if stt.x <> _UNDEF then ""
    else {bar|context [anonymous] 1:6 attribute x isn't defined
|bar} in
  {
    classname = "hello"
  ; indent = true
  ; ignore = false
  ; errors
  ; errorsContains = ""
  ; groupfiles = []
  ; groupfile
  ; runs = [{
               input = (Ploc.dummy, "<test(x)>")
             ; output = stt.expecting
             ; attributes
             ; comments = ""
             ; disabled = false
           }]
  }

let _LIST0 = LIST[]
let _LISTa = LIST[STRING "a"]
let _LISTab = LIST[STRING"a";  STRING"b"]
let _LISTnull = LIST[NULL]
let _LISTa_null = LIST[STRING "a";NULL]
let _LISTnull_b = LIST[NULL; STRING "b"]
let _LISTa_null_b = LIST[STRING "a"; NULL; STRING "b"]

let single_valued_tests = [
    {template="<x>"; x= _UNDEF; expecting = ""}
  ; {template="<x>"; x= NULL; expecting = ""}
  ; {template="<x>"; x= STRING""; expecting = ""}
  ; {template="<x>"; x= _LIST0; expecting = ""}
  ; {template="<x:t()>"; x= _UNDEF; expecting = ""}
  ; {template="<x:t()>"; x= NULL; expecting = ""}
  ; {template="<x:t()>"; x= STRING""; expecting = ""}
  ; {template="<x:t()>"; x= _LIST0; expecting = ""}
  ; {template="<x; null={y}>"; x= _UNDEF; expecting = "y"}
  ; {template="<x; null={y}>"; x= NULL; expecting = "y"}
  ; {template="<x; null={y}>"; x= STRING""; expecting = ""}
  ; {template="<x; null={y}>"; x= _LIST0; expecting = ""}
  ; {template="<x:t(); null={y}>"; x= _UNDEF; expecting = "y"}
  ; {template="<x:t(); null={y}>"; x= NULL; expecting = "y"}
  ; {template="<x:t(); null={y}>"; x= STRING""; expecting = ""}
  ; {template="<x:t(); null={y}>"; x= _LIST0; expecting = ""}
  ; {template="<if(x)>y<endif>"; x= _UNDEF; expecting = ""}
  ; {template="<if(x)>y<endif>"; x= NULL; expecting = ""}
  ; {template="<if(x)>y<endif>"; x= STRING""; expecting = "y"}
  ; {template="<if(x)>y<endif>"; x= _LIST0; expecting = ""}
  ; {template="<if(x)>y<else>z<endif>"; x= _UNDEF; expecting = "z"}
  ; {template="<if(x)>y<else>z<endif>"; x= NULL; expecting = "z"}
  ; {template="<if(x)>y<else>z<endif>"; x= STRING""; expecting = "y"}
  ; {template="<if(x)>y<else>z<endif>"; x= _LIST0; expecting = "z"}
  ]

let multi_valued_tests = [
    {template="<x>"; x= _LIST0; expecting=        ""}
  ; {template="<x>"; x= _LISTa; expecting=        "a"}
  ; {template="<x>"; x= _LISTab; expecting=       "ab"}
  ; {template="<x>"; x= _LISTnull; expecting=     ""}
  ; {template="<x>"; x= _LISTnull_b; expecting=   "b"}
  ; {template="<x>"; x= _LISTa_null; expecting=   "a"}
  ; {template="<x>"; x= _LISTa_null_b; expecting= "ab"}
  ; {template="<x; null={y}>"; x= _LIST0; expecting=        ""}
  ; {template="<x; null={y}>"; x= _LISTa; expecting=        "a"}
  ; {template="<x; null={y}>"; x= _LISTab; expecting=       "ab"}
  ; {template="<x; null={y}>"; x= _LISTnull; expecting=     "y"}
  ; {template="<x; null={y}>"; x= _LISTnull_b; expecting=   "yb"}
  ; {template="<x; null={y}>"; x= _LISTa_null; expecting=   "ay"}
  ; {template="<x; null={y}>"; x= _LISTa_null_b; expecting= "ayb"}
  ; {template="<x; separator={,}>"; x= _LIST0; expecting=        ""}
  ; {template="<x; separator={,}>"; x= _LISTa; expecting=        "a"}
  ; {template="<x; separator={,}>"; x= _LISTab; expecting=       "a,b"}
  ; {template="<x; separator={,}>"; x= _LISTnull; expecting=     ""}
  ; {template="<x; separator={,}>"; x= _LISTnull_b; expecting=   "b"}
  ; {template="<x; separator={,}>"; x= _LISTa_null; expecting=   "a"}
  ; {template="<x; separator={,}>"; x= _LISTa_null_b; expecting= "a,b"}
  ; {template="<x; null={y}, separator={,}>"; x= _LIST0; expecting=        ""}
  ; {template="<x; null={y}, separator={,}>"; x= _LISTa; expecting=        "a"}
  ; {template="<x; null={y}, separator={,}>"; x= _LISTab; expecting=       "a,b"}
  ; {template="<x; null={y}, separator={,}>"; x= _LISTnull; expecting=     "y"}
  ; {template="<x; null={y}, separator={,}>"; x= _LISTnull_b; expecting=   "y,b"}
  ; {template="<x; null={y}, separator={,}>"; x= _LISTa_null; expecting=   "a,y"}
  ; {template="<x; null={y}, separator={,}>"; x= _LISTa_null_b; expecting= "a,y,b"}
  ; {template="<if(x)>y<endif>"; x= _LIST0; expecting=        ""}
  ; {template="<if(x)>y<endif>"; x= _LISTa; expecting=        "y"}
  ; {template="<if(x)>y<endif>"; x= _LISTab; expecting=       "y"}
  ; {template="<if(x)>y<endif>"; x= _LISTnull; expecting=     "y"}
  ; {template="<if(x)>y<endif>"; x= _LISTnull_b; expecting=   "y"}
  ; {template="<if(x)>y<endif>"; x= _LISTa_null; expecting=   "y"}
  ; {template="<if(x)>y<endif>"; x= _LISTa_null_b; expecting= "y"}
  ; {template="<x:{it | <it>}>"; x= _LIST0; expecting=        ""}
  ; {template="<x:{it | <it>}>"; x= _LISTa; expecting=        "a"}
  ; {template="<x:{it | <it>}>"; x= _LISTab; expecting=       "ab"}
  ; {template="<x:{it | <it>}>"; x= _LISTnull; expecting=     ""}
  ; {template="<x:{it | <it>}>"; x= _LISTnull_b; expecting=   "b"}
  ; {template="<x:{it | <it>}>"; x= _LISTa_null; expecting=   "a"}
  ; {template="<x:{it | <it>}>"; x= _LISTa_null_b; expecting= "ab"}
  ; {template="<x:{it | <it>}; null={y}>"; x= _LIST0; expecting=        ""}
  ; {template="<x:{it | <it>}; null={y}>"; x= _LISTa; expecting=        "a"}
  ; {template="<x:{it | <it>}; null={y}>"; x= _LISTab; expecting=       "ab"}
  ; {template="<x:{it | <it>}; null={y}>"; x= _LISTnull; expecting=     "y"}
  ; {template="<x:{it | <it>}; null={y}>"; x= _LISTnull_b; expecting=   "yb"}
  ; {template="<x:{it | <it>}; null={y}>"; x= _LISTa_null; expecting=   "ay"}
  ; {template="<x:{it | <it>}; null={y}>"; x= _LISTa_null_b; expecting= "ayb"}
  ; {template="<x:{it | <i>.<it>}>"; x= _LIST0; expecting=        ""}
  ; {template="<x:{it | <i>.<it>}>"; x= _LISTa; expecting=        "1.a"}
  ; {template="<x:{it | <i>.<it>}>"; x= _LISTab; expecting=       "1.a2.b"}
  ; {template="<x:{it | <i>.<it>}>"; x= _LISTnull; expecting=     ""}
  ; {template="<x:{it | <i>.<it>}>"; x= _LISTnull_b; expecting=   "1.b"}
  ; {template="<x:{it | <i>.<it>}>"; x= _LISTa_null; expecting=   "1.a"}
  ; {template="<x:{it | <i>.<it>}>"; x= _LISTa_null_b; expecting= "1.a2.b"}
  ; {template="<x:{it | <i>.<it>}; null={y}>"; x= _LIST0; expecting=        ""}
  ; {template="<x:{it | <i>.<it>}; null={y}>"; x= _LISTa; expecting=        "1.a"}
  ; {template="<x:{it | <i>.<it>}; null={y}>"; x= _LISTab; expecting=       "1.a2.b"}
  ; {template="<x:{it | <i>.<it>}; null={y}>"; x= _LISTnull; expecting=     "y"}
  ; {template="<x:{it | <i>.<it>}; null={y}>"; x= _LISTnull_b; expecting=   "y1.b"}
  ; {template="<x:{it | <i>.<it>}; null={y}>"; x= _LISTa_null; expecting=   "1.ay"}
  ; {template="<x:{it | <i>.<it>}; null={y}>"; x= _LISTa_null_b; expecting= "1.ay2.b"}
  ; {template="<x:{it | x<if(!it)>y<endif>}; null={z}>"; x= _LIST0; expecting=        ""}
  ; {template="<x:{it | x<if(!it)>y<endif>}; null={z}>"; x= _LISTa; expecting=        "x"}
  ; {template="<x:{it | x<if(!it)>y<endif>}; null={z}>"; x= _LISTab; expecting=       "xx"}
  ; {template="<x:{it | x<if(!it)>y<endif>}; null={z}>"; x= _LISTnull; expecting=     "z"}
  ; {template="<x:{it | x<if(!it)>y<endif>}; null={z}>"; x= _LISTnull_b; expecting=   "zx"}
  ; {template="<x:{it | x<if(!it)>y<endif>}; null={z}>"; x= _LISTa_null; expecting=   "xz"}
  ; {template="<x:{it | x<if(!it)>y<endif>}; null={z}>"; x= _LISTa_null_b; expecting= "xzx"}
  ; {template="<x:t():u(); null={y}>"; x= _LIST0; expecting=        ""}
  ; {template="<x:t():u(); null={y}>"; x= _LISTa; expecting=        "a"}
  ; {template="<x:t():u(); null={y}>"; x= _LISTab; expecting=       "ab"}
  ; {template="<x:t():u(); null={y}>"; x= _LISTnull; expecting=     "y"}
  ; {template="<x:t():u(); null={y}>"; x= _LISTnull_b; expecting=   "yb"}
  ; {template="<x:t():u(); null={y}>"; x= _LISTa_null; expecting=   "ay"}
  ; {template="<x:t():u(); null={y}>"; x= _LISTa_null_b; expecting= "ayb"}
  ]

let list_tests = [
    {template="<[]>";x= _UNDEF; expecting= ""}
  ; {template="<[]; null={x}>"; x=_UNDEF; expecting= ""}
  ; {template="<[]:{it | x}>"; x=_UNDEF; expecting= ""}
  ; {template="<[[],[]]:{it| x}>"; x=_UNDEF; expecting= ""}
  ; {template="<[]:t()>"; x=_UNDEF; expecting= ""}
  ]

let single_l = 
  single_valued_tests
  |> List.map generate
  |> List.mapi (fun i th ->
         let name = Fmt.(str "single%02d" i) in
         (name, th))

let multi_l = 
  multi_valued_tests
  |> List.map generate
  |> List.mapi (fun i th ->
         let name = Fmt.(str "multi%02d" i) in
         (name, th))

let list_l = 
  list_tests
  |> List.map generate
  |> List.mapi (fun i th ->
         let name = Fmt.(str "list%02d" i) in
         (name, th))

let sexp = Multi.located_sexp_of_t (single_l@multi_l@list_l)
;;
sexp |> Sexpio.Printing.to_string |> print_string ;;
