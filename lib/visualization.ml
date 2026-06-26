
open Graph

module StringVertex = struct
  type t = string
  let compare = Stdlib.compare
  let hash = Hashtbl.hash
  let equal a b = (a = b)
  type label = t
  let create x = x
  let label x = x
end

module StateIDVertex = struct
  type t = Atn.state_id
  let compare = Stdlib.compare
  let hash = Hashtbl.hash
  let equal a b = (a = b)
  type label = t
  let create x = x
  let label x = x
end

module StringEdge = struct
  type t = string
  let compare = Stdlib.compare
  let default = ""
end

module V = StateIDVertex
module G = Imperative.Digraph.ConcreteBidirectionalLabeled(V)(StringEdge)

let to_dot ~with_rule_index oc atn edges =
  let open Atn in

  let vertex_name snum =
    let open State in
    let st = State.get_state atn.states snum in
    Fmt.(str "%a" dump_state_id snum) in

  let vertex_attributes snum =
    let open State in
    let st = State.get_state atn.states snum in
    let label =
      if with_rule_index then
        Fmt.(str "%a/%a/%d"
               dump_state_id snum
               Node.pp_atn_state_type_t (Node.serialization_name st.State.node)
               st.State.ruleIndex)
      else
        Fmt.(str "%a/%a"
               dump_state_id snum
               Node.pp_atn_state_type_t (Node.serialization_name st.State.node))

 in
    [`Label label] in

let module DotIn = struct
  type t = G.t
  module V = G.V
  module E = G.E
  let iter_vertex = G.iter_vertex
  let iter_edges_e = G.iter_edges_e
  let graph_attributes _ = []
  let default_vertex_attributes _ = []
  let vertex_name v = vertex_name v
  let vertex_attributes v = vertex_attributes v
  let get_subgraph _ = None

  let default_edge_attributes _ = []
  let edge_attributes (_,elab,_) = [`Label elab]
end in
let module GDot = Graph.Graphviz.Dot(DotIn) in
  let g = G.create () in
    List.iter (G.add_edge_e g) edges ;
  GDot.output_graph oc g ; flush oc
