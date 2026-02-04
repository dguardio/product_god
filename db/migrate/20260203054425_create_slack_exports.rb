class CreateSlackExports < ActiveRecord::Migration[7.1]
  def change
    create_table :slack_exports do |t|
      t.string :title
      t.references :user, null: false, foreign_key: true
      t.string :visibility

      t.timestamps
    end
  end
end
