class RagSearchService
  def initialize(context = {})
    @context = context
  end

  def ask(query)
    @query = query
    # 1. Retrieve relevant context
    chunks = retrieve_context
    
    if chunks.empty?
      return {
        answer: "I couldn't find any relevant information in the transcripts to answer your question.",
        sources: []
      }
    end

    # 2. Construct the prompt
    context_text = chunks.map { |c| "- #{c.content} (Source: #{c.sourceable.try(:title) || c.sourceable_id})" }.join("\n\n")
    
    system_prompt = <<~PROMPT
      You are an expert assistant for the "Product God" podcast project.

      Your job is to answer the user's question using ONLY the information provided in the context below.
      Treat the context as the single source of truth.

      You MUST output your response in valid JSON format using the following schema:
      {
        "answer": "Direct answer to the user's question based strictly on the provided context.",
        "key_points": [
          "Supporting detail from the context"
        ],
        "related_topics": [
          "Related topic mentioned in the context"
        ],
        "confidence": "high | medium | low",
        "context_gaps": [
          "Specific information missing from the context, if any"
        ]
      }

      Guidelines:
      - Be clear, accurate, and concise.
      - If the context contains relevant information, synthesize it into a helpful answer.
      - Do NOT add external facts, assumptions, or personal opinions.
      - Respond ONLY in valid JSON.
      - Do not include markdown code blocks (```json), explanations, or extra text.
      - If the answer cannot be determined from the context, return null for the "answer" field and explain what is missing in the "context_gaps" field.

      Context:
      #{context_text}
    PROMPT

    # 3. Generate Answer
    Rails.logger.info "DEBUG: RagSearchService PID=#{Process.pid} Requesting Model=gemini-2.5-pro"
    chat = RubyLLM.chat(model: "gemini-2.5-pro")
    
    # Set system prompt
    chat.with_instructions(system_prompt)

    # Ask the question
    message = chat.ask(@query)
    
    # Parse JSON (Handle potential markdown wrapping just in case)
    json_str = message.content
    json_str = json_str.gsub(/^```json\s*/, '').gsub(/\s*```$/, '') # Strip markdown blocks
    
    parsed_response = JSON.parse(json_str)

    {
      answer: parsed_response, # Now a Hash
      sources: chunks
    }
  rescue JSON::ParserError => e
    Rails.logger.error "RAG JSON Error: #{e.message}"
    { answer: { "answer" => "Error parsing AI response.", "confidence" => "low" }, sources: chunks }
  rescue => e
    Rails.logger.error "RAG Error: #{e.message}"
    { answer: { "answer" => "An error occurred.", "confidence" => "low" }, sources: chunks }
  end

  private

  def retrieve_context(limit: 5)
    # Generate embedding for the query
    embedding_response = RubyLLM.embed(@query, model: "text-embedding-004")
    query_vector = embedding_response&.vectors

    return [] unless query_vector

    # Search database
    # Privacy Scope: Default to public if no user
    # If target_user is specified (e.g. filtering by a specific profile), restrict to that user's public content
    scope = ContentChunk.accessible_by(@context[:user])
    
    if @context[:target_user]
      # Intersect accessible scope with target user's ownership
      scope = scope.where(user: @context[:target_user])
    end

    scope.nearest_neighbors(:embedding, query_vector, distance: "cosine").limit(limit).includes(:sourceable)
  end
end
