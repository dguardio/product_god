class GraphEdge < ApplicationRecord
  belongs_to :source_node, class_name: 'GraphNode'
  belongs_to :target_node, class_name: 'GraphNode'
  belongs_to :content_chunk

  validates :relationship_type, presence: true
end
