# Debug script for Vectorization
STDOUT.sync = true

chunk = ContentChunk.where(embedding: nil).first
if chunk.nil?
  puts "No chunks found needing vectorization."
  exit
end

puts "Debugging Chunk ID: #{chunk.id}"
puts "Current Embedding: #{chunk.embedding.inspect}"

puts "Calling VectorizeChunkJob.perform_now..."
begin
  VectorizeChunkJob.perform_now(chunk.id)
  puts "Job finished."
rescue => e
  puts "Job raised exception: #{e.class} - #{e.message}"
end

chunk.reload
puts "Post-Job Embedding: #{chunk.embedding.present? ? 'PRESENT' : 'NIL'}"

if chunk.embedding.present?
  puts "Vector Header: #{chunk.embedding[0..5].inspect}"
else
  # Try manual
  puts "Job failed to save. Trying manual inline..."
  begin
    response = RubyLLM.embed(chunk.content, model: "text-embedding-004")
    puts "Manual Response Data Size: #{response.data&.size}"
    
    if chunk.update(embedding: response.data)
      puts "Manual Update SUCCESS"
    else
      puts "Manual Update FAILED: #{chunk.errors.full_messages}"
    end
  rescue => e
    puts "Manual Execution Error: #{e.message}"
  end
end
