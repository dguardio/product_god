class PlaybookGenerationService
  def initialize(goal, user: nil)
    @goal = goal
    @user = user
  end

  def call
    content, sources = generate
    
    Playbook.create!(
      title: @goal,
      content: content,
      sources: sources
    )
  end

  def generate
    # 1. Retrieve Context
    # We will do a manual embedding search here to control the limit.
    embedding = RubyLLM.embed(@goal, model: "text-embedding-004").vectors
    return [nil, []] unless embedding

    scope = ContentChunk.accessible_by(@user)
    related_chunks = scope.nearest_neighbors(:embedding, embedding, distance: "cosine").limit(20)
    
    context_text = related_chunks.map do |chunk|
      guest_name = chunk.sourceable.respond_to?(:guest) ? chunk.sourceable.guest : "Unknown Guest"
      title = chunk.sourceable.respond_to?(:title) ? chunk.sourceable.title : "Unknown Title"
      "Guest: #{guest_name}\nTitle: #{title}\nContent: #{chunk.content}"
    end.join("\n\n---\n\n")

    # 2. Synthesize with LLM
    prompt = <<~PROMPT
      You are an expert Chief Product Officer and consultant.
      Your task is to create a detailed, actionable "Playbook" for the following goal:
      
      GOAL: "#{@goal}"
      
      Use the provided transcript excerpts as your primary knowledge base. 
      Synthesize the best advice into a structured step-by-step guide.
      
      Requirements:
      - Use GITHUB FLAVORED MARKDOWN.
      - Use headers (##, ###) to structure the steps.
      - Use bullet points (*) and numbered lists (1.) where appropriate.
      - **CRITICAL**: Use Task Lists (- [ ]) for actionable checklists.
      - Cite the specific Guest or Episode for every major piece of advice (e.g., "As Lenny suggests..." or "According to Gibson Biddle...").
      - Include a "Common Pitfalls" section.
      - Tone: Professional, encouraging, and highly tactical.
      
      CONTEXT:
      #{context_text}
    PROMPT

    # Use 2.5 Pro for best reasoning/writing capability
    chat = RubyLLM.chat(model: "gemini-2.5-pro")
    response = chat.ask(prompt)
    
    sources_data = related_chunks.map do |c|
      guest_name = c.sourceable.respond_to?(:guest) ? c.sourceable.guest : nil
      title = c.sourceable.respond_to?(:title) ? c.sourceable.title : nil
      { id: c.id, guest: guest_name, title: title }
    end
    
    [response.content, sources_data]
  end
end
