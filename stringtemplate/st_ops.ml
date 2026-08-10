(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx_migrate,pa_ppx.import *)

open St_types

module Migrate = struct
exception Migration_error of string

let migration_error feature =
  raise (Migration_error feature)

let _migrate_list subrw0 __dt__ l =
  List.map (subrw0 __dt__) l

[%%typedecls
  [%%import: St_types.template_t]
  [%%import: St_types.qualified_id_t]
]
[@@deriving migrate
    { dispatch_type = dispatch_table_t
    ; dispatch_table_constructor = make_dt
    ; default_dispatchers = [
        {
          srcmod = St_types
        ; dstmod = St_types
        ; types = [
            arg_expr_list_t
          ; args_t
          ; conditional_t
          ; elements_t
          ; element_t
          ; expr_options_t
          ; expr_option_t
          ; expr_t
          ; expr_tag_t
          ; include_expr_arg_t
          ; include_expr_t
          ; list_element_t
          ; map_expr_t
          ; map_template_ref_t
          ; member_expr_t
          ; named_arg_t
          ; primary_t
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
        (TEXT s)::tacc in

  let rec corec tacc stracc = function
      [] ->
       let tacc = finish_stracc tacc stracc in
       List.rev tacc
    | (TEXT s)::l -> corec tacc (s::stracc) l
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
