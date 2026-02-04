class CreateEpisodes < ActiveRecord::Migration[7.1]
  def change
    create_table :episodes do |t|
      t.string :guest
      t.string :title
      t.string :video_id
      t.date :publish_date
      t.text :description
      t.integer :duration_seconds
      t.integer :view_count
      t.string :channel
      t.string :youtube_url

      t.timestamps
    end
  end
end
