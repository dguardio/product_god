class CreateChatMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :chat_messages do |t|
      t.references :chat_session, null: false, foreign_key: true
      t.integer :role
      t.text :content
      t.json :sources

      t.timestamps
    end
  end
end
