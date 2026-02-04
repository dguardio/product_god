class IngestWebJob < ApplicationJob
  queue_as :default

  def perform(web_page_id)
    page = WebPage.find(web_page_id)
    Ingestors::Web.call(page)
    
    page.content_chunks.each do |chunk|
      VectorizeChunkJob.perform_later(chunk.id)
    end
  end
end
