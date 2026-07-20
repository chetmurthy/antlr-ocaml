(**pp -syntax camlp5o -package pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.yojson,pa_ppx.deriving_plugins.located_yojson,pa_ppx_regexp *)

open Pa_ppx_utils
open Pa_ppx_base
open Ppxutil

let plisti elem i = 
  let rec plist_rec accum i = parser
     [< e = elem i; strm >] -> plist_rec (e::accum) (i+1) strm
   | [< >]                         -> (List.rev accum)
  in plist_rec [] i

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

let finally f arg finf =
  let open Std in
  let rv = try Inl(f arg) with e -> Inr (e, Printexc.get_raw_backtrace ())
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
  let div_grain = n / grain in
  let mod_grain = n mod grain in
  if 0 <> mod_grain then
    n+(grain-mod_grain)
  else n

let escape_string s =
  let s = [%subst "\n" / {|\n|} / pcre2 g s] s in
  let s = [%subst "\r" / {|\r|} / pcre2 g s] s in
  let s = [%subst "\t" / {|\t|} / pcre2 g s] s in
  s
