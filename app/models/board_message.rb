class BoardMessage < ApplicationRecord
  belongs_to :board_meeting
  belongs_to :sender_node, class_name: 'GraphNode', foreign_key: 'sender_graph_node_id', optional: true
  
  scope :chronological, -> { order(sequence: :asc) }
  
  after_create_commit do
    broadcast_append_to "board_meeting_#{board_meeting_id}", 
                        partial: "board_meetings/message", 
                        locals: { message: self },
                        target: "messages"
  end
end
