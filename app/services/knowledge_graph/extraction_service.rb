module KnowledgeGraph
  class ExtractionService
    def initialize(chunk)
      @chunk = chunk
    end

    def call
      prompt = construct_prompt
      response = call_llm(prompt)
      data = parse_response(response)
      
      return unless data

      ActiveRecord::Base.transaction do
        process_nodes(data['nodes'])
        process_edges(data['edges'])
      end
    end

    private

    def construct_prompt
      <<~PROMPT
        You are a knowledge graph extractor for a product management podcast.
        Analyze the following transcript excerpt and extract:
        
        1. **Nodes**: Key entities mentioned. Focus on:
           - **Person**: Guests, hosts, famous figures.
           - **Company**: Tech companies, startups.
           - **Tool**: Software tools (e.g., Jira, Notion).
           - **Framework**: Methodologies (e.g., "Jobs to be Done", "PLG").
           - **Book**: Books mentioned.
           - **Concept**: Core product concepts.

        2. **Edges**: Relationships between these nodes explicitly mentioned or clearly implied in the text.
           - Examples: "Lenny HOSTS Podcast", "Guest WORKS_AT Company", "Company USES Tool", "Person WROTE Book".
           - Use UPPER_CASE for relationship types.

        Output strictly valid JSON with this structure:
        {
          "nodes": [
            { "name": "Exact Name", "label": "LabelType", "description": "Brief context from text" }
          ],
          "edges": [
            { "source": "Exact Name", "target": "Exact Name", "relationship": "RELATIONSHIP_TYPE", "context": "Snippet proving relationship" }
          ]
        }

        Rules:
        - Normalize names (e.g., "AirBnB" -> "Airbnb").
        - Only extract significant entities.
        - If no clear relationship exists, do not create an edge.

        Transcript Chunk:
        "#{@chunk.content}"
      PROMPT
    end

    def call_llm(prompt)
      # Using Gemini 2.5 Pro for high fidelity extraction
      chat = RubyLLM.chat(model: "gemini-2.5-pro") 
      chat.with_instructions("You are a precise data extraction AI. Output strictly valid JSON.")
      chat.ask(prompt)
    end

    def parse_response(message)
      content = message.content
      # Strip markdown code blocks if present
      content = content.gsub(/^```json\s*/, '').gsub(/\s*```$/, '')
      JSON.parse(content)
    rescue JSON::ParserError => e
      Rails.logger.error "KnowledgeGraph JSON Error for Chunk #{@chunk.id}: #{e.message}"
      nil
    rescue => e
      Rails.logger.error "KnowledgeGraph Extraction Error for Chunk #{@chunk.id}: #{e.message}"
      nil
    end

    def process_nodes(nodes_data)
      return unless nodes_data.is_a?(Array)

      nodes_data.each do |node_data|
        # Find by name case-insensitive to avoid duplicates
        node = GraphNode.find_or_initialize_by(name: node_data['name'])
        
        # Update attributes if new or missing details
        node.label ||= node_data['label']
        node.description ||= node_data['description']
        
        # Vectorize name + description for semantic search later
        # (This implies we should probably do embeddings here or in a callback)
        # For now, we save it. Embedding generation can be async or integrated here.
        # Let's simple save.
        
        node.save!
        
        # Generate embedding if it's missing or if description changed
        if node.embedding.nil? || node.saved_change_to_description?
          # We can do this inline or enqueue a job. Inline for now to ensure data completeness.
          # Rescue errors to not fail the whole transaction just for embedding
          begin
            node.generate_embedding!
          rescue => e
            Rails.logger.error "Failed to generate embedding for Node #{node.name}: #{e.message}"
          end
        end
      end
    end

    def process_edges(edges_data)
      return unless edges_data.is_a?(Array)

      edges_data.each do |edge_data|
        source = GraphNode.find_by(name: edge_data['source'])
        target = GraphNode.find_by(name: edge_data['target'])

        next unless source && target

        # Avoid self-loops
        next if source.id == target.id

        # Idempotency: Check if this specific relationship already exists for this chunk
        GraphEdge.find_or_create_by!(
          source_node: source,
          target_node: target,
          relationship_type: edge_data['relationship'],
          content_chunk: @chunk
        ) do |edge|
          edge.properties = { context: edge_data['context'] }
        end
      end
    end
  end
end
