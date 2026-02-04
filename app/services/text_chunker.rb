module TextChunker
  def self.split(text, chunk_size: 1000, chunk_overlap: 100)
    # Simple recursive character text splitter logic
    # 1. Clean text
    text = text.to_s.strip
    return [] if text.empty?
    
    # If block given, yield; otherwise return array
    if block_given?
      start_idx = 0
      while start_idx < text.length
        end_idx = start_idx + chunk_size
        
        # If we are not at end, try to find a natural break
        if end_idx < text.length
          # Try to break at paragraph -> sentence -> word
          break_match = text[start_idx..end_idx].rindex(/\n\n|\.\s|\n|\s/)
          
          if break_match
            # Adjust end_idx to the break point
            end_idx = start_idx + break_match
          end
        end
        
        # Extract chunk
        chunk = text[start_idx...end_idx].strip
        yield chunk unless chunk.empty?
        
        # Move start_idx, accounting for overlap
        new_start_idx = end_idx - chunk_overlap
        
        # CRITICAL: Ensure we always advance significantly to avoid infinite loops or crawling
        # If overlap pushed us back behind or to the current start, force a move forward.
        # Advance by at least 50% of the chunk we just emitted, or 1 char minimum.
        min_progress = [(chunk.length * 0.5).to_i, 1].max
        
        if new_start_idx < start_idx + min_progress
           start_idx += min_progress
        else
           start_idx = new_start_idx
        end 
      end
    else
      # Re-use logic or just collect (simplification: duplicate logic or recursive call?)
      # For now, just duplicate the loop for array return to keep it simple without recursive meta-programming
      chunks = []
      split(text, chunk_size: chunk_size, chunk_overlap: chunk_overlap) { |c| chunks << c }
      chunks
    end
  end
end
