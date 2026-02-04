class ChatSessionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat_session, only: [:show, :update, :destroy]

  def index
    @chat_sessions = current_user.chat_sessions.order(updated_at: :desc)
  end

  def show
    @messages = @chat_session.chat_messages.order(created_at: :asc)
  end

  def create
    @chat_session = current_user.chat_sessions.create!(
      title: "New Chat #{Time.now.strftime('%H:%M')}" # Default title, can generate later
    )
    redirect_to @chat_session
  end
  
  def update
    # 1. User Message
    user_content = params[:content]
    return redirect_to @chat_session if user_content.blank?

    @chat_session.chat_messages.create!(role: :user, content: user_content)

    # 2. Get AI Response
    # Pass target_user if filtering by profile (stored in context_filters or params?)
    # For MVP, just standard RAG
    
    rag_result = RagSearchService.new(user: current_user).ask(user_content)
    
    # 3. Save AI Message
    @chat_session.chat_messages.create!(
      role: :assistant,
      content: rag_result[:answer]["answer"], # Extract answer text
      sources: rag_result[:sources].map { |s| { id: s.id, content: s.content.truncate(100) } } # Simple source serialization
    )
    
    # Update title if it's the first message? (Optional enhancement)
    
    redirect_to @chat_session
  end
  
  def destroy
    @chat_session.destroy
    redirect_to chat_sessions_path, notice: "Chat deleted."
  end

  private

  def set_chat_session
    @chat_session = current_user.chat_sessions.find(params[:id])
  end
end
