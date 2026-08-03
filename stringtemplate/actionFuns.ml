open Antlr
open Exec

let lDelim = Char.code '<'
let rDelim = Char.code '>'

let subtemplateDepth = ref 0

let startsSubTemplate self cu =
  incr subtemplateDepth ;
  false

let endsSubTemplate self cu =
  if !subtemplateDepth > 0 then begin
      decr subtemplateDepth ;
      R.mode self 1
    end ;
  true

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

