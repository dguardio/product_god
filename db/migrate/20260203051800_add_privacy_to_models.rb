class AddPrivacyToModels < ActiveRecord::Migration[7.1]
  def change
    # 1. Users
    add_column :users, :username, :string
    add_column :users, :admin, :boolean, default: false
    add_index :users, :username, unique: true

    # 2. Episodes
    add_reference :episodes, :user, foreign_key: true, null: true # Null initially, will backfill
    add_column :episodes, :visibility, :string, default: 'public' # Legacy content is public
    add_index :episodes, :visibility

    # 3. WhatsAppChats
    add_column :whats_app_chats, :visibility, :string, default: 'private'
    add_index :whats_app_chats, :visibility

    # 4. ContentChunks (Denormalization for performance)
    add_reference :content_chunks, :user, foreign_key: true, null: true
    add_column :content_chunks, :visibility, :string
    add_index :content_chunks, :visibility
    # Compound index for RAG filtering: WHERE visibility='public' OR user_id=X
    add_index :content_chunks, [:user_id, :visibility] 
  end
end
