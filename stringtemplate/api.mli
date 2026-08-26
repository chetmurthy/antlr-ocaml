(**pp -syntax camlp5o *)

module STPa = Pa.STG2_STPa
module STGPa = Pa.STG2_STGPa

module FileCache :
  sig
    type t
    val mk :
      (string * (Lexing.position * string)) list ->
      (string * (Ploc.t * string)) list -> t
    val mt : t
  end
module FC = FileCache

module GroupLoadContext :
  sig
    type t
    val mk : FC.t -> t
 end
module GLC = GroupLoadContext

module Group :
  sig
    type t
    val mk : unit -> t
    val load : GLC.t -> Fpath.t -> t
    val of_located_string :
      GLC.t -> stg:bool -> Ploc.t * string -> t
    val of_here_string :
      GLC.t -> stg:bool -> Lexing.position * string -> t
  end

module GroupDir :
  sig
    type t
    val mk : ?group:Group.t -> unit -> t
    val load : GLC.t -> Fpath.t -> t
  end
module Template :
  sig
    type t
    val of_string : string -> t
    val eval :
      ?group:Group.t ->
      ?groupdir:GroupDir.t ->
      Eval.Environ.t -> t -> string
    module Simple :
      sig
        val eval :
          ?group:Group.t ->
          ?groupdir:GroupDir.t ->
          (string * string list) list -> t -> string

        val transform_file :
          ?group:Group.t ->
          ?groupdir:GroupDir.t ->
          (string * string list) list -> Fpath.t -> string

      end
  end
