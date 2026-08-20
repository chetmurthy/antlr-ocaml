(**pp -syntax camlp5o -package pa_ppx_regexp,pa_ppx.deriving_plugins.std *)

open Pa_ppx_utils

type raw = Exec.T.token_t
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

type 'a located = (Ploc.t * 'a)
let located_sexp_of_located subf (_,x) = subf x
let located_of_located_sexp subf se =
  let open Pa_ppx_located_sexp in
  (Sexp.loc_of_sexp se, subf se)
let pp_located subf pps (_,x) = subf pps x


module type ACTION_FUNS = sig
  val reset : unit -> unit
end

module type TOKEN_CUSTOMIZATION = sig
  val renaming : ((string option * string option) * (string option * string option)) list
end

module type AFTER_INIT = sig
  module Lex : Exec.FULL_LEXER
  val after_init : Lex.t -> unit
end

module type CAMLP5LEXER = sig
  module Lex : Exec.FULL_LEXER
  val rename :
    string option * string option -> string option * string option
  val names : (string option * string option) array
  val pattern_of_token : Exec.T.token_t -> Plexing.pattern
  val located_pattern_of_token :
    startloc:Ploc.t -> Exec.T.token_t -> Plexing.pattern * Ploc.t
  val start_location : Ploc.t ref
  val raw_lexer :
    ?all_channels:bool -> char Stream.t -> unit -> Exec.T.t
  val raw_modes_lexer :
    char Stream.t -> unit -> (string list * Exec.T.t * string list)
  val located_pattern_lexer :
    ?all_channels:bool ->
    char Stream.t -> unit -> Plexing.pattern * Ploc.t
  val pattern_modes_lexer :
    char Stream.t -> unit -> (string list * Plexing.pattern * string list)
  val triple_lexer :
    ?all_channels:bool ->
    char Stream.t -> unit -> Exec.T.t * (Plexing.pattern * Ploc.t)
  val stream_of_lexer : (unit -> 'a) -> 'a Stream.t
  val lexer :
    char Stream.t -> Plexing.pattern Stream.t * Plexing.Locations.t
  val raw_of_string :
    ?all_channels:bool -> string -> Exec.T.t Stream.t
  val raw_modes_of_string :
    string -> (string list * Exec.T.t * string list) Stream.t
  val located_patterns_of_string :
    ?startloc:Ploc.t ->
    ?all_channels:bool -> string -> (Plexing.pattern * Ploc.t) Stream.t
  val pattern_modes_of_string :
    string -> (string list * Plexing.pattern * string list) Stream.t
  val located_patterns_of_here_string :
    ?all_channels:bool ->
    Lexing.position * string -> (Plexing.pattern * Ploc.t) Stream.t
  val triple_of_string :
    ?startloc:Ploc.t ->
    ?all_channels:bool ->
    string -> (Exec.T.t * (Plexing.pattern * Ploc.t)) Stream.t
  val triple_of_here_string :
    ?all_channels:bool ->
    Lexing.position * string ->
    (Exec.T.t * (Plexing.pattern * Ploc.t)) Stream.t
  val watch_mode : (string * int * int list) -> unit
  val watch_mode0 : (string * string * string list) -> unit
end


let ploc_of_token ~startloc t =
  let open Exec in
  let open T in
  let open Std in
  let file = Ploc.file_name startloc in
  let sl_line = Ploc.line_nb startloc in
  let sl_bol_pos = Ploc.bol_pos startloc in
  let sl_bp = Ploc.first_pos startloc in

  let tok_line = outSome t.line in
  let tok_column = outSome t.column in
  let tok_bp = outSome t.start in
  let tok_ep = 1 + (outSome t.stop) in

  let line = sl_line + tok_line - 1 in
  let bp = sl_bp + tok_bp in
  let ep = sl_bp + tok_ep in
  let bol_pos = if tok_line = 1 then sl_bol_pos else bp - tok_column in

  Ploc.make_loc file line bol_pos (bp,ep) ""

let string_of_char_stream cs =
  let b = Buffer.create 23 in
  Stream.iter (Buffer.add_char b) cs ;
  Buffer.contents b

let watch_pattern (x : (string * string)) = ()

module Make
         (AF : ACTION_FUNS)
         (TC : TOKEN_CUSTOMIZATION)
         (Lex : Exec.FULL_LEXER)
         (AfterInit : AFTER_INIT with module Lex = Lex) : (CAMLP5LEXER with module Lex = Lex)
  = struct
module Lex = Lex

let mode2string n = 
  List.nth (fst Lex.full_atn).Interp.Raw.mode_names n

let watch_mode0 ((s:string), (mode : string), (modeStack : string list)) = ()

let watch_mode ((s:string), (mode : int), (modeStack : int list)) =
  watch_mode0 (s, mode2string mode,  List.map mode2string modeStack)

let rename x =
  match List.assoc_opt x TC.renaming with
    None -> x
  | Some y -> y

let names =
  let symbolic_names = (fst Lex.full_atn).Interp.Raw.token_symbolic_names in
  let literal_names = (fst Lex.full_atn).Interp.Raw.token_literal_names in
  assert (Array.length symbolic_names = Array.length literal_names) ;
  let names = Array.of_list (Std.combine (Array.to_list symbolic_names) (Array.to_list literal_names)) in
  Array.map rename names

let pattern_of_token self : Plexing.pattern =
  match self.Exec.T.type_ with
    None -> assert false
  | Some (-1) -> ("EOI","")
  | Some n when n < 0 -> assert false
  | Some n when n >= Array.length names -> assert false
  | Some n ->
     match names.(n) with
       (None, _) -> assert false
     | (Some _, Some txt) -> ("", txt)
     | (Some ty, None) ->
        let txt =
          match self._text with
            Some txt -> txt
          | None ->
             let open Exec in
             assert (Std.isSome self.start) ;
             assert (Std.isSome self.stop) ;
             let start = Std.outSome self.start in
             let stop = Std.outSome self.stop in
             let n = IS.size self._input in
             if start < n && stop < n then
               (IS.getText self._input start stop)
             else assert false in
        (ty, txt)

let located_pattern_of_token ~startloc self : (Plexing.pattern * Ploc.t) =
  let loc = ploc_of_token ~startloc self in
  let tok = pattern_of_token self in
  watch_pattern tok ;
  (tok,loc)

let start_location = ref Ploc.dummy

let raw_lexer ?(all_channels=false) cs =
  let txt = string_of_char_stream cs in
  let input : Exec.IS.t =
    Tracelog.with_disabled (fun () ->
        Exec.IS.init txt ()
      ) ()
  in
  AF.reset() ;
  let lex = Lex.full_init ~input ~output:stdout in
  AfterInit.after_init lex ;
  let rec next_token () =
    watch_mode ("before",lex.recog._mode, lex.recog._modeStack) ;
    let t = Lex.nextToken lex in
    watch_mode ("after",lex.recog._mode, lex.recog._modeStack) ;
    assert(Std.isSome t.channel) ;
    if not all_channels && (Std.outSome t.channel) <> 0 then next_token()
    else
      t in
  next_token

let raw_modes_lexer cs =
  let txt = string_of_char_stream cs in
  let input : Exec.IS.t =
    Tracelog.with_disabled (fun () ->
        Exec.IS.init txt ()
      ) ()
  in
  AF.reset() ;
  let lex = Lex.full_init ~input ~output:stdout in
  AfterInit.after_init lex ;
  let rec next_token () =
    let modes1 = (lex.recog._mode :: lex.recog._modeStack) in
    let t = Lex.nextToken lex in
    let modes2 = (lex.recog._mode :: lex.recog._modeStack) in
    assert(Std.isSome t.channel) ;
    (List.map mode2string modes1, t, List.map mode2string modes2) in
  next_token

let located_pattern_lexer ?(all_channels=false) cs =
  let startloc = !start_location in
  let next_token = raw_lexer ~all_channels cs in
  let next_token () =
    let t = next_token () in
    located_pattern_of_token ~startloc t in
  next_token

let pattern_modes_lexer cs =
  let next_token = raw_modes_lexer cs in
  let next_token () =
    let (m1,t,m2) = next_token () in
    (m1, pattern_of_token t, m2) in
  next_token

let triple_lexer ?(all_channels=false) cs =
  let startloc = !start_location in
  let next_token = raw_lexer ~all_channels cs in
  let next_token () =
    let t = next_token () in
    let locpat = located_pattern_of_token ~startloc t in
    (t, locpat) in
  next_token

let stream_of_lexer f =
  Stream.from (fun _ -> Some (f()))

let lexer cs =
  Plexing.make_stream_and_location (located_pattern_lexer cs)

let raw_of_string ?all_channels s =
  s
  |> Stream.of_string
  |> raw_lexer ?all_channels
  |> stream_of_lexer
  |> Util.truncate_stream raw_is_EOF

let raw_modes_is_EOF (_,t,_) =
  raw_is_EOF t

let raw_modes_of_string s =
  s
  |> Stream.of_string
  |> raw_modes_lexer
  |> stream_of_lexer
  |> Util.truncate_stream raw_modes_is_EOF


let with_location start_location ?startloc f arg =
  let startloc = match startloc with None -> Ploc.dummy | Some x -> x in
  let old_start_location = !start_location in
  start_location := startloc ;
  Util.finally f
    (fun _ _ -> start_location := old_start_location)
    arg

let located_patterns_of_string ?startloc ?all_channels s =
  with_location start_location ?startloc (fun s ->
      s
      |> Stream.of_string
      |> located_pattern_lexer ?all_channels
      |> stream_of_lexer
      |> Util.(truncate_stream located_pattern_is_EOI)
    ) s

let pattern_modes_is_EOI (_,p,_) = Util.pattern_is_EOI p

let pattern_modes_of_string s =
  s
  |> Stream.of_string
  |> pattern_modes_lexer
  |> stream_of_lexer
  |> Util.(truncate_stream pattern_modes_is_EOI)

let located_patterns_of_here_string ?all_channels (pos,s)  =
  let startloc = Util.ploc_of_position pos in
  located_patterns_of_string  ~startloc ?all_channels s

let triple_of_string ?startloc ?all_channels s =
  with_location start_location ?startloc (fun s ->
      s
      |> Stream.of_string
      |> triple_lexer ?all_channels
      |> stream_of_lexer
      |> Util.truncate_stream triple_is_EOI
    ) s

let triple_of_here_string ?all_channels (pos,s)  =
  let startloc = Util.ploc_of_position pos in
  triple_of_string  ~startloc ?all_channels s

end
