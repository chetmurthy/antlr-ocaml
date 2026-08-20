(**pp -syntax camlp5o -package pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.located_sexp,pa_ppx.utils *)

open Pa_ppx_base
open Ppxutil
open Pa_ppx_utils
open Sttypes2
open Stg_types

module STPa = Pa.STG2_STPa
module STGPa = Pa.STG2_STGPa

module Intern = struct
  open Coll
  open Cooked

  let dict_value = function
      Raw.KEYVAL_BIGSTRING (loc, s) ->
       let (loc, s) = St_util.unwrap_stg_bigstring (loc, s) in
       let t = STPa.Template.of_located_string (loc, s) in
       DVAL_VALUE (VALUE_TEMPLATE t)
    | KEYVAL_BIGSTRING_NO_NL (loc, s) ->
       let (loc, s) = St_util.unwrap_stg_bigstring_no_nl (loc, s) in
       let t = STPa.Template.of_located_string (loc, s) in
       let t = St_ops.removews t in
       DVAL_VALUE (VALUE_TEMPLATE t)
    | KEYVAL_STRING (loc, s) ->
       let (loc, s) = St_util.unescape_stg_string (loc, s) in
       DVAL_VALUE(VALUE_TEMPLATE (STPa.Template.of_located_string (loc, s)))
    | KEYVAL_SUBTEMPLATE st ->
       DVAL_VALUE(VALUE_SUBTEMPLATE st)
    | KEYVAL_BOOL b -> DVAL_VALUE(VALUE_BOOL b)
    | KEYVAL_MT_DICT -> DVAL_VALUE VALUE_MT_DICT
    | KEYVAL_KEY -> DVAL_KEY

  let dict g (name,(kv,dflt_opt)) =
    let kv =
      kv
      |> List.map (fun (k, v) ->
             (snd (St_util.unescape_stg_string k),
              dict_value v)) in
    let kv = MHM.ofList 23 kv in
    let default = Option.map dict_value dflt_opt in
    let rv = { kv ; default } in
    MHM.add g.dicts (name,rv)

  let template_def g t =
    let open Raw in
    match t with
      TEMPLATE_DEF (name, formals,  rhs) ->
       let formals =
         formals
         |> List.map (fun (argname, dflt_opt) ->
                let dflt_opt =
                  dflt_opt
                  |> Option.map (function
                           FORMAL_STRING s ->
                            let s = St_util.unescape_stg_string s in
                            VALUE_TEMPLATE (STPa.Template.of_located_string s)
                         | FORMAL_SUBTEMPLATE st ->
                            VALUE_SUBTEMPLATE st
                         | FORMAL_BOOL b -> VALUE_BOOL b
                         | FORMAL_MT_DICT -> VALUE_MT_DICT) in
                (argname,dflt_opt)) in
       let body =
         match rhs with
           TDEF_STRING s ->
            let s = St_util.unescape_stg_string s in
            STPa.Template.of_located_string s
         | TDEF_BIGSTRING s ->
            let s = St_util.unwrap_stg_bigstring s in
            STPa.Template.of_located_string s
         | TDEF_BIGSTRING_NO_NL s ->
            let s = St_util.unwrap_stg_bigstring_no_nl s in
            let t = STPa.Template.of_located_string s in
            St_ops.removews t in
       let t = {
           name
         ; formals
         ; body
         } in
       MHM.add g.templates (name, t)

    | TEMPLATE_ALIAS (name, realname) ->
       if not (MHM.in_dom g.templates realname) then
         Fmt.(failwithf "InternGroup: alias %s->%s refers to a non-existent template"
                name realname) ;
       let rhs = MHM.map g.templates realname in
       MHM.add g.templates (name, rhs)

  let group g =
    let templates = MHM.mk 23 in
    let dicts = MHM.mk 23 in
    let rv = {
        header = g.Raw.header
      ; imports = g.Raw.imports
      ; templates
      ; dicts
      } in
    g.defs
    |> List.iter (function
             Raw.GROUPDEF_TEMPLATE t ->
             template_def rv t
           | GROUPDEF_DICT d ->
              dict rv d) ;
    rv

  let group_of_string s =
    let raw = STGPa.Group.of_string s in
    group raw

  let group_of_located_string s =
    let raw = STGPa.Group.of_located_string s in
    group raw

  let groupfile ~stg file =
    let raw = STGPa.Group.load ~file in
    if not stg then begin
        assert (raw.Raw.imports = []) ;
      end ;
    group raw

  let groupdir dir =
    let gd = { groups = MHM.mk 23 } in
    let dir = Fpath.v dir in
    let files =
      dir
      |> Bos.OS.Dir.contents ~rel:true
      |> Rresult.R.failwith_error_msg
      |> List.filter (fun p -> Fpath.has_ext "stg" p || Fpath.has_ext "st" p)
    in
    let rec intern_and_add file =
      if MHM.in_dom gd.groups file then ()
      else if Fpath.(file |> v |> has_ext "st") then
        let g = groupfile ~stg:false file in
        assert (g.imports = []) ;
        MHM.add gd.groups (file, g)

      else if Fpath.(file |> v |> has_ext "stg") then
        let g = groupfile ~stg:true file in
        MHM.add gd.groups (file, g) ;
        List.iter intern_and_add g.imports
      else assert false
    and intern_and_add_fpath fpath =
      fpath |> Fpath.to_string |> intern_and_add
    in
    List.iter intern_and_add_fpath files ;
    gd

end

module type INDENT = sig
  type t
  val mt : t
  val add_string : t -> string -> t
  val emit : Buffer.t -> t -> unit
end

module Indent : INDENT = struct
  type t = string list

  let mt = []
  let add_string t s = s::t

  let emit b t =
    let l = List.rev t in
    List.iter (Buffer.add_string b) l

end

module OutputToken = struct
open Pa_ppx_located_sexp.Sexp
  type t =
    LITERAL of literal_t
  | INDENT of Indent.t

  type render_t = (unit -> t Stream.t)
                    [@printer fun pps x -> Fmt.(pf pps "<rendered>")]
                    [@located_sexp_of (fun _ -> Atom(Ploc.dummy, "<rendered>"))]
                    [@of_located_sexp (fun _ -> failwith "cannot deserialize to rendered stream")]
                    [@@deriving show,located_sexp {exn=true}]
end

module Value = struct
type t =
  STRING of string
| BOOL of bool
| INT of int
| DICT of (string * t) list
| LIST of t list
| NULL
| RENDERED of OutputToken.render_t
[@@deriving show,located_sexp {exn=true}]

let isSTRING = function STRING _ -> true | _ -> false
let isSTRINGorNULL = function (STRING _|NULL) -> true | _ -> false
let isINT = function INT _ -> true | _ -> false
let isBOOL = function BOOL _ -> true | _ -> false

end

module Context = struct
  open Sttypes2
  open Stg_types.Cooked

type context_t = {
    group : group_t
  ; warning : string -> unit
  ; error : string -> unit
  }

let warning ctxt s = ctxt.warning s
let error ctxt s = ctxt.error s

let default_warning s =  Fmt.(pf stderr "%s@." s)
let default_error s = Fmt.(failwithf "%s@." s)

let mk () = {
    group = mk_group ()
  ; warning = default_warning
  ; error = default_error
  }
end

module Environ = struct
type attr_val_t = MV of Value.t list | SV of Value.t
[@@deriving show,located_sexp {exn=true}]
type binding_t = string * attr_val_t
[@@deriving show,located_sexp {exn=true}]
type frame_t = binding_t list
[@@deriving show,located_sexp {exn=true}]
type t = frame_t list
[@@deriving show,located_sexp {exn=true}]

let lookup_opt ctxt (env : t) varname =
  let rec lookrec = function
      [] ->
       Context.warning ctxt Fmt.(str "Environ.lookup: name %a not found" Dump.string varname) ;
       None
    | fh::tl when List.mem_assoc varname fh ->
       Some (List.assoc varname fh)
    | _::tl -> lookrec tl
  in lookrec env

let mt = []

let push_frame f (env : t) : t = f::env

end

module IW = struct
  type t = {
      mutable cur_indent : Indent.t
    ; mutable emitted_text : bool
    ; buf : Buffer.t
    }

  let mk() = {
      cur_indent = Indent.mt
    ; emitted_text = false
    ; buf = Buffer.create 23
    }

  let emit ~indent t x =
    match x with
      TEXT s when t.emitted_text ->
       Buffer.add_string t.buf s

    | TEXT s ->
       Indent.emit t.buf t.cur_indent ;
       ; t.cur_indent <- Indent.mt
       ; t.emitted_text <- true
       ; Buffer.add_string t.buf s

    | HORZ_WS s when t.emitted_text ->
       Buffer.add_string t.buf s

    | HORZ_WS s ->
       t.cur_indent <- Indent.add_string t.cur_indent s

    | VERT_WS s ->
       Buffer.add_string t.buf s
      ; t.cur_indent <- indent
      ; t.emitted_text <- false

  let cur_indent ~indent t =
    if t.emitted_text then indent
    else t.cur_indent

end
module IndentWriter = IW

module Doit = struct
  open Sttypes2
  open Stg_types.Cooked

  open Environ
  open Value

type context_t = {
    group : group_t
  }

open OutputToken

let render_value v : render_t =
  fun () ->
  match v with
    STRING s -> [< 'LITERAL (TEXT s) >]
  | BOOL b -> [< 'LITERAL (TEXT (if b then "true" else "false")) >]
  | INT n -> [< 'LITERAL (TEXT (string_of_int n)) >]
  | DICT _ -> failwith "render_value: DICT unimplemented"
  | LIST  _ -> failwith "render_value: LIST unimplemented"
  | NULL -> [< >]
  | RENDERED f -> f ()

let render_nullable ~null v : render_t  =
  match v with
    NULL -> null
  | v -> render_value v

let render_list ~sep ~null l : render_t =
  fun () ->
  let rec rerec = function
      [] -> [< >]
    | [h] -> render_nullable ~null h ()
    | h::t ->
       [< render_nullable ~null h () ;
        sep () ;
        rerec t >] in
  rerec l

let render_attr_value v : render_t =
  fun () ->
  match v with
    SV v -> render_value v ()
  | MV l -> render_list ~sep:(fun () -> [< >]) ~null:(fun () -> [< >]) l ()

let rec option_value ctxt env indent key options =
  match List.assoc_opt key options with
    (None | Some None) -> (fun _ -> [< >])
  | Some (Some me) ->
     match eval_mexpr ctxt env indent me with
       ((SV v)|(MV[v])) -> render_value v
     | MV _ -> Fmt.(failwithf "%s: value must be single-value" key)

and eval_mexpr ctxt env indent = function
    ME_PRIMARY p -> eval_mexpr_primary ctxt env indent p

and eval_mexpr_primary ctxt env indent = function
    ME_ID varname ->
     match lookup_opt ctxt env varname with
       None -> SV NULL
     | Some v -> v
    
and eval_expr_tag ctxt env indent ((me, options) : expr_tag_t) : attr_val_t =
  let rv = eval_mexpr ctxt env indent me in
  match rv with
  | SV v -> begin
      match List.assoc_opt "null" options with
        None -> rv
      | Some _ ->
         let null_value = option_value ctxt env indent "null" options in
         SV (RENDERED (render_nullable ~null:null_value v))
    end
 | MV l ->
     match List.assoc_opt "separator" options with
       None -> rv
     | Some _ ->
        let sep_value = option_value ctxt env indent "separator" options in
        let null_value = option_value ctxt env indent "null" options in
        SV (RENDERED (render_list ~sep:sep_value ~null:null_value l))

and eval_literal ctxt env indent = function
    TEXT s -> RENDERED (fun () -> [< 'LITERAL(TEXT s) >])
| HORZ_WS s -> RENDERED (fun () -> [< 'LITERAL(HORZ_WS s) >])
| VERT_WS s -> RENDERED (fun () -> [< 'LITERAL(VERT_WS s) ; 'INDENT indent >])

and eval_element ctxt env indent e : attr_val_t =
  match e with
    LIT lit -> SV (eval_literal ctxt env indent lit)
  | EXPR_TAG et -> eval_expr_tag ctxt env indent et
  | IFSTAT (me_cond, thenl, thenifl, elsel_opt) ->
     let rec irec l =
       match (l,elsel_opt) with
         ([], None) -> SV NULL
       | ([], Some l) -> eval_elements ctxt env indent l
       | (((me_cond,thenl)::l), _) ->
          if eval_cond ctxt env me_cond then
            eval_elements ctxt env indent thenl
          else irec l in
     irec ((me_cond, thenl)::thenifl)

and eval_elements ctxt env indent l =
  match l with
    [h] -> eval_element ctxt env indent h
  | _ ->
     SV (RENDERED (fun () ->
  let rec erec = function
      [] -> [< >]
    | h::t -> [< render_attr_value (eval_element ctxt env indent h) () ; erec t >]
  in erec l))

and eval_cond ctxt env me_cond : bool =
  match me_cond with
  COND_ATOM me -> begin
      match eval_mexpr ctxt env Indent.mt me with
        SV NULL -> false
      | SV (BOOL b) -> b
      | _ -> true
    end
| COND_NOT c -> not(eval_cond ctxt env c)
| COND_AND (c1,c2) ->
   (eval_cond ctxt env c1) && (eval_cond ctxt env c2)
| COND_OR (c1,c2) ->
   (eval_cond ctxt env c1) || (eval_cond ctxt env c2)

end
