namespace :knowledge_graph do
  desc "Backfill knowledge graph from all transcript chunks"
  task backfill: :environment do
    puts "Starting Knowledge Graph Backfill..."
    total = ContentChunk.count
    puts "Found #{total} chunks."

    ContentChunk.find_each.with_index do |chunk, index|
      # Optional: Check if already processed? 
      # Current logic doesn't mark chunks as processed, but ExtractJob is somewhat idempotent (it finds_or_creates).
      # However, re-running WILL generate LLM costs.
      
      # We could check if any edges exist for this chunk.
      if GraphEdge.where(content_chunk: chunk).exists?
        print "S" # Skipped
      else
        KnowledgeGraph::ExtractJob.perform_later(chunk.id)
        print "." 
      end
      
      # Flush output every 100 items
      puts " #{index + 1}/#{total}" if (index + 1) % 100 == 0
    end
    puts "\nBackfill enqueued!"
  end

  desc "Process specific chunk"
  task :process_chunk, [:chunk_id] => :environment do |_, args|
    chunk_id = args[:chunk_id]
    abort "Please provide chunk_id" unless chunk_id
    
    puts "Processing chunk #{chunk_id}..."
    KnowledgeGraph::ExtractJob.perform_now(chunk_id)
    puts "Done."
  end

  desc "Reset knowledge graph data"
  task reset: :environment do
    puts "Deleting all Knowledge Graph Nodes and Edges..."
    GraphEdge.delete_all
    GraphNode.delete_all
    puts "Done."
  end
end
