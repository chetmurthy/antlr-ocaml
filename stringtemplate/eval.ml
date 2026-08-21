(**pp -syntax camlp5o -package pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.located_sexp,pa_ppx.utils,pa_ppx_regexp,pa_ppx.import *)

open Pa_ppx_base
open Ppxutil
open Pa_ppx_utils

open Antlr
open Sttypes2
open Stg_types

module STPa = Pa.STG2_STPa
module STGPa = Pa.STG2_STGPa

module Intern = struct
  open Coll
  open Cooked

  let dict_value = function
      Raw.KEYVAL_BIGSTRING (loc, s) ->
      (loc, s)
      |> St_util.unwrap_stg_bigstring
      |> STPa.Template.of_located_string
      |> St_ops.coalesce
      |> St_ops.insert_indentation
      |> (fun t -> DVAL_VALUE (VALUE_TEMPLATE t))
    | KEYVAL_BIGSTRING_NO_NL (loc, s) ->
       (loc, s)
       |> St_util.unwrap_stg_bigstring_no_nl
       |> STPa.Template.of_located_string
       |> St_ops.coalesce
       |> (fun t -> DVAL_VALUE (VALUE_TEMPLATE t))
    | KEYVAL_STRING (loc, s) ->
       (loc, s)
       |> St_util.unescape_stg_string 
       |> STPa.Template.of_located_string
       |> St_ops.coalesce
       |> St_ops.insert_indentation
       |> (fun t -> DVAL_VALUE(VALUE_TEMPLATE t))

    | KEYVAL_SUBTEMPLATE st ->
       st
       |> St_ops.coalesce_subtemplate
       |> (fun st -> DVAL_VALUE(VALUE_SUBTEMPLATE st))

    | KEYVAL_BOOL b -> DVAL_VALUE(VALUE_BOOL b)
    | KEYVAL_MT_DICT -> DVAL_VALUE VALUE_MT_DICT
    | KEYVAL_KEY -> DVAL_KEY

  let dict loc (name,(kv,dflt_opt)) : string * Cooked.dict_t =
    let kv =
      kv
      |> List.map (fun (k, v) ->
             (snd (St_util.unescape_stg_string k),
              dict_value v)) in
    let kv = MHM.ofList 23 kv in
    let default = Option.map dict_value dflt_opt in
    (name, { loc ; kv ; default })

  let template_def loc (name, formals,  rhs) : string * Cooked.template_def_t =
    let open Raw in
    let formals =
      formals
      |> List.map (fun (argname, dflt_opt) ->
             let dflt_opt =
               dflt_opt
               |> Option.map (function
                        FORMAL_STRING s ->
                         s
                         |> St_util.unescape_stg_string
                         |> STPa.Template.of_located_string
                         |> St_ops.coalesce
                         |> St_ops.insert_indentation
                         |> (fun s -> VALUE_TEMPLATE s)

                      | FORMAL_SUBTEMPLATE st ->
                         st
                         |> St_ops.coalesce_subtemplate
                         |> St_ops.insert_indentation_subtemplate
                         |> (fun st -> VALUE_SUBTEMPLATE st)

                      | FORMAL_BOOL b -> VALUE_BOOL b
                      | FORMAL_MT_DICT -> VALUE_MT_DICT) in
             (argname,dflt_opt)) in
    let body =
      match rhs with
        TDEF_STRING s ->
         s
         |> St_util.unescape_stg_string
         |> STPa.Template.of_located_string
         |> St_ops.coalesce
         |> St_ops.insert_indentation

      | TDEF_BIGSTRING s ->
         s
         |> St_util.unwrap_stg_bigstring
         |> STPa.Template.of_located_string
         |> St_ops.coalesce
         |> St_ops.insert_indentation

      | TDEF_BIGSTRING_NO_NL s ->
         s
         |> St_util.unwrap_stg_bigstring_no_nl
         |> STPa.Template.of_located_string
         |> St_ops.coalesce
    in
    let t = {
        loc
      ; name
      ; formals
      ; body
      } in
    (name, t)

end

module Group = struct
  open Coll
  open Cooked
  type t = {
      dicts : (string, dict_t) MHM.t
    ; templates : (string, template_def_t) MHM.t
    ; aliases : (string, string) MHM.t
    }

  let intern_group raw =
    let open Raw in
    let rawdicts =
      raw.defs |> List.filter (function GROUPDEF_DICT _ -> true | _ -> false) in
    let rawdefs =
      raw.defs |> List.filter (function GROUPDEF_TEMPLATE_DEF _ -> true | _ -> false) in
    let rawaliases =
      raw.defs |> List.filter (function GROUPDEF_TEMPLATE_ALIAS _ -> true | _ -> false) in

    let defs = List.map (function GROUPDEF_TEMPLATE_DEF (loc, name, formals, rhs)
                                  -> Intern.template_def loc (name, formals, rhs))
                 rawdefs in
    let aliases = List.map (function GROUPDEF_TEMPLATE_ALIAS (loc, name, alias)
                                  -> (name, alias))
                    rawaliases in
    let dicts = List.map (function GROUPDEF_DICT (loc, d)
                                   -> Intern.dict loc d)
                  rawdicts in
    (defs, aliases, dicts)

  let merge1 (defs1, aliases1, dicts1) (defs2, aliases2, dicts2) =
    let defnames1 = (List.map fst defs1)@(List.map fst aliases1) in
    let defnames2 = (List.map fst defs2)@(List.map fst aliases2) in
    if [] <> Std.intersect defnames1 defnames2 then
      Fmt.(failwithf "Group.merge: two parallel imports define the same template-names: %a@."
             (list string) (Std.intersect defnames1 defnames2)) ;
    let dictnames1 = List.map fst dicts1 in
    let dictnames2 = List.map fst dicts2 in
    if [] <> Std.intersect dictnames1 dictnames2 then
      Fmt.(failwithf "Group.merge: two parallel imports define the same dictionary-names: %a@."
             (list string) (Std.intersect dictnames1 dictnames2)) ;
    (defs1@defs2, aliases1@aliases2, dicts1@dicts2)

  let merge_imports ~imported:(imp_defs, imp_aliases, imp_dicts) (defs, aliases, dicts) =
    let upsert m (k,v) =
      let m =
        if List.mem_assoc k m then
          List.remove_assoc k m
        else m in
      (k,v)::m in
    let defs = List.fold_left upsert imp_defs defs in
    let aliases = List.fold_left upsert imp_aliases aliases in
    let dicts = List.fold_left upsert imp_dicts dicts in
    (defs, aliases, dicts)

  let check_st_constraint ~stg raw =
    let open Raw in
    if not stg then begin
        if not Fpath.(raw.filename |> v |> has_ext "st") then
          Fmt.(raise_failwith raw.loc "check_st_constraint: internal error: was not a .st file even though that's what we expected: %a@." raw.filename) ;
        let basename = Fpath.(raw.filename |> v |> rem_ext |> basename) in
        if raw.imports <> [] then
          Fmt.(raise_failwith raw.loc "check_st_constraint: .st file cannot have imports") ;
        begin
          match raw.defs with
            (_::_::_)|[] ->
             Fmt.(raise_failwith raw.loc "check_st_constraint: .st file must contain exact ONE entry") ;
          | [(GROUPDEF_TEMPLATE_DEF (_, tname, _, _)
              | GROUPDEF_TEMPLATE_ALIAS (_, tname, _))] when tname = basename -> ()
          | [(GROUPDEF_TEMPLATE_DEF (_, tname, _, _)
              | GROUPDEF_TEMPLATE_ALIAS (_, tname, _))] ->
             Fmt.(raise_failwith raw.loc "check_st_constraint: .st file must contain exact ONE template-def or alias with same name (%a) as file's basename (%a)"
                    Dump.string tname Dump.string basename)
          | [GROUPDEF_DICT _] ->
             Fmt.(raise_failwith raw.loc "check_st_constraint: .st file cannot contain dict") ;
        end
      end

module Int = struct
  let rec of_located_string ?(filecache=[]) ~stg locs =
    let raw = STGPa.Group.of_located_string locs in
    check_st_constraint ~stg raw ;
    let imported = read_imports ~filecache raw in
    let interned = intern_group raw in
    merge_imports ~imported interned

  and of_here_string ?(filecache=[]) ~stg locs =
    let raw = STGPa.Group.of_here_string locs in
    check_st_constraint ~stg raw ;
    let imported = read_imports ~filecache raw in
    let interned = intern_group raw in
    merge_imports ~imported interned

  and load ?(filecache=[]) ~file =
    let file_exists file =
      List.mem_assoc file filecache ||
        file |> Fpath.v |> Bos.OS.File.exists |> Rresult.R.failwith_error_msg in
    let (file,stg) =
      if Fpath.(file |> v |> has_ext "st") && file_exists file then
        (file, false)
      else if Fpath.(file |> v |> has_ext "stg") && file_exists file then
        (file, true)
      else if file_exists (file^".st") then
        (file^".st",false)
      else if file_exists (file^".stg") then
        (file^".stg",true)
      else Fmt.(failwithf "Group.load: no such file %a@." Dump.string file) in
    load1 ~filecache ~stg ~file
    
  and load1 ?(filecache=[]) ~stg ~file =
    let raw =
      match List.assoc_opt file filecache with
        Some x ->
         let g = STGPa.Group.of_located_string x in
         { (g) with filename = file }
      | None -> STGPa.Group.load ~file in
    check_st_constraint ~stg raw ;
    let imported = read_imports ~filecache raw in
    let interned = intern_group raw in
    merge_imports ~imported interned

  and read_imports ?(filecache=[]) raw =
    let files = raw.Raw.imports in
    let imported_l = List.map (fun file -> load ~filecache ~file) files in
    List.fold_left merge1 ([], [], []) imported_l

let mk_filecache here_filecache ploc_filecache =
  (List.map (fun (fname, (pos, txt)) -> (fname, (Util.ploc_of_position pos, txt))) here_filecache)
  @ploc_filecache

let _mk (defs, aliases, dicts) =
  {
    dicts = MHM.ofList 23 dicts
  ; templates = MHM.ofList 23 defs
  ; aliases = MHM.ofList 23 aliases
  }

end

let load ?(here_filecache=[]) ?(ploc_filecache=[]) file =
  let filecache = Int.mk_filecache here_filecache ploc_filecache in
  Int._mk (Int.load ~filecache ~file)

let of_located_string ?(here_filecache=[]) ?(ploc_filecache=[]) ~stg locs =
  let filecache = Int.mk_filecache here_filecache ploc_filecache in
  Int._mk (Int.of_located_string ~filecache ~stg locs)

let of_here_string ?(here_filecache=[]) ?(ploc_filecache=[]) ~stg locs =
  let filecache = Int.mk_filecache here_filecache ploc_filecache in
  Int._mk (Int.of_here_string ~filecache ~stg locs)

end


module type INDENT = sig
  type t
  val mt : t
  val add_string : string -> t -> t
  val to_strings : t -> string list
  val pop : t -> t
  val emit : Buffer.t -> t -> unit
end

module Indent : INDENT = struct
  type t = string list

  let mt = []
  let add_string s t = s::t
  let pop t = List.tl t

  let to_strings t = List.rev t

  let emit b t =
    let l = to_strings t in
    List.iter (Buffer.add_string b) l

end

module OutputToken = struct
open Pa_ppx_located_sexp.Sexp
  type t = [%import: Sttypes2.literal_t]

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
    warning : string -> unit
  ; error : string -> unit
  }

let warning ctxt s = ctxt.warning s
let error ctxt s = ctxt.error s

let default_warning s =  Fmt.(pf stderr "%s@." s)
let default_error s = Fmt.(failwithf "%s@." s)

let mk () = {
    warning = default_warning
  ; error = default_error
  }
end

module Environ = struct

let mexpr_t_of_located_sexp =
  let open Pa_ppx_located_sexp in
  function
    Sexp.Atom(loc, s) ->
    (loc,"#inside "^s)
    |> STPa.Mexpr.of_located_string
    |> St_ops.coalesce_mexpr
    |> St_ops.insert_indentation_mexpr
  | se -> Sttypes2.mexpr_t_of_located_sexp se

type attr_val_t = 
  MV of Value.t list
| SV of Value.t
| MEXPR of (Sttypes2.mexpr_t [@of_located_sexp mexpr_t_of_located_sexp])
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

module FIW = struct
  type t = {
      cur_indent : Indent.t
    ; emitted_indent : bool
    }

  let mt = {
      cur_indent = Indent.mt
    ; emitted_indent = false
    }

  let emit t = function
      TEXT s when not t.emitted_indent ->
      ({(t) with emitted_indent = true},
       (Indent.to_strings t.cur_indent)@[s])
    | TEXT s -> (t, [s])
    | HORZ_WS s ->
       (* should not be immediately after a VWS, so a TEXT should have preceded it *)
       assert t.emitted_indent ;
       (t, [s])
    | VERT_WS s ->
       ({(t) with emitted_indent = false}, [s])
    | INDENT s ->
       ({(t) with cur_indent = Indent.add_string s t.cur_indent},
        [])
    | DEDENT ->
       ({(t) with cur_indent = Indent.pop t.cur_indent},
       [])

let render_stream ?(init=mt) strm =
  let rec rerec t = parser
    [< 'lit ; strm >] ->
      let (t, strs) = emit t lit in
      [< Std.stream_of_list strs ; rerec t strm >]
  | [< >] -> [< >]
  in rerec init strm

end
module FunctionalIndentWriter = FIW

module IW = struct
  type _t = {
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
       t.cur_indent <- Indent.add_string  s t.cur_indent

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

open OutputToken

let render_value v : render_t =
  fun () ->
  match v with
    STRING s -> [< '(TEXT s) >]
  | BOOL b -> [< '(TEXT (if b then "true" else "false")) >]
  | INT n -> [< '(TEXT (string_of_int n)) >]
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
    ME_ID varname -> begin
      match lookup_opt ctxt env varname with
        None -> SV NULL
      | Some ((SV _ | MV _) as v) -> v
      | Some (MEXPR me) -> eval_mexpr ctxt env indent me
    end

  | ME_STRING s ->
     let parts = [%split {|([ \t]+)|([\r\n\x0c]+)|} / strings (1,2) pcre2] s in
     let lits =
       parts
       |> List.map (function
                `Text s -> (TEXT s)
              | `Delim (None, Some vws) -> (VERT_WS vws)
              | `Delim (Some hws, None) ->  (HORZ_WS hws)
              | _ -> assert false) in
     SV (RENDERED (fun () -> Std.stream_of_list lits))

  | ME_BOOL b -> SV (BOOL b)
  | ME_LIST l ->
     let eval1 = function
         None -> [NULL]
       | Some me -> begin
           match eval_mexpr ctxt env indent me with
             SV v -> [v]
           | MV l -> l
         end in
     MV (List.concat_map eval1 l)

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

and eval_literal ctxt env indent lit =
  RENDERED (fun () -> [< 'lit >])

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
