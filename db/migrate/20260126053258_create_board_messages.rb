class CreateBoardMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :board_messages do |t|
      t.references :board_meeting, null: false, foreign_key: true
      t.string :sender_type
      t.bigint :sender_graph_node_id
      t.text :content
      t.integer :sequence

      t.timestamps
    end
  end
end
