class CreateWebPages < ActiveRecord::Migration[7.1]
  def change
    create_table :web_pages do |t|
      t.string :title
      t.string :url
      t.text :content_snapshot
      t.references :user, null: false, foreign_key: true
      t.string :visibility

      t.timestamps
    end
  end
end
