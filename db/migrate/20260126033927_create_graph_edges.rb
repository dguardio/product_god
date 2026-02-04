class CreateGraphEdges < ActiveRecord::Migration[7.1]
  def change
    create_table :graph_edges do |t|
      t.references :source_node, null: false, foreign_key: { to_table: :graph_nodes }
      t.references :target_node, null: false, foreign_key: { to_table: :graph_nodes }
      t.string :relationship_type
      t.references :transcript_chunk, null: false, foreign_key: true
      t.jsonb :properties

      t.timestamps
    end
    
    # Add unique index to prevent duplicate edges of same type between nodes in same chunk context?
    # Or just generic index for lookups
    add_index :graph_edges, [:source_node_id, :target_node_id, :relationship_type], name: 'index_edges_on_source_target_rel'
  end
end
