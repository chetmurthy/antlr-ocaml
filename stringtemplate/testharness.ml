(**pp -syntax camlp5o -package pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.yojson,pa_ppx.deriving_plugins.located_yojson,pa_ppx.utils *)

open Eval

type harness_t =
  {
    classname : string
  ; template_s : string
  ; attributes : Environ.frame_t
  ; groupfile : (string * string) option
  ; expected : string
  }
[@@deriving show,yojson,located_yojson {exn=true}]

let of_string s =
  let open Pa_ppx_located_yojson.Json in
  let j = JsonEOI.of_string s in
  harness_t_of_located_yojson_exn j

let load ~file =
  let open Pa_ppx_located_yojson.Json in
  let j = JsonEOI.load ~file in
  harness_t_of_located_yojson_exn j

let eg1 = {
    classname = "hello"
  ; template_s = "<{Hello, <name>!}>"
  ; attributes = Value.[
        ("name", STRING "World")
                 ]
  ; groupfile = None
  ; expected = "Hello, World!"
  }

let eg2 = {
    classname = "hello"
  ; template_s = "<{Hello, <name>!}>"
  ; attributes = Value.[
        ("name", LIST [STRING "World1"; STRING "World2"])
                 ]
  ; groupfile = None
  ; expected = "Hello, World!"
  }

let emit pps th =
  let stconstructor pps th =
    match th.groupfile with
      None -> Fmt.(pf pps "new ST(%a)" Dump.string th.template_s)
    | Some (fname, _) -> Fmt.(pf pps "new ST(new STGroupFile(%a), %a)"
                           Dump.string fname
                           Dump.string th.template_s) in
  let rec staddattr pps (n,v) =
    let open Value in
    match v with
      STRING s ->
      Fmt.(pf pps "st.add(%a, %a);" Dump.string n Dump.string s)
    | LIST l ->
       let add1 pps v = staddattr pps (n,v) in
       Fmt.(pf pps "%a" (list add1) l)
    | NULL ->
      Fmt.(pf pps "st.add(%a, null);" Dump.string n)
  in
  Fmt.(pf pps {|
import org.stringtemplate.v4.*;

public class %s {
    public static void main(String[] args) {
	ST st = %a;
	%a
	String output = st.render();
	System.out.println("<RoNnIe|"+output+"|RaYgUn>");
    }
}
|}
         th.classname
         stconstructor th
         (list staddattr) th.attributes
  )
