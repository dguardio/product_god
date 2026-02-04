module Ingestors
  class WhatsApp
    TIMESTAMP_REGEX = /^\[(\d{2}\/\d{2}\/\d{2,4}), (\d{1,2}:\d{2}:\d{2})\s?([AP]M)?\]\s/

    def initialize(chat)
      @chat = chat
    end

    def call
      downloaded_content = @chat.file.download.force_encoding('UTF-8')
      
      # Process file in batches to avoid memory explosion with huge strings
      chunks_count = 0
      buffer = ""
      overlap_buffer = ""
      
      downloaded_content.each_line do |line|
        line = line.strip
        next if line.empty?
        
        buffer += "#{line}\n"
        
        # When buffer gets large enough (~50KB), process it
        if buffer.length > 50_000
          text_to_process = overlap_buffer + buffer
          
          # We need to be careful not to split in the middle of a message if possible, 
          # but TextChunker handles ensuring we don't return partial garbage if we use it right.
          # Actually, TextChunker returns chunks. The last chunk might be cut off.
          # Ideally we keep the overlap from the LAST chunk generated.
          
          # Simplified strategy: Just process, and keep the last N chars from the buffer to prepend to next.
          
          TextChunker.split(text_to_process, chunk_size: 1500, chunk_overlap: 150) do |chunk_text|
            create_chunk(chunk_text)
            chunks_count += 1
          end
          
          # Keep last 200 chars for context overlap on next batch
          overlap_buffer = buffer.last(200) || ""
          buffer = ""
        end
      end

      # Process remaining buffer
      if buffer.present?
        text_to_process = overlap_buffer + buffer
        TextChunker.split(text_to_process, chunk_size: 1500, chunk_overlap: 150) do |chunk_text|
          create_chunk(chunk_text)
          chunks_count += 1
        end
      end
      
      @chat.update!(processed: true)
      chunks_count
    end

    private

    def create_chunk(content)
      return if content.strip.empty?
      
      chunk = ContentChunk.create!(
        sourceable: @chat,
        content: content
      )
      
      # Enqueue processing
      VectorizeChunkJob.perform_later(chunk.id)
      KnowledgeGraph::ExtractJob.perform_later(chunk.id)
    end
  end
end
