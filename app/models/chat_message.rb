class ChatMessage < ApplicationRecord
  belongs_to :chat_session
  
  enum role: { user: 0, assistant: 1 }
  
  validates :content, presence: true
end
