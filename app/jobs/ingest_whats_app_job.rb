class IngestWhatsAppJob < ApplicationJob
  queue_as :default

  def perform(chat_id)
    chat = WhatsAppChat.find(chat_id)
    Ingestors::WhatsApp.new(chat).call
  rescue => e
    Rails.logger.error "WhatsApp Ingestion Failed for Chat #{chat_id}: #{e.message}"
    raise e
  end
end
