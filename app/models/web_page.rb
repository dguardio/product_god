class WebPage < ApplicationRecord
  belongs_to :user
  has_many :content_chunks, as: :sourceable, dependent: :destroy
  
  validates :title, presence: true
  validates :url, presence: true
  validates :visibility, inclusion: { in: %w[public private] }
  
  scope :public_content, -> { where(visibility: 'public') }
end
