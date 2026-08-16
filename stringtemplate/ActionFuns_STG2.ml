module L_constants = STG2Lexer_constants

open Antlr
open Exec

let lDelim = Char.code '<'
let rDelim = Char.code '>'

let subtemplateDepth = ref 0

let watch_subtemplateDepth (n : int) = ()

let enterSubTemplate self cu =
  incr subtemplateDepth ;
  watch_subtemplateDepth !subtemplateDepth

let exitSubTemplate self cu =
  watch_subtemplateDepth !subtemplateDepth;
  if !subtemplateDepth > 0 then begin
      decr subtemplateDepth ;
      ignore(R.popMode self : int)
    end

let subTemplateHasIDs self cu =
  let rec idrec i =
  let c = IS.la self.R._input i in
  if c = C._EOF then true
  else let uc = Uchar.of_int c in
       if Uucp.Id.is_id_start uc || Uucp.Id.is_id_continue uc || Uucp.White.is_white_space uc
          || uc = Uchar.of_char ',' then
         idrec (i+1)
       else if uc = Uchar.of_char '|' then true
       else false
  in idrec 1

let adjText self cu =
  let c1 = IS.la self.R._input (-1) in
  if c1 = Char.code '\\' then begin
      let c2 = IS.la self._input 1 in
      if c2 = Char.code '\\' then
        IS.consume self._input
      else if c2 = lDelim || c2 = Char.code '}' then
                IS.consume self._input
      else ()
    end ;
  true

let isLDelimNotComment self cu =
  IS.la self.R._input (-1) = lDelim && IS.la self.R._input 1 <> Char.code '!'

let isRDelim self cu =
  rDelim = IS.la self.R._input (-1)

let isLTmplComment self cu =
   IS.la self.R._input (-1) = lDelim && IS.la self._input (1) = Char.code '!'

let isRTmplComment self cu =
   IS.la self.R._input (-2) = Char.code '!' && IS.la self._input (-1) = rDelim

let reset () =
  subtemplateDepth := 0
