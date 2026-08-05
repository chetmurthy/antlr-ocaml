
open Pa_ppx_utils
open Antlr

module type ACTION_FUNS = sig
  val reset : unit -> unit
end

module type TOKEN_CUSTOMIZATION = sig
  val renaming : ((string option * string option) * (string option * string option)) list
end



module Make(AF : ACTION_FUNS)(TC : TOKEN_CUSTOMIZATION)(Lex : Exec.FULL_LEXER) = struct

let ploc_of_token ~file t =
  let open Antlr in
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

let rename x =
  match List.assoc_opt x TC.renaming with
    None -> x
  | Some y -> y

let names =
  let open Antlr in
  let symbolic_names = (fst Lex.full_atn).Interp.Raw.token_symbolic_names in
  let literal_names = (fst Lex.full_atn).Interp.Raw.token_literal_names in
  assert (Array.length symbolic_names = Array.length literal_names) ;
  let names = Array.of_list (Std.combine (Array.to_list symbolic_names) (Array.to_list literal_names)) in
  Array.map rename names

let pattern_of_token self : Plexing.pattern =
  let open Antlr in
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

let located_pattern_of_token ~file self : (Plexing.pattern * Ploc.t) =
  let loc = ploc_of_token ~file self in
  let tok = pattern_of_token self in
  (tok,loc)

let input_file = Plexing.input_file
let lexer cs =
  let open Antlr in
  let txt = string_of_char_stream cs in
  let input : Exec.IS.t =
    Tracelog.with_disabled (fun () ->
        Exec.IS.init txt ()
      ) ()
  in
  AF.reset() ;
  let lex = Lex.full_init ~input ~output:stdout in
  let rec next_token () =
    let t = Lex.nextToken lex in
    assert(Std.isSome t.channel) ;
    if (Std.outSome t.channel) <> 0 then next_token()
    else
      located_pattern_of_token ~file:!input_file t in
  Plexing.make_stream_and_location next_token

end

module ST = Make(ActionFuns_st)(struct
let renaming = [
    ((Some "LDELIM", None), (Some "LDELIM",Some "<"))
  ; ((Some "RDELIM", None), (Some "RDELIM",Some ">"))
  ; ((Some "LBRACE", None), (Some "LBRACE",Some "{"))
  ; ((Some "RBRACE", None), (Some "RBRACE",Some "}"))
  ; ((Some "COLON", None), (Some "COLON",Some ":"))
  ; ((Some "COMMA", None), (Some "COMMA",Some ","))
  ; ((Some "SEMI", None), (Some "SEMI",Some ";"))
  ; ((Some "LPAREN", None), (Some "LPAREN",Some "("))
  ; ((Some "RPAREN", None), (Some "RPAREN",Some ")"))
  ; ((Some "LBRACK", None), (Some "LBRACK",Some "["))
  ; ((Some "RBRACK", None), (Some "RBRACK",Some "]"))
  ; ((Some "DOT", None), (Some "DOT",Some "."))
  ; ((Some "BANG", None), (Some "BANG",Some "!"))
  ; ((Some "AND", None), (Some "AND",Some "&&"))
  ; ((Some "OR", None), (Some "OR",Some "||"))
  ; ((Some "PIPE", None), (Some "PIPE",Some "|"))
  ; ((Some "EQUALS", None), (Some "EQUALS", Some "="))
  ]
              end)(L_st.Full)
