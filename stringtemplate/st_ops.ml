(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.import,pa_ppx_migrate *)

open Pa_ppx_utils

open Sttypes2

module Migrate = struct
exception Migration_error of string

let migration_error feature =
  raise (Migration_error feature)

let _migrate_list subrw0 __dt__ l =
  List.map (subrw0 __dt__) l

[%%typedecls
  [%%import: Sttypes2.template_t]
  [%%import: Sttypes2.qualified_id_t]
]
[@@deriving migrate
    { dispatch_type = dispatch_table_t
    ; dispatch_table_constructor = make_dt
    ; default_dispatchers = [
        {
          srcmod = Sttypes2
        ; dstmod = Sttypes2
        ; types = [
            args_t
          ; elements_t
          ; element_t
          ; expr_tag_t
          ; literal_t
          ; mexpr_cond_t
          ; mexpr_primary_t
          ; mexpr_t
          ; mexpr_template_ref_t
          ; qualified_id_t
          ; subtemplate_t
          ; template_t
          ]
        }
      ]
    ; dispatchers = {
        migrate_list = {
          srctype = [%typ: 'a list]
        ; dsttype = [%typ: 'b list]
        ; code = _migrate_list
        ; subs = [ ([%typ: 'a], [%typ: 'b]) ]
        }
      ; migrate_option = {
          srctype = [%typ: 'a option]
        ; dsttype = [%typ: 'b option]
        ; subs = [ ([%typ: 'a], [%typ: 'b]) ]
        ; code = (fun subrw __dt__ x -> Option.map (subrw __dt__) x)
        }
      }
    }
]

end

let coalesce1 (l : template_t) : template_t =
  let finish_stracc tacc stracc =
    match stracc with
      [] -> tacc
    | strl ->
       let s = String.concat "" (List.rev strl) in
        (LIT (TEXT s))::tacc in

  let rec corec tacc stracc = function
      [] ->
       let tacc = finish_stracc tacc stracc in
       List.rev tacc
    | (LIT (TEXT s))::l -> corec tacc (s::stracc) l
    | h::l ->
       let tacc = finish_stracc tacc stracc in
       corec (h::tacc) [] l
  in
  corec [] [] l

let coalesce t =
  let dt = Migrate.make_dt() in
  let old_migrate_elements_t = dt.migrate_elements_t in
  let migrate_elements_t __dt__ t =
    let t = old_migrate_elements_t __dt__ t in
    coalesce1 t in
  let dt = { (dt) with migrate_elements_t } in
  dt.migrate_elements_t dt t

let coalesce_subtemplate t =
  let dt = Migrate.make_dt() in
  let old_migrate_elements_t = dt.migrate_elements_t in
  let migrate_elements_t __dt__ t =
    let t = old_migrate_elements_t __dt__ t in
    coalesce1 t in
  let dt = { (dt) with migrate_elements_t } in
  dt.migrate_subtemplate_t dt t

let coalesce_mexpr t =
  let dt = Migrate.make_dt() in
  let old_migrate_elements_t = dt.migrate_elements_t in
  let migrate_elements_t __dt__ t =
    let t = old_migrate_elements_t __dt__ t in
    coalesce1 t in
  let dt = { (dt) with migrate_elements_t } in
  dt.migrate_mexpr_t dt t

let removews1 (l : template_t) : template_t =
  l
  |> List.filter_map
       (function
          LIT (TEXT _) as x -> Some x
       | _ -> None)

let removews t =
  let dt = Migrate.make_dt() in
  let old_migrate_elements_t = dt.migrate_elements_t in
  let migrate_elements_t __dt__ t =
    let t = old_migrate_elements_t __dt__ t in
    removews1 t in
  let dt = { (dt) with migrate_elements_t } in
  dt.migrate_elements_t dt t


(** insert_indentation0 takes an [element list] and replaces HORZ_WS
    immediately following VERT_WS with INDENT; if it does so, then
    before the next VERT_WS, it inserts a DEDENT.  There can only be
    one HORZ_WS, so this will guarantee balance (one INDENT, one
    DEDENT).

    If there is no last VERT_WS, it inserts the DEDENT at the end.
 *)

let insert_indentation0 t =
  let open Sttypes2 in
  let rec balrec indented acc = function
      (LIT(VERT_WS _))::_ as l when indented ->
       let acc = (LIT DEDENT)::acc in
       balrec false acc l

    | (LIT(VERT_WS _) as e1)::(LIT(HORZ_WS s))::tl when not indented ->
      let acc = (e1::acc) in
      let acc = (LIT(INDENT s))::acc in
      balrec true acc tl

    | (LIT(VERT_WS _) as e1)::tl when not indented ->
      let acc = (e1::acc) in
      balrec false acc tl

    | [] when indented ->
       let acc = (LIT DEDENT)::acc in
       List.rev acc

    | [] -> List.rev acc

    | h::tl -> balrec indented (h::acc) tl

  in
  let acc = [] in
  match t with
    (LIT(HORZ_WS s))::tl ->
    let acc = (LIT(INDENT s))::acc in
    balrec true acc tl

  | _ -> balrec false [] t

let insert_indentation t =
  let dt = Migrate.make_dt() in
  let old_migrate_elements_t = dt.migrate_elements_t in
  let migrate_elements_t __dt__ t =
    let t = old_migrate_elements_t __dt__ t in
    insert_indentation0 t in
  let dt = { (dt) with migrate_elements_t } in
  dt.migrate_elements_t dt t

let insert_indentation_subtemplate t =
  let dt = Migrate.make_dt() in
  let old_migrate_elements_t = dt.migrate_elements_t in
  let migrate_elements_t __dt__ t =
    let t = old_migrate_elements_t __dt__ t in
    insert_indentation0 t in
  let dt = { (dt) with migrate_elements_t } in
  dt.migrate_subtemplate_t dt t

let insert_indentation_mexpr t =
  let dt = Migrate.make_dt() in
  let old_migrate_elements_t = dt.migrate_elements_t in
  let migrate_elements_t __dt__ t =
    let t = old_migrate_elements_t __dt__ t in
    insert_indentation0 t in
  let dt = { (dt) with migrate_elements_t } in
  dt.migrate_mexpr_t dt t

let balanced_indentation0 t =
  let indents = List.filter (function LIT (INDENT _) -> true | _ -> false) t in
  let dedents = List.filter (function LIT DEDENT -> true | _ -> false) t in
  List.length indents = List.length dedents

let balanced_indentation t =
  let exception Caught in
  let dt = Migrate.make_dt() in
  let old_migrate_elements_t = dt.migrate_elements_t in
  let migrate_elements_t __dt__ t =
    let t = old_migrate_elements_t __dt__ t in
    if not (balanced_indentation0 t) then
      raise Caught ;
    t
  in
  let dt = { (dt) with migrate_elements_t } in
  try
    dt.migrate_elements_t dt t ;
    true
  with Caught -> false

let nuke_first_lf t =
  match t with
    (LIT (VERT_WS s))::l ->
    let s = [%subst {|^\n|} / {||} / s] s in
    if s <> "" then
      (LIT (VERT_WS s))::l
    else l

let nuke_last_lf t =
  if t = [] then []
  else
    match Std.sep_last t with
      (LIT (VERT_WS "\n")),rest -> rest
    | (LIT (VERT_WS s)),rest ->
       let s = [%subst {|\n$|} / {||} / s] s in
       rest@[(LIT (VERT_WS s))]
