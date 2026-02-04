class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :username, uniqueness: true, allow_nil: true
  
  has_many :episodes
  has_many :whats_app_chats
  has_many :chat_sessions, dependent: :destroy
  has_many :pdf_documents, dependent: :destroy
  has_many :slack_exports, dependent: :destroy
  has_many :web_pages, dependent: :destroy
  
  def admin?
    admin
  end
end
