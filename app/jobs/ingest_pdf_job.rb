class IngestPdfJob < ApplicationJob
  queue_as :default

  def perform(pdf_document_id)
    pdf = PdfDocument.find(pdf_document_id)
    Ingestors::Pdf.call(pdf)
    
    # Vectorize and Extract KG for new chunks
    pdf.content_chunks.each do |chunk|
      VectorizeChunkJob.perform_later(chunk.id)
      # KnowledgeGraph::ExtractJob.perform_later(chunk.id) # Optional for now to save tokens
    end
  end
end
