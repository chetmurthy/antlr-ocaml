
open Pa_ppx_utils
open Antlr

let ploc_of_token ~file t =
  let open Exec in
  let open T in
  let open Std in
  let line = outSome t.line in
  let column = outSome t.column in
  let bp = outSome t.start in
  let ep = 1 + (outSome t.stop) in
  let bol_pos = bp-column in
  Ploc.make_loc file line bol_pos (bp,ep) ""

let string_of_char_stream cs =
  let b = Buffer.create 23 in
  Stream.iter (Buffer.add_char b) cs ;
  Buffer.contents b

let pattern_of_token self : Plexing.pattern =
  let symbolic_names = (fst ANTLRv4Lexer.atns.lexer).Interp.Raw.token_symbolic_names in
  let literal_names = (fst ANTLRv4Lexer.atns.lexer).Interp.Raw.token_literal_names in
  assert (Array.length symbolic_names = Array.length literal_names) ;
  match self.Exec.T.type_ with
    None -> assert false
  | Some (-1) -> ("EOI","")
  | Some n when n < 0 -> assert false
  | Some n when n >= Array.length symbolic_names -> assert false
  | Some n ->
     match (symbolic_names.(n), literal_names.(n)) with
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

let located_pattern_of_token ~file self : (Plexing.pattern * Ploc.t) =
  let loc = ploc_of_token ~file self in
  let tok = pattern_of_token self in
  (tok,loc)

let input_file = ref ""
let lexer cs =
  let txt = string_of_char_stream cs in
  let input : Exec.IS.t =
    Tracelog.with_disabled (fun () ->
        Exec.IS.init txt ()
      ) ()
  in
  let lex = ANTLRv4Lexer.init ~input ~output:stdout in
  let rec next_token () =
    let t = Exec.Lexer.nextToken lex in
    assert(Std.isSome t.channel) ;
    if (Std.outSome t.channel) <> 0 then next_token()
    else
      located_pattern_of_token ~file:!input_file t in
  Plexing.make_stream_and_location next_token

let _ : Plexing.(pattern lexer_func) = lexer
