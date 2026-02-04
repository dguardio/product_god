STDOUT.sync = true

# Configuration
batch_limit = 100 # Start small
scope = ContentChunk.where(embedding: nil).order(:id).limit(batch_limit)
total_count = scope.count

puts "Processing direct batch of #{total_count} chunks..."

processed = 0
errors = 0

scope.find_each do |chunk|
  begin
    print "Chunk #{chunk.id}: "
    
    # 1. Call API
    response = RubyLLM.embed(chunk.content, model: "text-embedding-004")
    vector = response&.vectors
    
    if vector && vector.is_a?(Array)
      # 2. Save directly
      # Using update_columns to bypass potential callbacks/validations that might be interfering
      if chunk.update_columns(embedding: vector, updated_at: Time.current)
        puts "Saved (#{vector.size})"
        processed += 1
      else
        puts "DB Error"
        errors += 1
      end
    else
      puts "API Error: Response data was #{response&.data.class}"
      errors += 1
    end
    
    # Sleep to avoid rate limits
    sleep(0.5)
    
  rescue => e
    puts "Exception: #{e.message}"
    puts e.backtrace.first(5).join("\n")
    errors += 1
  end
end

puts "\nDone. Processed: #{processed}, Errors: #{errors}"
