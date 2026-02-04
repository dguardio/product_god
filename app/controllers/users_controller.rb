class UsersController < ApplicationController
  def show
    @user = User.find_by!(username: params[:username])
    
    # "Interact with information they chose to make public"
    # Show public episodes and chats
    @episodes = @user.episodes.public_content.order(published_at: :desc).limit(10)
    @chats = @user.whats_app_chats.public_content.order(created_at: :desc)
    
    # For RAG context
    @user_context = { 
      user: @user, 
      access: :public_only 
    }
  end
end
