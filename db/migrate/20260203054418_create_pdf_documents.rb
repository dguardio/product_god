class CreatePdfDocuments < ActiveRecord::Migration[7.1]
  def change
    create_table :pdf_documents do |t|
      t.string :title
      t.references :user, null: false, foreign_key: true
      t.string :visibility
      t.integer :page_count

      t.timestamps
    end
  end
end
