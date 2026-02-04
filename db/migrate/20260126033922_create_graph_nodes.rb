class CreateGraphNodes < ActiveRecord::Migration[7.1]
  def change
    create_table :graph_nodes do |t|
      t.string :name
      t.string :label
      t.text :description
      t.jsonb :properties
      t.vector :embedding, limit: 768

      t.timestamps
    end
    add_index :graph_nodes, :name
  end
end
