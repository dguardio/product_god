require 'open3'
require 'front_matter_parser'

class IngestionService
  REPO_URL = "https://github.com/ChatPRD/lennys-podcast-transcripts.git"
  LOCAL_PATH = Rails.root.join("tmp", "lennys-podcast-transcripts")

  def call
    clone_repo unless Dir.exist?(LOCAL_PATH)
    pull_repo if Dir.exist?(LOCAL_PATH)
    
    process_episodes
  end

  private

  def clone_repo
    puts "Cloning repository..."
    system("git clone #{REPO_URL} #{LOCAL_PATH}")
  end

  def pull_repo
    puts "Pulling latest changes..."
    Dir.chdir(LOCAL_PATH) do
      system("git pull origin main")
    end
  end

  def process_episodes
    files = Dir.glob(File.join(LOCAL_PATH, "episodes", "**", "transcript.md"))
    puts "Found #{files.count} transcripts. Processing..."

    files.each do |file_path|
      process_file(file_path)
    end
  end

  def process_file(file_path)
    # Fix for Date parsing error in YAML
    loader = FrontMatterParser::Loader::Yaml.new(allowlist_classes: [Date])
    parsed = FrontMatterParser::Parser.parse_file(file_path, loader: loader)
    front_matter = parsed.front_matter
    content = parsed.content

    episode = Episode.find_or_initialize_by(video_id: front_matter['video_id'])
    
    # Fallback for older files that might not have video_id or other fields
    episode.title = front_matter['title'] || File.basename(file_path, '.*')
    
    episode.assign_attributes(
      guest: front_matter['guest'],
      youtube_url: front_matter['youtube_url'],
      publish_date: front_matter['publish_date'],
      description: front_matter['description'],
      duration_seconds: front_matter['duration_seconds'],
      view_count: front_matter['view_count'],
      channel: front_matter['channel']
    )

    if episode.save
      puts "Saved: #{episode.title}"
      create_chunks(episode, content)
    else
      puts "Error saving #{front_matter['title']}: #{episode.errors.full_messages}"
    end
  rescue => e
    puts "Failed to process #{file_path}: #{e.message}"
  end

  private

  def create_chunks(episode, text)
    # Simple chunking strategy: split by paragraphs, then group to max tokens
    return if episode.transcript_chunks.exists? # Skip if already chunked (idempotency)

    puts "  Chunking..."
    encoder = Tiktoken.get_encoding("cl100k_base")
    max_tokens = 1000
    
    current_chunk_text = ""
    current_tokens = 0
    
    # Split by standard double newline for paragraphs
    paragraphs = text.split(/\n\n+/)
    
    paragraphs.each do |para|
      para_tokens = encoder.encode(para).size
      
      if current_tokens + para_tokens > max_tokens && !current_chunk_text.empty?
        # Save current chunk
        save_chunk(episode, current_chunk_text)
        current_chunk_text = para
        current_tokens = para_tokens
      else
        current_chunk_text += "\n\n" unless current_chunk_text.empty?
        current_chunk_text += para
        current_tokens += para_tokens
      end
    end
    
    # Save last chunk
    save_chunk(episode, current_chunk_text) if current_chunk_text.present?
  end

  def save_chunk(episode, text)
    chunk = episode.transcript_chunks.create!(
      content: text
    )
    VectorizeChunkJob.perform_later(chunk.id)
  end
end
