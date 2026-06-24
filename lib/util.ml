(**pp -syntax camlp5o -package pa_ppx.deriving_plugins.std,pa_ppx.deriving_plugins.yojson,pa_ppx.deriving_plugins.located_yojson *)

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
