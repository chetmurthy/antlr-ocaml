(**pp -syntax camlp5o -package pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.yojson,pa_ppx.deriving_plugins.located_yojson,pa_ppx.deriving_plugins.located_sexp,pa_ppx.utils *)

open Pa_ppx_base
open Ppxutil

open Eval

type t =
  {
    classname : string
  ; template_s : string
  ; attributes : Environ.frame_t
  ; groupfile : (string * string) option[@yojson.default None][@located_yojson.default None][@located_sexp.default None]
  ; groupfiles : (string * string) list[@yojson.default []][@located_yojson.default []][@located_sexp.default []]
  ; output : string
  ; errors : string[@yojson.default ""][@located_yojson.default ""][@located_sexp.default ""]
  ; indent : bool[@yojson.default true][@located_yojson.default true][@located_sexp.default true]
  }
[@@deriving show,yojson,located_yojson {exn = true},located_sexp {exn=true}]

let of_json_string s =
  let open Pa_ppx_located_yojson.Json in
  let j = JsonEOI.of_string s in
  of_located_yojson_exn j

let of_sexp_string s =
  let open Pa_ppx_located_sexp.Altsexp in
  let j = of_string s in
  t_of_located_sexp j

let load_json ~file =
  let open Pa_ppx_located_yojson.Json in
  let j = JsonEOI.load ~file in
  of_located_yojson_exn j

let load_sexp ~file =
  let open Pa_ppx_located_sexp.Altsexp in
  let j = load_sexp file in
  t_of_located_sexp j

let load ~file =
  if Fpath.(file |> v |> has_ext "json") then
    load_json ~file
  else if Fpath.(file |> v |> has_ext "sexp") then
    load_sexp ~file
  else Fmt.(failwithf "TH.load: file %s is neither .json nor .sexp" file)

module Multi = struct
type _t = (string * t) list
[@@deriving show,yojson,located_yojson {exn = true},located_sexp {exn=true}]
type t = _t
[@@deriving show,yojson,located_yojson {exn = true},located_sexp {exn=true}]

let of_json_string s =
  let open Pa_ppx_located_yojson.Json in
  let j = JsonEOI.of_string s in
  of_located_yojson_exn j

let of_sexp_string s =
  let open Pa_ppx_located_sexp.Altsexp in
  let j = of_string s in
  t_of_located_sexp j

let load_json ~file =
  let open Pa_ppx_located_yojson.Json in
  let j = JsonEOI.load ~file in
  of_located_yojson_exn j

let load_sexp ~file =
  let open Pa_ppx_located_sexp.Altsexp in
  let j = load_sexp file in
  t_of_located_sexp j

let load ~file =
  if Fpath.(file |> v |> has_ext "json") then
    load_json ~file
  else if Fpath.(file |> v |> has_ext "sexp") then
    load_sexp ~file
  else Fmt.(failwithf "TH.Multi.load: file %s is neither .json nor .sexp" file)

end

open Value
open Environ
let eg1 = {
    classname = "hello"
  ; template_s = "<{Hello, <name>!}>"
  ; attributes = [
      ("name", SV (STRING "World"))
    ]
  ; groupfile = Some ("a.stg"," d() ::= << >> ")
  ; groupfiles = []
  ; output = "Hello, World!"
  ; errors = ""
  ; indent = false
  }

let eg2 = {
    classname = "hello"
  ; template_s = "<{Hello, <name>!}>"
  ; attributes = [
        ("name", MV [STRING "World1"; STRING "World2"])
                 ]
  ; groupfile = None
  ; groupfiles = []
  ; output = "Hello, World!"
  ; errors = ""
  ; indent = false
  }

let eg3 = {
    classname = "hello"
  ; template_s = "<{Hello, <name>!}>"
  ; attributes = [
      ("name", SV NULL)
    ]
  ; groupfile = None
  ; groupfiles = []
  ; output = "Hello, World!"
  ; errors = ""
  ; indent = false
  }

let eg4 = {
    classname = "hello"
  ; template_s = "<{Hello, <name>!}>"
  ; attributes = [
        ("name", SV (LIST [STRING "World1"; STRING "World2"]))
                 ]
  ; groupfile = None
  ; groupfiles = []
  ; output = "Hello, World!"
  ; errors = ""
  ; indent = false
  }

let eg4 = {
    classname = "hello"
  ; template_s = "<{Hello, <name>!}>"
  ; attributes = [
        ("name", SV (DICT [("a",STRING "b"); ("c",STRING "d")]))
                 ]
  ; groupfile = None
  ; groupfiles = []
  ; output = "Hello, World!"
  ; errors = ""
  ; indent = false
  }

let rec fmt_value pps v =
  match v with
    NULL -> Fmt.(pf pps "null")
  | STRING s -> Fmt.(pf pps "%a" Dump.string s)
  | INT s -> Fmt.(pf pps "%d" s)
  | BOOL b -> Fmt.(pf pps "%b" b)
  | LIST l when List.for_all isSTRING l ->
     let pp1 pps (STRING s) = Fmt.(pf pps "add(%a);" Dump.string s) in
     Fmt.(pf pps "new ArrayList<String>() {{%a}}" (list pp1) l)
  | LIST l when List.for_all isINT l ->
     let pp1 pps (INT s) = Fmt.(pf pps "add(%d);" s) in
     Fmt.(pf pps "new ArrayList<Integer>() {{%a}}" (list pp1) l)
  | DICT l when List.for_all (fun (_,v) -> isSTRING v) l ->
     let pp1 pps (k,STRING s) = Fmt.(pf pps "put(%a,%a);" Dump.string k Dump.string s) in
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
    match groupfiles with
      [] -> Fmt.(pf pps "")
    | [(fname, _)] when String.contains fname '/' ->
       Fmt.(pf pps "STGroup group = new STGroupDir(\".\");\n")
    | [(fname, _)] ->
       Fmt.(pf pps "STGroupFile group = new STGroupFile(%a);\ngroup.load();\n"
              Dump.string fname)
    | _::_::_ ->
       Fmt.(pf pps "STGroup group = new STGroupDir(\".\");\n") in
  let stconstructor pps th =
    if hasgroup then
       Fmt.(pf pps "new ST(group, %a)" Dump.string th.template_s)
    else
      Fmt.(pf pps "new ST(%a)" Dump.string th.template_s) in
  let render_txt =
    if th.indent then
      "String output = st.render();"
    else
      "StringWriter sw = new StringWriter();
        NoIndentWriter w = new NoIndentWriter(sw);
        st.write(w);
        String output = sw.toString();"
  in

  Fmt.(pf pps {|
import java.io.StringWriter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import org.stringtemplate.v4.AutoIndentWriter;
import org.stringtemplate.v4.NoIndentWriter;
import org.stringtemplate.v4.*;

public class %s {
    public static void main(String[] args) throws Exception {
        %a
	ST st = %a;
	%a
	%s
	System.out.println("<RoNnIe|"+output+"|RaYgUn>");
    }
}
|}
         th.classname
         stgroup th
         stconstructor th
         (list add_binding) th.attributes
         render_txt
  )
