class VectorizeChunkJob < ApplicationJob
  queue_as :default

  def perform(chunk_id)
    chunk = ContentChunk.find(chunk_id)
    return if chunk.embedding.present?

    # Using RubyLLM to generate embeddings
    # Make sure ENV['OPENAI_API_KEY'] is set if using OpenAI
    
    puts "[Job] Requesting embedding for Chunk #{chunk.id}..."
    
    begin
      response = RubyLLM.embed(chunk.content, model: "text-embedding-004")
      puts "[Job] Got response. Vector size: #{response&.vectors&.size}"
    rescue => e
      puts "[Job] ERROR calling RubyLLM: #{e.message}"
      Rails.logger.error("Error calling RubyLLM for Chunk #{chunk.id}: #{e.message}")
      raise e
    end
    
    # For single input, response.data is the vector (Array of Floats)
    embedding_vector = response.vectors

    if embedding_vector
      puts "[Job] Updating DB with vector size: #{embedding_vector.size}"
      if chunk.update!(embedding: embedding_vector)
        puts "[Job] Update! successful."
      else
        puts "[Job] Update! FAILED (should have raised)."
      end
    else
      puts "[Job] Embedding vector is NIL or FALSE."
      Rails.logger.error "Failed to generate embedding for Chunk #{chunk.id}"
    end
  rescue RubyLLM::Error => e
    Rails.logger.error "RubyLLM Error: #{e.message}"
    retry_job wait: 5.minutes, queue: :low_priority
  end
end
