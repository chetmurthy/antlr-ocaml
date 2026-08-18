(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.deriving_plugins.std,pa_ppx.import *)

open Pa_ppx_base
open Ppxutil
open Pa_ppx_utils
open Antlr

let unescape_escape_template s =
  let payload =
    match [%match {|^<(.+)>$|} / strings !1] s with
      None ->
      Fmt.(failwithf "St_util.unescape: unrecognized escape %a" Dump.string s)
    | Some s -> s in
  match payload with
    {|\b|} -> "\b"
  | {|\t|} -> "\t"
  | {|\n|} -> "\n"
  | {|\f|} -> "\x0c"
  | {|\r|} -> "\r"
  | {|\"|} -> "\""
  | {|\'|} -> "'"
  | {|\\|} -> "\\"
  | {|\ |} -> " "
  | s ->
     if [%match {|^\\u([0-9a-fA-F]{1,4})$|} / pred] s then
       s |> [%subst {|^\\u([0-9a-fA-F]{1,4})$|} / {|\u{$1}|} / pcre2 ] |> Std.unescape_string
     else Fmt.(failwithf "St_util.unescape: unrecognized escape -payload- %a" Dump.string s)

let unescape_stg_string s =
  let s =
    match [%match {|^"(.*)"$|} / s strings !1] s with
      None ->
      Fmt.(failwithf "unescape_stg_string: malformed string %a" Dump.string s)
    | Some s -> s in
  Util.unescape_string s

let unwrap_stg_bigstring s =
  match [%match {|^<<(.*)>>$|} / s strings !1] s with
    None ->
    Fmt.(failwithf "unwrap_stg_bigstring: malformed string %a" Dump.string s)
  | Some s -> s

let unwrap_stg_bigstring_no_nl s =
  match [%match {|^<%(.*)%>$|} / s strings !1] s with
    None ->
     Fmt.(failwithf "unwrap_stg_bigstring_no_nl: malformed string %a" Dump.string s)
  | Some s -> s  

module type PAHELPER = sig
  type t
  val entry : t Grammar.Entry.e
  val parse_parsable : Grammar.parsable -> t
  val parse : ?startloc:Ploc.t -> char Stream.t -> t
  val of_string : ?startloc:Ploc.t -> string -> t
  val of_here_string : Lexing.position * string -> t
  val input : ?startloc:Ploc.t -> in_channel -> t
  val load : file:string -> t
end


let with_location start_location ?startloc f arg =
  let startloc = match startloc with None -> Ploc.dummy | Some x -> x in
  let old_start_location = !start_location in
  start_location := startloc ;
  Util.finally f
    (fun _ _ -> start_location := old_start_location)
    arg


module PAHelper(M : sig type t
                        val start_location : Ploc.t ref
                        val entry : t Grammar.Entry.e
                    end)
 : (PAHELPER with type t = M.t) = struct
  type t = M.t
  let entry = M.entry
  let parse_parsable = Grammar.Entry.parse_parsable entry

  let parse ?startloc cs =
    with_location M.start_location ?startloc (Grammar.Entry.parse entry) cs

  let of_string ?startloc s =
    s |> Stream.of_string |> parse ?startloc

  let of_here_string (pos, s) =
    let startloc = Util.ploc_of_position pos in
    of_string ~startloc s

  let input ?startloc ic =
    with_location M.start_location ?startloc (fun ic -> ic |> Stream.of_channel |> Grammar.Entry.parse entry) ic

  let load ~file =
    let ic = open_in file in
    let startloc = Ploc.make_loc file 1 0 (0,0) "" in
    Util.finally (input ~startloc)
      (fun _ _ -> close_in ic)
      ic
end

type raw = Antlr.Exec.T.token_t
[@@deriving show { with_path = false }]


type ploc_t = Ploc.t
let pp_ploc_t pps loc =
  let intloc = Ploc.Internal.of_t loc in
  Util.PlocInternal.pp pps intloc

type located_pattern = (string * string) * ploc_t
[@@deriving show { with_path = false }]

type triple = raw * located_pattern
[@@deriving show { with_path = false }]

let raw_is_EOF t = Exec.(t.T.type_ = Some C._EOF)
let triple_is_EOI (_,(p,_)) = fst p = "EOI"

let triple2raw (raw, _) = raw
let triple2pattern (_,(pat,_)) = pat
let triple2ploc (_,(_,ploc)) = ploc
