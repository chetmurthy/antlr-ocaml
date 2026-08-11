(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.import,pa_ppx_migrate *)

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
