class WhatsAppChat < ApplicationRecord
  belongs_to :user
  has_one_attached :file
  has_many :content_chunks, as: :sourceable, dependent: :destroy

  validates :title, presence: true
  validates :visibility, inclusion: { in: %w[public private] }

  scope :public_content, -> { where(visibility: 'public') }
  
  def public?
    visibility == 'public'
  end
end
