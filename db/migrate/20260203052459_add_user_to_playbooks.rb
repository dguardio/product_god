class AddUserToPlaybooks < ActiveRecord::Migration[7.1]
  def change
    add_reference :playbooks, :user, null: true, foreign_key: true
  end
end
