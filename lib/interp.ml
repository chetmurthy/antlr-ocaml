(**pp -syntax camlp5o *)

module Raw = struct
type t = {
    token_literal_names : string option array
  ; token_symbolic_names : string option array
  ; rule_names : string array
  ; channel_names : string list option
  ; mode_names : string list option
  ; atn : int list
  }
end
