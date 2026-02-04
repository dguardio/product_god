class Episode < ApplicationRecord
  belongs_to :user, optional: true # Optional for legacy support until backfill
  has_many :content_chunks, as: :sourceable, dependent: :destroy

  validates :visibility, inclusion: { in: %w[public private] }
  
  scope :public_content, -> { where(visibility: 'public') }
  
  def public?
    visibility == 'public'
  end
end
