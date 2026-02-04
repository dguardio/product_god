class ContentChunk < ApplicationRecord
  belongs_to :sourceable, polymorphic: true
  belongs_to :user, optional: true
  
  has_neighbors :embedding
  
  before_save :inherit_privacy_metadata

  scope :public_content, -> { where(visibility: 'public') }
  scope :accessible_by, ->(user) {
    if user
      where(visibility: 'public').or(where(user: user))
    else
      where(visibility: 'public')
    end
  }

  private

  def inherit_privacy_metadata
    if sourceable&.respond_to?(:user)
      self.user = sourceable.user
    end
    
    if sourceable&.respond_to?(:visibility)
      self.visibility = sourceable.visibility
    end
  end
end
