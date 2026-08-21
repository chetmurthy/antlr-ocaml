#include "version.inc"

let top = try Sys.getenv "TOP" with Not_found -> "" ;;
let destdir = ref (top ^ "/local-install") ;;

Arg.(parse [
         "-destdir", (Arg.String (fun s -> destdir := s)),
         ("<path>    Set the destination directory (default: " ^
	    !destdir ^ ")")
       ]
       (fun _ -> failwith "mk_meta: no anonymous args supported")
     "mk_meta -destdir <dir>")
;;

Fmt.(pf stdout {|# Specifications for the "stringtemplate" package:
version = "%s"
description = "String Templates"

  archive(byte) = "ST4.cma"
  archive(native) = "ST4.cmxa"

  requires = "camlp5,pa_ppx_regexp.runtime,fmt,bos,pa_ppx.utils,yojson,pa_ppx.located_yojson,pa_ppx.located_sexp"
|} version)
