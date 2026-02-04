class IngestEpisodeJob < ApplicationJob
  queue_as :default

  def perform(episode_id, transcript_text)
    episode = Episode.find(episode_id)
    
    # Use TextChunker directly since we have the raw text
    chunks = TextChunker.split(transcript_text, chunk_size: 1000, chunk_overlap: 100)
    
    chunks.each do |chunk_text|
      ContentChunk.create!(
        sourceable: episode,
        content: chunk_text.strip,
        user: episode.user, # Should be admin usually, or current user
        visibility: episode.visibility
      )
    end
    
    # Trigger vectorization
    episode.content_chunks.each do |chunk|
       VectorizeChunkJob.perform_later(chunk.id)
       # KnowledgeGraph::ExtractJob.perform_later(chunk.id)
    end
  end
end
