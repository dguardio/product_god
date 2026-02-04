class CreateTranscriptChunks < ActiveRecord::Migration[7.1]
  def change
    create_table :transcript_chunks do |t|
      t.references :episode, null: false, foreign_key: true
      t.text :content
      t.float :start_timestamp
      t.float :end_timestamp
      t.vector :embedding, limit: 1536

      t.timestamps
    end
  end
end
