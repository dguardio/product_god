class CreateBoardMeetings < ActiveRecord::Migration[7.1]
  def change
    create_table :board_meetings do |t|
      t.string :topic
      t.jsonb :guest_ids
      t.string :status

      t.timestamps
    end
  end
end
