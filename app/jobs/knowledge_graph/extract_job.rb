module KnowledgeGraph
  class ExtractJob < ApplicationJob
    queue_as :default

    def perform(chunk_id)
      chunk = ContentChunk.find(chunk_id)
      KnowledgeGraph::ExtractionService.new(chunk).call
    end
  end
end
