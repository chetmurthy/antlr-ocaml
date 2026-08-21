(**pp -syntax camlp5o -package pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.yojson,pa_ppx.deriving_plugins.located_yojson,pa_ppx.deriving_plugins.located_sexp,pa_ppx.utils *)

open Pa_ppx_base
open Ppxutil
open Pa_ppx_located_sexp

open St_util
open Eval

type run_t = {
    input : string located
  ; output : string
    [@located_sexp.default ""]
    [@located_sexp.sexp_drop_default (=)]
  ; attributes : Environ.frame_t
    [@located_sexp.default []]
    [@located_sexp.sexp_drop_default (=)]
  ; comments : string
    [@located_sexp.default ""]
    [@located_sexp.sexp_drop_default (=)]
  ; disabled : bool
    [@located_sexp.default false]
    [@located_sexp.sexp_drop_default (=)]

  }
[@@deriving show,located_sexp {exn=true, strict=true}]

type t =
  {
    classname : string
  ; groupfile : (string * string located) option
    [@located_sexp.default None]
    [@located_sexp.sexp_drop_default (=)]
  ; groupfiles : (string * string located) list
    [@located_sexp.default []]
    [@located_sexp.sexp_drop_default (=)]
  ; indent : bool
    [@located_sexp.default true]
    [@located_sexp.sexp_drop_default (=)]
  ; runs : run_t list
  ; errors : string
    [@located_sexp.default ""]
    [@located_sexp.sexp_drop_default (=)]
  ; errorsContains : string
    [@located_sexp.default ""]
    [@located_sexp.sexp_drop_default (=)]
  ; ignore : bool
    [@located_sexp.default false]
    [@located_sexp.sexp_drop_default (=)]
  }
[@@deriving show,located_sexp {exn=true, strict=true}]

let of_sexp_string s =
  let open Pa_ppx_located_sexp.Altsexp in
  let j = of_string s in
  t_of_located_sexp j

let load_sexp ~file =
  let open Pa_ppx_located_sexp.Altsexp in
  let j = load_sexp file in
  t_of_located_sexp j

let load ~file = load_sexp ~file

let verify ~verbose th =
  let open Pa in
  List.map (fun r ->
      if verbose then Fmt.(pf stderr "\t[input %a]@." Dump.string (snd r.input)) ;
      STG2_STPa.Template.of_located_string r.input) th.runs ;
  Option.map (fun (fname,txt) ->
      if verbose then Fmt.(pf stderr "\t[groupfile %s]@." fname) ;
      Eval.Group.of_located_string txt) th.groupfile ;
  List.map (fun (fname,txt) ->
      if verbose then Fmt.(pf stderr "\t[groupfile %s]@." fname) ;
      Eval.Group.of_located_string txt
    ) th.groupfiles ;
  ()

module Multi = struct
type _t = (string * t) list
[@@deriving show,located_sexp {exn=true, strict=true}]
type t = _t
[@@deriving show,located_sexp {exn=true, strict=true}]

let of_sexp_string s =
  let open Pa_ppx_located_sexp.Altsexp in
  let j = of_string s in
  t_of_located_sexp j

let load_sexp ~file =
  let open Pa_ppx_located_sexp.Altsexp in
  let j = load_sexp file in
  t_of_located_sexp j

let load ~file =
  load_sexp ~file

end

open Value
open Environ
let eg1 = {
    classname = "hello"
  ; groupfile = Some ("a.stg",(Ploc.dummy, " d() ::= << >> "))
  ; groupfiles = []
  ; runs = [{
               input = (Ploc.dummy, "<{Hello, <name>!}>")
             ; output = "Hello, World!"
             ; attributes = [
                 ("name", SV (STRING "World"))
               ]
             ; comments = ""
             ; disabled = false
           }]
  ; indent = false
  ; errors = ""
  ; errorsContains = ""
  ; ignore = false
  }

let eg2 = {
    classname = "hello"
  ; groupfile = None
  ; groupfiles = []
  ; runs = [{
               input = (Ploc.dummy, "<{Hello, <name>!}>")
             ; output = "Hello, World!"
             ; attributes = [
                 ("name", MV [STRING "World1"; STRING "World2"])
               ]
             ; comments = ""
             ; disabled = false
           }]
  ; indent = false
  ; errors = ""
  ; errorsContains = ""
  ; ignore = false
  }

let eg3 = {
    classname = "hello"
  ; groupfile = None
  ; groupfiles = []
  ; runs = [{
               input = (Ploc.dummy, "<{Hello, <name>!}>")
             ; output = "Hello, World!"
             ; attributes = [
                 ("name", SV NULL)
               ]
             ; comments = ""
             ; disabled = false
           }]
  ; indent = false
  ; errors = ""
  ; errorsContains = ""
  ; ignore = false
  }

let eg4 = {
    classname = "hello"
  ; groupfile = None
  ; groupfiles = []
  ; runs = [{
               input = (Ploc.dummy, "<{Hello, <name>!}>")
             ; output = "Hello, World!"
             ; attributes = [
                 ("name", SV (LIST [STRING "World1"; STRING "World2"]))
               ]
             ; comments = ""
             ; disabled = false
           }]
  ; indent = false
  ; errors = ""
  ; errorsContains = ""
  ; ignore = false
  }

let eg5 = {
    classname = "hello"
  ; groupfile = None
  ; groupfiles = []
  ; runs = [{
               input = (Ploc.dummy, "<{Hello, <name>!}>")
             ; output = "Hello, World!"
             ; attributes = [
                 ("name", SV (DICT [("a",STRING "b"); ("c",STRING "d")]))
               ]
             ; comments = ""
             ; disabled = false
           }]
  ; indent = false
  ; errors = ""
  ; errorsContains = ""
  ; ignore = false
  }

let rec fmt_value pps v =
  match v with
    NULL -> Fmt.(pf pps "null")
  | STRING s -> Fmt.(pf pps "%a" Dump.string s)
  | INT s -> Fmt.(pf pps "%d" s)
  | BOOL b -> Fmt.(pf pps "%b" b)
  | LIST l when List.for_all isSTRINGorNULL l ->
     let pp1 pps = function
         (STRING s) -> Fmt.(pf pps "add(%a);" Dump.string s)
       | NULL -> Fmt.(pf pps "add(null);")
     in
     Fmt.(pf pps "new ArrayList<String>() {{%a}}" (list pp1) l)
  | LIST l when List.for_all isINT l ->
     let pp1 pps (INT s) = Fmt.(pf pps "add(%d);" s) in
     Fmt.(pf pps "new ArrayList<Integer>() {{%a}}" (list pp1) l)
  | LIST l when List.for_all isBOOL l ->
     let pp1 pps (BOOL s) = Fmt.(pf pps "add(%b);" s) in
     Fmt.(pf pps "new ArrayList<Boolean>() {{%a}}" (list pp1) l)
  | DICT l when List.for_all (fun (_,v) -> isSTRINGorNULL v) l ->
     let pp1 pps (k,v) = match v with
         STRING s -> Fmt.(pf pps "put(%a,%a);" Dump.string k Dump.string s)
       | NULL -> Fmt.(pf pps "put(%a,null);" Dump.string k)
     in
     Fmt.(pf pps "new LinkedHashMap<String,String>() {{%a}}" (list pp1) l)
  | _ -> Fmt.(failwithf "fmt_value: cannot format %a" Value.pp v)

let add_attr pps (n,v) =
    Fmt.(pf pps "st.add(%a, %a);" Dump.string n fmt_value v)

let add_binding pps (n,rhs) =
  match rhs with
    SV v ->
    add_attr pps (n,v)
  | MV l ->
       let add1 pps v = add_attr pps (n,v) in
       Fmt.(pf pps "%a" (list add1) l)

let emit pps th =
  let groupfiles = (match th.groupfile with None -> [] | Some x -> [x])@th.groupfiles in
  let hasgroup = groupfiles <> [] in
  let stgroup pps th =
    match (th.groupfile, th.groupfiles) with
      (None, []) -> Fmt.(pf pps "")
    | (None, _::_) ->
       Fmt.(pf pps {|
STGroup group = new STGroupDir(".");
dumpGroup(group) ;
|})
    | (Some(fname, _), _) ->
       Fmt.(pf pps {|STGroupFile group = new STGroupFile(%a);
group.load();
dumpGroup(group) ;
|}
              Dump.string fname)
  in
  let render_txt =
    if th.indent then
      "String output = st.render();"
    else
      "StringWriter sw = new StringWriter();
        NoIndentWriter w = new NoIndentWriter(sw);
        st.write(w);
        String output = sw.toString();"
  in
  let strun pps r =
    if hasgroup then
      Fmt.(pf pps {|
{
ST st = new ST(group, %a) ;
System.out.println("================ template ================") ;
System.out.println(%a) ;
dump(%a, st.impl) ;
%a
%s
System.out.println("<RoNnIe|"+output+"|RaYgUn>") ;
System.out.println("====") ;
}
|}
           Dump.string (snd r.input)
           Dump.string (snd r.input)
           Dump.string (snd r.input)
           (list add_binding) r.attributes
           render_txt
      )
    else
      Fmt.(pf pps {|
{
STGroup group = new STGroup() ;
ST st = new ST(group, %a) ;
dumpGroup(group) ;
System.out.println("================ template ================") ;
System.out.println(%a) ;
dump(%a, st.impl) ;
%a
%s
System.out.println("<RoNnIe|"+output+"|RaYgUn>") ;
System.out.println("====") ;
}
|}
           Dump.string (snd r.input)
           Dump.string (snd r.input)
           Dump.string (snd r.input)
           (list add_binding) r.attributes
           render_txt
      ) in
  Fmt.(pf pps {|
import java.io.StringWriter;
import java.util.*;
import org.stringtemplate.v4.AutoIndentWriter;
import org.stringtemplate.v4.NoIndentWriter;
import org.stringtemplate.v4.*;
import org.stringtemplate.v4.compiler.*;

public class %s {
    public static
    <T extends Comparable<? super T>> List<T> asSortedList(Collection<T> c) {
      List<T> list = new ArrayList<T>(c);
      java.util.Collections.sort(list);
      return list;
    }
    public static void dump(String name, CompiledST cst) {
	System.out.println("================ "+name+"   ================") ;
	System.out.println("Template: "+cst.template) ;
	System.out.println("================ instrs   ================") ;
	System.out.println(cst.instrs()) ;
	System.out.println("================ instrs (bytes)   ================") ;
        {
        byte[] bytes = Arrays.copyOfRange(cst.instrs, 0, cst.codeSize);
        System.out.println(Arrays.toString(bytes)); 
        }
	System.out.println("================ disasm   ================") ;
	System.out.println(cst.disasm()) ;
	System.out.println("================ dump     ================") ;
	cst.dump() ;
	System.out.println("================ end      ================") ;
    }
    public static void dumpGroup(STGroup group) {
	for (String name : asSortedList(group.getTemplateNames())) {
	    dump(name, (new ST(name)).impl) ;
	}
    }
    public static void main(String[] args) throws Exception {
        %a
	%a
    }
}
|}
         th.classname
         stgroup th
         (list strun) (List.filter (fun r -> not r.disabled) th.runs)
  )
