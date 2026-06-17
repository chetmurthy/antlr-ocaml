(**pp -syntax camlp5o *)

module Raw = struct
type t = {
    token_literal_names : string option list
  ; token_symbolic_names : string  option list
  ; rule_names : string list
  ; channel_names : string list option
  ; mode_names : string list option
  ; atn : int list
  }
end
