(**pp -syntax camlp5o -package pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.yojson,pa_ppx.deriving_plugins.located_yojson,pa_ppx_regexp *)

open Pa_ppx_utils
open Pa_ppx_base
open Ppxutil

let truncate_stream pred strm =
  let rec trec = parser
    [< 't ; strm >] ->
      if pred t then [< 't >] else [< 't ; trec strm >]
  | [< >] -> [< >]
  in trec strm

let plisti elem i = 
  let rec plist_rec accum i = parser
     [< e = elem i; strm >] -> plist_rec (e::accum) (i+1) strm
   | [< >]                         -> (List.rev accum)
  in plist_rec [] i

let plist_with_sep elemf sepf =
  let rec plistrec acc = parser
    [< _=sepf ; e=elemf ; l=plistrec (e::acc) >] -> l
  | [< >] -> List.rev acc in
  parser
    [< h=elemf ; l=plistrec [h] >] -> l

let plistn elem i = 
  let rec plist_rec accum i strm =
    if i = 0 then List.rev accum
    else plist_rec2 accum (i-1) strm
    and plist_rec2 accum i = parser
     [< e = elem; strm >] -> plist_rec (e::accum) i strm
  in plist_rec [] i

let insert_after n l v =
  let rec insrec = function
      (0,l) -> v::l
    | (n,h::t) -> h::(insrec (n-1,t))
    | (_,[]) -> [v]
  in insrec (n,l)

let pa_pair pa1 pa2 =
  parser [< p1 = pa1 ; p2 = pa2 >] -> (p1, p2)

type 'b _strmap = (string * 'b) list
[@@deriving yojson, located_yojson, show]

type 'b strmap = 'b _strmap
let strmap_to_yojson vconv l =
  let j : Yojson.Safe.t = _strmap_to_yojson vconv l in
  match j with
    `List l ->
     `Assoc (List.map (function `List[`String k; v] -> (k,v) | _ -> assert false) l)
  | _ -> assert false

let strmap_of_yojson vconv j =
  match j with
    `Assoc l ->
     _strmap_of_yojson vconv (`List (List.map (fun (k,v) -> `List [`String k; v]) l))
  | _ -> Result.Error "Stg.Env.strmap_of_yojson"

let pp_strmap = pp__strmap

open Pa_ppx_located_yojson

let strmap_to_located_yojson vconv l =
  let j : Json.t = _strmap_to_located_yojson vconv l in
  match j with
    (loc, `List l) ->
     (loc, `Assoc (List.map (function (_, `List[(_, `String k); v]) -> (k,v) | _ -> assert false) l))
  | _ -> assert false

let strmap_of_located_yojson vconv j =
  match j with
    (loc, `Assoc l) ->
     _strmap_of_located_yojson vconv ((loc, `List (List.map (fun (k,v) -> (loc, `List [(loc, `String k); v])) l)))
  | (loc, _) -> Result.Error (loc, "Stg.Env.strmap_of_yojson")

let stream_iter f strm =
  let rec itrec = parser
    [< 't ; s >] -> f t ; itrec s
  | [< >] -> ()
  in itrec strm

let stream_iter_i f strm =
  let rec itrec = parser
    bp [< 't ; s >] -> f bp t ; itrec s
  | [< >] -> ()
  in itrec strm

let extract_tag = function
    (_,`List ((_, `String tag):: _)) -> Some tag
  | _ -> None

(** entry_exit pulls out runs of events bracketed by
    "ENTER x" and "EXIT x" (inclusive), for specified
    "x".  Events outside those brackets are dropped.

    [~only_outermost_enter] : when it detects a full entry/exit tree, it emits only the
    first ENTER event

    [names] : the list of names [n] that are used for "ENTER [n]" and "EXIT [n]"
    event names

    [~nth : int option] :

    * when set to [None], emit all matching events from above;

    * when set to [Some (-1)], emit no events.

    * when set to [Some 0], emit the next event-tree as above

    * when set to [Some n], skip the next event-tree, and set to [Some (n-1)]

    The effect is to emit ONLY the nth event-tree.

 *)

let range_accepts ropt n =
  match ropt with
    None -> true
  | Some r -> Range.contains r n

let ee1 ~only_outermost_enter eemap extractor range n acc j = match (extractor j, acc) with
      (Some tag,_) when List.mem_assoc tag eemap ->
       let exit_tag = List.assoc tag eemap in
      (n, [], ((exit_tag,[j]) :: acc))

    | (Some tag, ((exittag, rev_j)::(exittag', rev_j')::acc)) when tag = exittag ->
       let rev_j' = List.append rev_j rev_j' in
       (n, [], (exittag', j::rev_j')::acc)

    | (Some tag, ((exittag, rev_j)::[])) when tag = exittag ->
        if range_accepts range n then
          if only_outermost_enter then
            (n+1, [Std.last rev_j], [])
          else
            (n+1, List.rev (j::rev_j), [])
        else
           (n+1, [], [])

    | (_, ((tag, rev_j) :: acc)) ->
       (n, [], ((tag, j::rev_j) :: acc))

    | (_, []) -> (n, [], acc)

let entry_exit ?start_nth ?stop_nth ~only_outermost_enter names extractor strm =
  let range = match (start_nth, stop_nth) with
      (None, None) -> None
    | (Some start, None) -> Some (Range.mk ~start (start+1))
    | (None, Some stop) -> Some (Range.mk stop)
    | (Some start, Some stop) -> Some (Range.mk ~start stop) in
  let entry_names = List.map (fun s -> "ENTER "^s) names in
  let exit_names = List.map (fun s -> "EXIT "^s) names in
  let eemap = Std.combine entry_names exit_names in
  let drain_acc acc =
    if only_outermost_enter then
      List.fold_right (fun (_, rev_j) acc -> (Std.last rev_j)::acc) acc []
    else
      List.fold_right (fun (_, rev_j) acc -> List.rev_append rev_j acc) acc [] in

  let rec eerec n acc = parser
    [< 'j ; strm >] ->
      let (n, emitl, acc) = ee1 ~only_outermost_enter eemap extractor range n acc j in
      [< Stream.of_list emitl ; eerec n acc strm >]
  | [< >] -> Stream.of_list (drain_acc acc) in

  eerec 0 [] strm

let entry_exit_yojson ?start_nth ?stop_nth ~only_outermost_enter names strm : 'a Stream.t =
  entry_exit ?start_nth ?stop_nth ~only_outermost_enter names extract_tag strm

let entry_exit_decorate_depth strm : (int * Pa_ppx_located_yojson.Json.t) Stream.t =
  let rec eerec depth stk = parser
    [< '((_, `List ((_, `String name)::_)) as j) ; strm >] ->
      if [%match {|^ENTER \S+$|} / pcre2 pred] name then
        let proc = [%match {|^ENTER (\S+)$|} / pcre2 strings !1] name in
        [< '(depth, j) ; eerec (depth+1) (proc::stk) strm >]
      else if [%match {|^EXIT \S+$|} / pcre2 pred] name then
        let proc = [%match {|^EXIT (\S+)$|} / pcre2 strings !1] name in
        match stk with
          (proc'::stk) when proc = proc' ->
          [< '(depth-1, j) ; eerec (depth-1) stk strm >]
        | _ -> [< '(depth, j); eerec depth stk strm >]
      else
        [< '(depth, j) ; eerec depth stk strm >]
    | [< 'j ; strm >] -> [< '(depth, j) ; eerec depth stk strm >]
    | [< >] -> [< >]
in eerec 0 [] strm

let uchars_of_string loc s =
  let open Uutf in
  let dec = decoder ~encoding:`UTF_8 (`String s) in
  let rec derec () =
    match decode dec with
      `Uchar uc -> uc::(derec ())
    | `End  -> []
    | _ -> Fmt.(raise_failwithf loc "uchars_of_string: malformed UTF-8 string %a"
                  Dump.string s)
  in derec ()

let string_of_uchars l =
  let b = Buffer.create (List.length l) in
  List.iter (Uutf.Buffer.add_utf_8 b) l ;
  Buffer.contents b

let array_of_string loc s =
  let l = uchars_of_string loc s in
  Array.of_list (List.map Uchar.to_int l)

let finally f finf arg =
  let open Std in
  let rv = try Inl(f arg)
           with e ->
             let eb = (e, Printexc.get_raw_backtrace ()) in
(*
             Fmt.(pf stderr "Util.finally: exception@.%a@." exn_backtrace eb) ;
 *)
             Inr eb
  in (try finf arg (match rv with Inl v -> Some v | Inr _ -> None) with e -> ());
	match rv with
		Inl v -> v
	  | Inr (e, bt) -> Printexc.raise_with_backtrace e bt

let stream_of_function_until f pred =
  let rec strec () =
    let v = f() in
    if pred v then [< 'v >]
    else [< 'v ; strec () >]
  in [< strec () >]

let stream_of_function_until_i f pred =
  let rec strec i =
    let v = f i in
    if pred v then [< 'v >]
    else [< 'v ; strec (i+1) >]
  in [< strec 0 >]

let roundup grain n =
  let mod_grain = n mod grain in
  if 0 <> mod_grain then
    n+(grain-mod_grain)
  else n

let escape_string s =
  let s = [%subst "\n" / {|\n|} / pcre2 g s] s in
  let s = [%subst "\r" / {|\r|} / pcre2 g s] s in
  let s = [%subst "\t" / {|\t|} / pcre2 g s] s in
  s

module Path = struct
  type t = Fpath.t list

  let find ~path fname =
    match List.find_map (fun dir ->
              let full = Fpath.append dir fname in
              if full |> Bos.OS.File.exists |> Rresult.R.get_ok then
                Some full
              else None) path with
      Some full -> full
    | None -> Fmt.(failwithf "Cannot find %a on path (%a)"
                     Fpath.pp fname (list ~sep:(const string " ") Fpath.pp) path)
end


let string_of_uchar uc =
  let b = Buffer.create 4 in
  Uutf.Buffer.add_utf_8 b uc ;
  Buffer.contents b


let digit2int = function
  '0'..'9' as c -> (Char.code c) - (Char.code '0')
| 'a'..'f' as c -> (Char.code c) - (Char.code 'a') + 10
| 'A'..'F' as c -> (Char.code c) - (Char.code 'A') + 10
| _ -> failwith "unescape_string: bad digit"


let hexstring2int digits = int_of_string ("0x"^digits)

let unescape_string s =
  let slen = String.length s in
  let b = Buffer.create slen in
  let rec unrec i =
    if i = String.length s then Buffer.contents b
    else match s.[i] with
           '\\' -> backslash (i+1)
         | c -> Buffer.add_char b c ; unrec (i+1)

  and backslash i =
    if i = slen then failwith "unescape_string: malformed trailing backslash escape"
    else
      match s.[i] with
          ('\'' | '"' | ' ' | '\\') as c -> Buffer.add_char b c ; unrec (i+1)
        | 'b' -> Buffer.add_char b '\b' ; unrec (i+1)
        | 'r' -> Buffer.add_char b '\r' ; unrec (i+1)
        | 'n' -> Buffer.add_char b '\n' ; unrec (i+1)
        | 't' -> Buffer.add_char b '\t' ; unrec (i+1)
        | '0'..'9' -> let i = dec i in unrec i
        | 'x' -> let i = hex (i+1) in unrec i
        | 'o' -> let i = oct (i+1) in unrec i
        | 'u' -> let i = uni (i+1) in unrec i
        | c -> failwith (Printf.sprintf "unescape_string: unrecognized backslash '%c' escape at offset %d" c i)

  and dec i =
    if i+3 > slen then
      failwith (Printf.sprintf "unescape_string: decimal escape without enough digits at offset %d" i)
    else
      match (s.[i], s.[i+1], s.[i+2]) with
          ((('0'..'9') as c1), (('0'..'9') as c2), (('0'..'9') as c3)) ->
          let code = (digit2int c1)*100 +(digit2int c2)*10 + (digit2int c3) in
          Buffer.add_char b (Char.chr code) ; i+3

        | _ -> failwith (Printf.sprintf "unescape_string: malformed decimal escape at offset %d" i)

  and oct i =
    if i+3 > slen then
      failwith (Printf.sprintf "unescape_string: octal escape without enough digits at offset %d" i)
    else
      match (s.[i], s.[i+1], s.[i+2]) with
          ((('0'..'7') as c1), (('0'..'7') as c2), (('0'..'7') as c3)) ->
          let code = (digit2int c1)*64 +(digit2int c2)*8 + (digit2int c3) in
          Buffer.add_char b (Char.chr code) ; i+3

        | _ -> failwith (Printf.sprintf "unescape_string: malformed octal escape at offset %d" i)
  and hex i =
    if i+2 > slen then
      failwith (Printf.sprintf "unescape_string: hex escape without enough digits at offset %d" i)
    else
      match (s.[i], s.[i+1]) with
          ((('0'..'7'|'a'..'f'|'A'..'F') as c1), (('0'..'7'|'a'..'f'|'A'..'F') as c2)) ->
          let code = (digit2int c1)*16 +(digit2int c2) in
          Buffer.add_char b (Char.chr code) ; i+2

        | _ -> failwith (Printf.sprintf "unescape_string: malformed hex escape at offset %d" i)

  and uni i =
    if i >= slen || s.[i] <> '{' then
      failwith (Printf.sprintf "unescape_string: malformed unicode escape at offset %d" i)
    else ();
    match String.index_from_opt s (i+1) '}' with
      None ->
        failwith (Printf.sprintf "unescape_string: malformed unicode escape (no '}') at offset %d" i)
    | Some j ->
       let digits = String.sub s (i+1) (j - (i+1)) in
       let n = hexstring2int digits in
       let uc = Uchar.of_int n in
       Buffer.add_string b (string_of_uchar uc) ; j+1

in unrec 0

let string_contains ~pat =
  let rex = Pcre2.regexp ~flags:[] ("\\Q"^pat^"\\E") in
  Pcre2.pmatch ~rex

let ploc_of_location loc =
  let open Location in
  let open Lexing in
  Ploc.make_loc loc.loc_start.pos_fname loc.loc_start.pos_lnum loc.loc_start.pos_bol (loc.loc_start.pos_cnum, loc.loc_end.pos_cnum) ""

let ploc_of_position pos =
  let open Lexing in
  Ploc.make_loc pos.pos_fname pos.pos_lnum pos.pos_bol (pos.pos_cnum, pos.pos_cnum) ""
