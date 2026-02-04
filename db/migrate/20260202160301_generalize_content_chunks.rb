class GeneralizeContentChunks < ActiveRecord::Migration[7.1]
  def up
    # 1. Rename table
    rename_table :transcript_chunks, :content_chunks

    # 2. Add polymorphic columns
    add_column :content_chunks, :sourceable_type, :string
    add_column :content_chunks, :sourceable_id, :bigint
    add_index :content_chunks, [:sourceable_type, :sourceable_id]

    # 3. Backfill data
    # We use execute for direct SQL to ensure it runs fast and doesn't depend on model definition
    execute <<-SQL
      UPDATE content_chunks
      SET sourceable_type = 'Episode',
          sourceable_id = episode_id
    SQL

    # 4. Remove old FK and column
    # Remove FK from content_chunks to episodes
    if foreign_key_exists?(:content_chunks, :episodes)
      remove_foreign_key :content_chunks, :episodes
    end
    
    # Remove index on episode_id if strictly necessary, but removing column usually removes index
    remove_column :content_chunks, :episode_id, :bigint

    # 5. Update GraphEdges
    # Rename column
    rename_column :graph_edges, :transcript_chunk_id, :content_chunk_id
    
    # Remove old FK on graph_edges pointing to transcript_chunks (which is now content_chunks)
    # The constraint name probably still references transcript_chunks or auto-generated name
    # We'll try to remove by column
    if foreign_key_exists?(:graph_edges, column: :content_chunk_id)
      remove_foreign_key :graph_edges, column: :content_chunk_id
    end
    
    # Add new FK to content_chunks
    add_foreign_key :graph_edges, :content_chunks
  end

  def down
    # Reverse operations
    remove_foreign_key :graph_edges, :content_chunks
    rename_column :graph_edges, :content_chunk_id, :transcript_chunk_id
    
    add_column :content_chunks, :episode_id, :bigint
    
    execute <<-SQL
      UPDATE content_chunks
      SET episode_id = sourceable_id
      WHERE sourceable_type = 'Episode'
    SQL

    change_column_null :content_chunks, :episode_id, false
    
    remove_index :content_chunks, [:sourceable_type, :sourceable_id]
    remove_column :content_chunks, :sourceable_id
    remove_column :content_chunks, :sourceable_type

    add_foreign_key :content_chunks, :episodes
    rename_table :content_chunks, :transcript_chunks
    add_foreign_key :graph_edges, :transcript_chunks
  end
end
