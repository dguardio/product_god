class CreatePlaybooks < ActiveRecord::Migration[7.1]
  def change
    create_table :playbooks do |t|
      t.string :title
      t.text :content
      t.jsonb :sources

      t.timestamps
    end
  end
end
