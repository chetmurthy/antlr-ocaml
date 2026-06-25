
module PackageGraph = struct
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

module StringEdge = struct
  type t = string
  let compare = Stdlib.compare
  let default = ""
end

module V = StringVertex
module G = Imperative.Digraph.ConcreteBidirectionalLabeled(V)(StringEdge)

module DotIn = struct
  type t = G.t
  module V = G.V
  module E = G.E
  let iter_vertex = G.iter_vertex
  let iter_edges_e = G.iter_edges_e
  let graph_attributes _ = []
  let default_vertex_attributes _ = []
  let vertex_name v = v
  let vertex_attributes _ = []
  let get_subgraph _ = None

  let default_edge_attributes _ = []
  let edge_attributes _ = []
end
module GDot = Graph.Graphviz.Dot(DotIn)
module DomG = Dominator.Make_graph(struct
    include G
    let empty () = create ()
    let add_edge g v1 v2 =
      G.add_edge g v1 v2 ;
      g
  end)

let to_dot ?dominator_from oc edges =
  let g = G.create () in
    List.iter (G.add_edge_e g) edges ;
  let g = match dominator_from with
    Some v -> DomG.(compute_dom_graph g (compute_all g v).dom_tree)
  | None -> g in

  GDot.output_graph oc g ; flush oc

end
