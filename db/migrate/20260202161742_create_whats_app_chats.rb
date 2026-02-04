class CreateWhatsAppChats < ActiveRecord::Migration[7.1]
  def change
    create_table :whats_app_chats do |t|
      t.string :title
      t.references :user, null: false, foreign_key: true
      t.boolean :processed

      t.timestamps
    end
  end
end
