(**pp -syntax camlp5o -package pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.located_sexp,pa_ppx.utils,pa_ppx_regexp,pa_ppx.import *)

open Pa_ppx_base
open Ppxutil
open Pa_ppx_utils
open Coll

open Antlr
open Sttypes2
open Stg_types

module STPa = Pa.STG2_STPa
module STGPa = Pa.STG2_STGPa

module Intern = struct
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

let mk() = Int._mk ([],[],[])

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

module OutputToken = struct
open Pa_ppx_located_sexp.Sexp
  type t = [%import: Sttypes2.literal_t]
             [@@deriving show,located_sexp {exn=true}]

  type _render_t =
    LITS of t list
  | RLIST of _render_t list

  let rec flatten = function
      LITS l -> l
    | RLIST l -> List.concat_map flatten l

  let pp_render_t_0 pps (x : _render_t) =
    let s =
      x
      |> flatten
      |> Std.stream_of_list
      |> FIW.render_stream
      |> Std.list_of_stream
      |> String.concat ""
    in Fmt.(pf pps "#<render< %s >>" s)

  type render_t = _render_t
                    [@printer pp_render_t_0]
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
    group : Group.t
  ; warning : string -> unit
  ; error : string -> unit
  }

let warning ctxt s = ctxt.warning s
let error ctxt s = ctxt.error s

let lookup_template ctxt qid =
  assert (not qid.rooted) ;
  assert (List.length qid.ids = 1) ;
  let id = List.hd qid.ids in
  let id = if MHM.in_dom ctxt.group.aliases id then
             MHM.map ctxt.group.aliases id
           else id in
  if not (MHM.in_dom ctxt.group.templates id) then
    Fmt.(failwithf "lookup_template: template %a not found" pp_qualified_id_t qid) ;
  MHM.map ctxt.group.templates id

let default_warning s =  Fmt.(pf stderr "%s@." s)
let default_error s = Fmt.(failwithf "%s@." s)

let mk group = {
    group
  ; warning = default_warning
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
  match v with
    STRING s -> LITS [(TEXT s)]
  | BOOL b -> LITS [(TEXT (if b then "true" else "false"))]
  | INT n -> LITS [(TEXT (string_of_int n))]
  | DICT _ -> failwith "render_value: DICT unimplemented"
  | LIST  _ -> failwith "render_value: LIST unimplemented"
  | NULL -> LITS []
  | RENDERED x -> x

let render_nullable ~null v : render_t  =
  match v with
    NULL -> null
  | v -> render_value v

let render_list ~sep ~null l : render_t =
  let rec rerec = function
      [] -> RLIST []
    | [h] -> render_nullable ~null h
    | h::t ->
       RLIST [render_nullable ~null h;
        sep ;
        rerec t] in
  rerec l

let bind_formal_arg vname (v : value_t) : Environ.binding_t =
  match v with
    VALUE_TEMPLATE t -> (vname, MEXPR (ME_TEMPLATE (MTR_TEMPLATE t)))
  | VALUE_SUBTEMPLATE st -> (vname, MEXPR (ME_TEMPLATE (MTR_SUB st)))
  | VALUE_BOOL b -> (vname, SV (BOOL b))
  | VALUE_MT_DICT -> (vname, MV [])

let filter_loopback_bindings bl =
  bl
  |> List.filter (function
           (v, MEXPR (ME_PRIMARY (ME_ID v'))) when v = v' -> false
         | _ -> true)

let render_attr_value v : render_t =
  match v with
    SV v -> render_value v
  | MV l -> render_list ~sep:(RLIST []) ~null:(RLIST[]) l

let attrval_map f (av : attr_val_t) : attr_val_t list =
  match av with
    MEXPR _ -> failwith "attrval_map: Internal error: MEXPR should never be found here"
  | SV NULL -> [SV NULL]
  | SV _ -> [f av]
  | MV l -> List.filter_map (function NULL -> None | v -> Some (f (SV v))) l

let attrval_mapi f (av : attr_val_t) : attr_val_t list =
  match av with
    MEXPR _ -> failwith "attrval_map: Internal error: MEXPR should never be found here"
  | SV NULL -> [SV NULL]
  | SV _ -> [f 0 av]
  | MV l ->
     let rec maprec i = function
         [] -> []
       | NULL::t -> (SV NULL)::(maprec i t)
       | v::t -> (f i (SV v))::(maprec (i+1) t)
     in maprec 0 l

let attrval_list_mapi (f : int -> attr_val_t list -> attr_val_t) (av_l : attr_val_t list) : attr_val_t list =
  let vl_l = List.map (function
                   MEXPR _ -> failwith "attrval_list_map: Internal error: MEXPR should never be found here"
                 | SV v -> [v]
                 | MV l -> l) av_l in
  let vl_array = Array.of_list vl_l in
  let has_values () = Array.exists (fun v -> v <> []) vl_array in
  let get_values () : attr_val_t list =
    vl_array
    |> Array.mapi (fun i v ->
           match v with
             [] -> SV NULL
           | h::t -> 
              vl_array.(i) <- t ;
              SV h)
    |> Array.to_list in
  
  let rec genrec i =
    if not (has_values()) then []
    else
      let v = get_values() in
      (f i v)::(genrec (i+1))
  in genrec 0

let attrval_list_map f (av_l : attr_val_t list) : attr_val_t list =
  attrval_list_mapi (fun i v -> f v) av_l

let attrval_append av1 av2 : attr_val_t =
  match (av1, av2) with
    (SV v1, SV v2) -> MV [v1; v2]
  | (SV v1, MV l) -> MV (v1::l)
  | (MV l, SV v2) -> MV (l@[v2])
  | (MV l1, MV l2) -> MV(l1@l2)
| ((MEXPR _, _)|(_, MEXPR _)) ->
     failwith "attrval_append: Internal error: MEXPR should never be found here"

let attrval_concat (l : attr_val_t list) : attr_val_t =
  List.fold_left attrval_append (MV[]) l

let flatten_MTR_CAT mtr =
  let rec flatrec = function
      MTR_CAT(mtr1, mtr2) ->
      (flatrec mtr1)@(flatrec mtr2)
    | mtr -> [mtr]
in flatrec mtr

let flatten_ME_CAT me =
  let rec flatrec = function
      ME_CAT(me1, me2) ->
      (flatrec me1)@(flatrec me2)
    | me -> [me]
in flatrec me

let rec option_value ctxt env key options =
  match List.assoc_opt key options with
    (None | Some None) -> (RLIST[])
  | Some (Some me) ->
     match eval_mexpr ctxt env me with
       ((SV v)|(MV[v])) -> render_value v
     | MV _ -> Fmt.(failwithf "%s: value must be single-value" key)

and eval_mexpr_arg_by_value ctxt env = function
    ME_TEMPLATE (MTR_SUB _) as me -> MEXPR me
  | ME_PRIMARY (ME_ID varname) -> begin
      match lookup_opt ctxt env varname with
        None -> SV NULL
      | Some ((SV _ | MV _) as v) -> v
      | Some (MEXPR me) -> eval_mexpr_arg_by_value ctxt env me
    end
  | me -> eval_mexpr ctxt env me

and eval_mexpr ctxt env = function
    ME_PRIMARY p -> eval_mexpr_primary ctxt env p

  | ME_MAP (ME_CAT _ as me1, mtr2) as me ->
     let me_l = flatten_ME_CAT me1 in
     let attrval_l = List.map (eval_mexpr ctxt env) me_l in
     eval_mexpr_template_ref_multi ctxt env attrval_l mtr2     

  | ME_MAP (me1, (MTR_CAT _ as mtr2)) ->
     let mtr_l = flatten_MTR_CAT mtr2 in
     let n = List.length mtr_l in
     let attrval = eval_mexpr ctxt env me1 in
     begin
       match attrval with
         MEXPR _ -> failwith "eval_mexpr: internal error: should never see MEXPR here"
       | SV _ -> eval_mexpr_template_ref ctxt env attrval (List.hd mtr_l)
       | MV l ->
          l
          |> List.mapi (fun i v ->
                 eval_mexpr_template_ref ctxt env (SV v) (List.nth mtr_l (i mod n)))
          |> attrval_concat
     end

  | ME_MAP (me1, mtr2) ->
     let attrval = eval_mexpr ctxt env me1 in
     eval_mexpr_template_ref ctxt env attrval mtr2

  | ME_TEMPLATE (MTR_INCLUDE (qid, args)) ->
     let t = Context.lookup_template ctxt qid in
     let formals = t.formals in
     let body = t.body in
     let bindings =
       match args with
         ARGS_EMPTY ->
          if formals |> List.exists (function (_, None) -> true | _ -> false) then
            Fmt.(failwith "eval_mexpr: no-arg include calls template with args that require values") ;
          List.filter_map (function (vname, Some rhs) -> Some (bind_formal_arg vname rhs) | _ -> None) formals

         | ARGS_NAMED (named_actuals, ellipsis) ->
            formals
            |> List.map (fun (vname, dflt_opt) ->
                   match (List.assoc_opt vname named_actuals, dflt_opt) with
                     (Some rhs, _) ->
                      let attrval = eval_mexpr_arg_by_value ctxt env rhs in
                      (vname, attrval)
                   | (None, Some rhs) -> bind_formal_arg vname rhs
                   | _ when not ellipsis ->
                      Fmt.(failwithf "eval_mexpr: var %s has no arg (and ellipsis not present)" vname))

         | ARGS_LIST actuals ->
            formals
            |> List.mapi (fun i (vname, dflt_opt) ->
                   match (List.nth_opt actuals i, dflt_opt) with
                     (Some rhs, _) ->
                      let attrval = eval_mexpr_arg_by_value ctxt env rhs in
                      (vname, attrval)
                   | (None, Some rhs) -> bind_formal_arg vname rhs
                   | _ ->
                      Fmt.(failwithf "eval_mexpr: var %s has no arg (too few actuals)" vname)) in
     let bindings = filter_loopback_bindings bindings in
     eval_elements ctxt (Environ.push_frame bindings env) body

  | ME_TEMPLATE (MTR_TEMPLATE t) ->
     eval_elements ctxt env t

  | ME_TEMPLATE (MTR_SUB (ids, t)) ->
     assert (ids = []) ;
     eval_elements ctxt env t

  | me ->
     Fmt.(pf stderr "eval_mexpr: unhandled@.%a@."
            pp_mexpr_t me) ;
     failwith "eval_mexpr: unhandled case"

and eval_mexpr_template_ref_multi ctxt env attrval_l mtr =
  let nattrs = List.length attrval_l in
  attrval_l
  |> attrval_list_mapi (fun i attrval_l ->
         match mtr with
           MTR_INCLUDE (qid, args) ->
           let t = Context.lookup_template ctxt qid in
           let formals = t.formals in
           if List.length formals < nattrs then
             Fmt.(failwithf "eval_mexpr_template_ref_multi:#formals %d < #attrvals %d"
                    (List.length formals) nattrs) ;
           let (firsts, rests) = Std.sep_firstn nattrs formals in
           let firstvars = List.map fst firsts in
           let argexps = List.map (fun v -> ME_PRIMARY(ME_ID v)) firstvars in
           let body = t.body in
           let args = match args with
               ARGS_NAMED _ -> failwith "eval_mexpr_template_ref_multi: named args not permitted here"
             | ARGS_EMPTY -> ARGS_LIST argexps
             | ARGS_LIST l -> ARGS_LIST (argexps@l)
           in
           let env = Environ.push_frame (List.map2 (fun v av -> (v, av)) firstvars attrval_l) env in
           eval_mexpr ctxt env (ME_TEMPLATE (MTR_INCLUDE (qid, args)))

           | MTR_SUB (ids, t) ->
              if List.length ids <> nattrs then
                Fmt.(failwithf "eval_mexpr_template_ref_multi:# subtemplate formals %d <> #attrvals %d"
                       (List.length ids) nattrs) ;

              let binding = List.map2 (fun v av -> (v, av)) ids attrval_l in
              let binding = [("i0", SV (STRING (string_of_int i)))
                            ;("i", SV (STRING (string_of_int (i+1))))]@binding in
              let env = Environ.push_frame binding env in
              eval_elements ctxt env t
              
           | metr ->
              Fmt.(pf stderr "eval_mexpr_template_ref_multi: unhandled@.%a@."
                     pp_mexpr_template_ref_t metr) ;
              failwith "eval_mexpr_template_ref_multi: unhandled case"
       )
  |> attrval_concat


and eval_mexpr_template_ref ctxt env attrval = function
    MTR_INCLUDE (qid, args) ->
     let t = Context.lookup_template ctxt qid in
     let formals = t.formals in
     let body = t.body in
     let varname = fst (List.hd formals) in
     let args = match args with
         ARGS_NAMED _ -> failwith "eval_mexpr_template_ref: named args not permitted here"
       | ARGS_EMPTY -> ARGS_LIST [ME_PRIMARY(ME_ID varname)]
       | ARGS_LIST l -> ARGS_LIST ((ME_PRIMARY(ME_ID varname))::l)
     in
     attrval
     |> attrval_map (fun attrval ->
            let env = Environ.push_frame [(varname, attrval)] env in
            eval_mexpr ctxt env (ME_TEMPLATE (MTR_INCLUDE (qid, args))))
     |> attrval_concat

  | MTR_SUB (ids, t) ->
     assert (List.length ids = 1) ;
     let varname = List.hd ids in
     attrval
     |> attrval_mapi (fun i attrval ->
            let env = Environ.push_frame [("i0", SV (STRING (string_of_int i)))
                                         ;("i", SV (STRING (string_of_int (i+1))))
                                         ;(varname, attrval)] env in
            eval_elements ctxt env t)
     |> attrval_concat

  | metr ->
    Fmt.(pf stderr "eval_mexpr_template_ref: unhandled@.%a@."
           pp_mexpr_template_ref_t metr) ;
    failwith "eval_mexpr_template_ref: unhandled case"

and eval_mexpr_primary ctxt env = function
    ME_ID varname -> begin
      match lookup_opt ctxt env varname with
        None -> SV NULL
      | Some ((SV _ | MV _) as v) -> v
      | Some (MEXPR me) -> eval_mexpr ctxt env me
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
     SV (RENDERED (LITS lits))

  | ME_BOOL b -> SV (BOOL b)
  | ME_LIST l ->
     let eval1 = function
         None -> [NULL]
       | Some me -> begin
           match eval_mexpr ctxt env me with
             SV v -> [v]
           | MV l -> l
         end in
     MV (List.concat_map eval1 l)

and eval_expr_tag ctxt env ((me, options) : expr_tag_t) : attr_val_t =
  let rv = eval_mexpr ctxt env me in
  match rv with
  | SV v -> begin
      match List.assoc_opt "null" options with
        None -> rv
      | Some _ ->
         let null_value = option_value ctxt env "null" options in
         SV (RENDERED (render_nullable ~null:null_value v))
    end
 | MV l ->
     match List.assoc_opt "separator" options with
       None -> rv
     | Some _ ->
        let sep_value = option_value ctxt env "separator" options in
        let null_value = option_value ctxt env "null" options in
        SV (RENDERED (render_list ~sep:sep_value ~null:null_value l))

and eval_literal ctxt env lit =
  RENDERED (LITS[lit])

and eval_element ctxt env e : attr_val_t =
  match e with
    LIT lit -> SV (eval_literal ctxt env lit)
  | EXPR_TAG et -> eval_expr_tag ctxt env et
  | IFSTAT (me_cond, thenl, thenifl, elsel_opt) ->
     let rec irec l =
       match (l,elsel_opt) with
         ([], None) -> SV NULL
       | ([], Some l) -> eval_elements ctxt env l
       | (((me_cond,thenl)::l), _) ->
          if eval_cond ctxt env me_cond then
            eval_elements ctxt env thenl
          else irec l in
     irec ((me_cond, thenl)::thenifl)

and eval_elements ctxt env l =
  match l with
    [h] -> eval_element ctxt env h
  | _ ->
     let rec erec = function
         [] -> RLIST []
       | h::t -> RLIST [render_attr_value (eval_element ctxt env h) ; erec t]
     in
     SV (RENDERED (erec l))

and eval_cond ctxt env me_cond : bool =
  match me_cond with
  COND_ATOM me -> begin
      match eval_mexpr ctxt env me with
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
