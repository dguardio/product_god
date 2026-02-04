class GraphNode < ApplicationRecord
  has_many :outgoing_edges, class_name: 'GraphEdge', foreign_key: 'source_node_id', dependent: :destroy
  has_many :incoming_edges, class_name: 'GraphEdge', foreign_key: 'target_node_id', dependent: :destroy
  
  validates :name, presence: true, uniqueness: true
  
  # For neighbor (vector search)
  has_neighbors :embedding

  # Helper to re-generate embedding (can be called after create/update)
  def generate_embedding!
    # Combine name and description for semantic context
    text_to_embed = "#{name}: #{description} #{label}"
    response = RubyLLM.embed(text_to_embed, model: "text-embedding-004")
    update(embedding: response.vectors) if response&.vectors
  end
end
