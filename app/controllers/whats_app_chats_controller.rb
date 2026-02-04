class WhatsAppChatsController < ApplicationController
  def index
    @chats = WhatsAppChat.where(user: current_user).order(created_at: :desc)
  end

  def show
    @chat = WhatsAppChat.find(params[:id])
    # Ensure user owns chat
    redirect_to whats_app_chats_path, alert: "Not authorized" unless @chat.user == current_user
  end

  def new
    @chat = WhatsAppChat.new
  end

  def create
    @chat = WhatsAppChat.new(chat_params)
    @chat.user = current_user

    if @chat.save
      # Enqueue ingestion
      IngestWhatsAppJob.perform_later(@chat.id)
      
      redirect_to @chat, notice: "WhatsApp chat uploaded successfully. Processing started."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def chat_params
    params.require(:whats_app_chat).permit(:title, :file)
  end
end
