
namespace :embeddings do
  desc "Backfill embeddings for all transcript chunks that are missing them"
  task backfill: :environment do
    scope = ContentChunk.where(embedding: nil)
    total = scope.count
    
    puts "Found #{total} chunks missing embeddings."
    puts "Enqueuing VectorizeChunkJob for each..."
    
    scope.find_each do |chunk|
      VectorizeChunkJob.perform_later(chunk.id)
      print "."
    end
    
    puts "\nDone! #{total} jobs enqueued."
  end
end
