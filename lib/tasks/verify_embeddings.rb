
# Usage: bin/rails runner lib/tasks/verify_embeddings.rb

query = "how to ask for advice from friends"
puts "Query: '#{query}'"

# 1. Generate embedding for query
response = RubyLLM.embed(query, model: "text-embedding-004")
query_embedding = response.vectors

if query_embedding.nil? || query_embedding.empty?
  puts "Error: Could not generate embedding for query."
  exit
end

# 2. Search for nearest neighbors using pgvector
# Assuming the ContentChunk model has 'has_neighbors :embedding'
results = ContentChunk.nearest_neighbors(:embedding, query_embedding, distance: "cosine").limit(3)

puts "\nTop 3 Results:"
results.each_with_index do |chunk, index|
  similarity = chunk.neighbor_distance # neighbor_distance is usually populated given we sort by it
  puts "\n--- Result #{index + 1} (Distance: #{similarity}) ---"
  puts chunk.content.truncate(300) 
end
