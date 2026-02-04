class GraphSearchService
  def initialize(model: "text-embedding-004")
    @model = model
  end

  # Search for nodes semantically
  def search_nodes(query, limit: 10)
    embedding = RubyLLM.embed(query, model: @model).vectors
    return [] unless embedding

    GraphNode.nearest_neighbors(:embedding, embedding, distance: "cosine")
             .limit(limit)
  end

  # Get a subgraph around a specific node (for visualization)
  def explore_node(node_id, depth: 1)
    # Simple 1-hop for now. 
    # To do depth > 1, we'd need a recursive CTE or loop.
    node = GraphNode.find(node_id)
    
    # Fetch outgoing edges and target nodes
    outgoing = GraphEdge.includes(:target_node).where(source_node: node)
    
    # Fetch incoming edges and source nodes
    incoming = GraphEdge.includes(:source_node).where(target_node: node)
    
    nodes = [node] + outgoing.map(&:target_node) + incoming.map(&:source_node)
    edges = outgoing + incoming
    
    {
      nodes: nodes.uniq,
      edges: edges.uniq
    }
  end
end
