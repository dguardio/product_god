class ChangeEmbeddingLimitTo768 < ActiveRecord::Migration[7.1]
  def change
    change_column :transcript_chunks, :embedding, :vector, limit: 768
  end
end
