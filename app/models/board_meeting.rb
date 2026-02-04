class BoardMeeting < ApplicationRecord
  has_many :board_messages, -> { order(sequence: :asc) }, dependent: :destroy
end
