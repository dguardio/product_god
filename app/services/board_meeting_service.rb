class BoardMeetingService
  def initialize(board_meeting)
    @meeting = board_meeting
  end

  # Starts the simulation (opening statements)
  def start_simulation
    guests = GraphNode.where(id: @meeting.guest_ids)
    
    # Pre-fetch personas context
    personas = guests.map do |guest|
      {
        id: guest.id,
        name: guest.name,
        context: fetch_context(guest, @meeting.topic)
      }
    end

    # Generate opening statements
    prompt = construct_system_prompt(@meeting.topic, personas)
    prompt += "\n\nTASK: Generate an opening statement for each guest to kick off the discussion. Output ONLY JSON array: [{ \"guest_id\": ID, \"text\": \"...\" }, ...]"

    response_json = call_llm(prompt)
    
    ActiveRecord::Base.transaction do
      response_json.each_with_index do |msg, idx|
        BoardMessage.create!(
          board_meeting: @meeting,
          sender_type: 'AI',
          sender_graph_node_id: msg['guest_id'],
          content: msg['text'],
          sequence: idx + 1
        )
      end
    end
  end

  # Handles AI response to user input
  def generate_ai_reply(user_text)
    # 1. Helper to fetch latest N messages for context
    history = @meeting.board_messages.last(10).map do |m|
      name = m.sender_type == 'User' ? "User" : m.sender_node&.name
      "#{name}: #{m.content}"
    end.join("\n")

    # 2. Ask LLM to respond
    # Identify guests again
    guests = GraphNode.where(id: @meeting.guest_ids)
    persona_summary = guests.map { |g| "#{g.name} (ID: #{g.id})" }.join(", ")

    prompt = <<~PROMPT
      You are simulating a board meeting.
      Topic: #{@meeting.topic}
      Participants: #{persona_summary}
      
      Conversation History:
      #{history}
      
      User just said: "#{user_text}"
      
      Determine which AI participant(s) should respond effectively. 
      It can be one or both, depending on who has a strong opinion or was addressed.
      Keep responses concise and conversational (chat style).
      
      Output strictly JSON: [{ "guest_id": 123, "text": "Response..." }]
    PROMPT

    response_json = call_llm(prompt)
    
    current_seq = @meeting.board_messages.maximum(:sequence) || 0
    
    ActiveRecord::Base.transaction do
      response_json.each do |msg|
        current_seq += 1
        BoardMessage.create!(
          board_meeting: @meeting,
          sender_type: 'AI',
          sender_graph_node_id: msg['guest_id'],
          content: msg['text'],
          sequence: current_seq
        )
      end
    end
  end

  private

  def fetch_context(guest, topic)
    # RAG search for guest-specific opinions
    embedding = RubyLLM.embed("#{guest.name} opinion on #{topic}", model: "text-embedding-004").vectors
    return "" unless embedding

    # This is rough; ideally we filter chunks by guest.
    # Our GraphEdge connects chunks to guests! We can use that.
    # chunks = guest.outgoing_edges.map(&:transcript_chunk) 
    # But filtering nearest neighbors by associated record is complex with pgvector alone in one query without join hack.
    # For MVP, regular search + query refinement "What does [Guest] say about [Topic]" is usually okay if the LLM is smart.
    # Let's try the simpler RAG for now:
    
    chunks = ContentChunk.nearest_neighbors(:embedding, embedding, distance: "cosine").limit(5)
    chunks.map(&:content).join("\n")
  end

  def construct_system_prompt(topic, personas)
    context_block = personas.map do |p|
      "--- PERSONA: #{p[:name]} (ID: #{p[:id]}) ---\nContext/Beliefs:\n#{p[:context]}"
    end.join("\n\n")

    <<~PROMPT
      You are simulating a high-stakes board meeting Debate.
      Topic: #{topic}
      
      #{context_block}
      
      Roleplay instructions:
      - Adopt the tone, vocabulary, and philosophy of each guest based on their context.
      - If one is a "Product" person and other is "Growth", highlight those differences.
      - Disagree respectfully but sharply if philosophies diverge.
    PROMPT
  end

  def call_llm(prompt)
    chat = RubyLLM.chat(model: "gemini-2.5-pro")
    chat.with_instructions("Output valid JSON only.")
    response = chat.ask(prompt)
    
    content = response.content.gsub(/^```json\s*/, '').gsub(/\s*```$/, '')
    JSON.parse(content)
  rescue => e
    Rails.logger.error "BoardMeeting LLM Error: #{e.message}"
    []
  end
end
