class CreateChatSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :chat_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.json :context_filters

      t.timestamps
    end
  end
end
