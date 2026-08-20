(**pp -syntax camlp5o -package pa_ppx_regexp *)

open Pa_ppx_utils

open Antlr
open Exec

let is_raw_string txt =
  let txtlen = String.length txt in
  (txt.[0] = '|' && txt.[txtlen-1] = '|') ||
    let parts = [%split {|\||}] txt in
    (List.length parts >= 2 &&
       List.hd parts = Std.last parts)

let canEndRawString self cu =
  let start = self.R._tokenStartCharIndex in
  let stop = (IS.index self.R._input) - 1 in
  let txt = IS.getText self.R._input (start+1) (stop-1) in
  is_raw_string txt
