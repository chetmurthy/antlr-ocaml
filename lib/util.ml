(**pp -syntax camlp5o -package pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.yojson,pa_ppx.deriving_plugins.located_yojson *)

open Pa_ppx_utils

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

let ee1 ~only_outermost_enter eemap extractor nth acc j = match (extractor j, acc) with
      (Some tag,_) when List.mem_assoc tag eemap ->
       let exit_tag = List.assoc tag eemap in
      (nth, [], ((exit_tag,[j]) :: acc))

    | (Some tag, ((exittag, rev_j)::(exittag', rev_j')::acc)) when tag = exittag ->
       let rev_j' = List.append rev_j rev_j' in
       (nth, [], (exittag', j::rev_j')::acc)

    | (Some tag, ((exittag, rev_j)::[])) when tag = exittag -> begin
        match nth with
          None ->
          if only_outermost_enter then
            (None, [Std.last rev_j], [])
          else
            (None, List.rev (j::rev_j), [])
        | Some 0 ->
          if only_outermost_enter then
            (Some (-1), [Std.last rev_j], [])
          else
            (Some (-1), List.rev (j::rev_j), [])
        | Some (-1) ->
           (Some (-1), [], [])
        | Some n ->
           (Some (n-1), [], [])
        | _ -> assert false
      end
    | (_, ((tag, rev_j) :: acc)) ->
       (nth, [], ((tag, j::rev_j) :: acc))

    | (_, []) -> (nth, [], acc)

let entry_exit ?nth ~only_outermost_enter names extractor strm =
  let entry_names = List.map (fun s -> "ENTER "^s) names in
  let exit_names = List.map (fun s -> "EXIT "^s) names in
  let eemap = Std.combine entry_names exit_names in
  let drain_acc nth acc =
    if only_outermost_enter then
      List.fold_right (fun (_, rev_j) acc -> (Std.last rev_j)::acc) acc []
    else
      List.fold_right (fun (_, rev_j) acc -> List.rev_append rev_j acc) acc [] in

  let rec eerec nth acc = parser
    [< 'j ; strm >] ->
      let (nth, emitl, acc) = ee1 ~only_outermost_enter eemap extractor nth acc j in
      [< Stream.of_list emitl ; eerec nth acc strm >]
  | [< >] -> Stream.of_list (drain_acc nth acc) in

  eerec nth [] strm

let entry_exit_yojson ?nth ~only_outermost_enter names strm : 'a Stream.t =
  entry_exit ?nth ~only_outermost_enter names extract_tag strm

