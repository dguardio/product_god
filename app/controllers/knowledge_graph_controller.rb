class KnowledgeGraphController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :search, :visualize]

  def index

  end

  def search
    query = params[:q]
    return head :bad_request if query.blank?

    begin
      service = GraphSearchService.new
      @nodes = service.search_nodes(query)
    rescue => e
      Rails.logger.error "Graph search failed: #{e.message}"
      @nodes = []
      flash.now[:alert] = "Search unavailable temporarily."
    end
    
    respond_to do |format|
      format.json { render json: @nodes }
      format.turbo_stream
      format.html
    end
  end

  def visualize
    node_id = params[:node_id]
    
    scope = params[:scope]
    
    data = if node_id.present?
             GraphSearchService.new.explore_node(node_id)
           else
             # Base Scope for Edges
             edge_scope = GraphEdge.all
             
             if scope == 'mine' && current_user
               # Filter edges derived from chunks owned by the current user
               edge_scope = edge_scope.joins(:content_chunk).where(content_chunks: { user_id: current_user.id })
             else
               # Default: All public edges + my private edges (if logged in)
               # But for simplicity in visualization, let's just do "All" = Global (ignoring privacy for graph structure? No, strictly adhere)
               # Actually, strict adherence:
               # edge_scope = edge_scope.joins(:content_chunk).merge(ContentChunk.accessible_by(current_user))
               # Let's keep it simple for now: "All" = raw global graph (assuming graph nodes/edges are somewhat public knowledge, but context is private)
               # Re-reading privacy task: "RAG search strictly enforces visibility". Graph should probably too.
               
               if current_user
                 edge_scope = edge_scope.joins(:content_chunk).merge(ContentChunk.accessible_by(current_user))
               else
                 edge_scope = edge_scope.joins(:content_chunk).merge(ContentChunk.public_content)
               end
             end

             # Global View: Top 50 most connected nodes WITHIN SCOPE
             top_nodes_ids = edge_scope
                                  .group(:source_node_id) # Heuristic: Use source node counts
                                  .order(Arel.sql('COUNT(*) DESC'))
                                  .limit(50)
                                  .pluck(:source_node_id)
                                  
             top_nodes = GraphNode.where(id: top_nodes_ids)
             
             # Edges between these nodes (strictly within scope)
             edges = edge_scope.where(source_node_id: top_nodes_ids, target_node_id: top_nodes_ids)
             
             { nodes: top_nodes, edges: edges }
           end

    # Format for Cytoscape (Standardized)
    elements = []
    
    data[:nodes].each do |node|
      # Calculate degree for sizing if not present
      degree = node.try(:degree) || (node.source_edges.count + node.target_edges.count rescue 1) 
      
      elements << { 
        data: { 
          id: node.id.to_s, 
          label: node.name, 
          type: node.label,
          weight: degree,
          description: node.description
        },
        classes: node.label.to_s.downcase.gsub(/\s+/, '-') # CSS Safe class
      }
    end

    data[:edges].each do |edge|
      elements << { 
        data: { 
          id: "e#{edge.id}", 
          source: edge.source_node_id.to_s, 
          target: edge.target_node_id.to_s, 
          label: edge.relationship_type 
        } 
      }
    end

    render json: elements
  end
end
