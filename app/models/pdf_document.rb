class PdfDocument < ApplicationRecord
  belongs_to :user
  has_many :content_chunks, as: :sourceable, dependent: :destroy
  
  has_one_attached :file

  validates :title, presence: true
  validates :visibility, inclusion: { in: %w[public private] }
  
  scope :public_content, -> { where(visibility: 'public') }
end
