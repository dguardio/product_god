require 'zip'
require 'json'

module Ingestors
  class Slack
    def self.call(slack_export)
      new(slack_export).call
    end

    def initialize(slack_export)
      @slack_export = slack_export
    end

    def call
      return unless @slack_export.file.attached?

      @slack_export.file.open do |tempfile|
        Zip::File.open(tempfile) do |zip_file|
          # 1. Map Users (users.json)
          users_entry = zip_file.find_entry('users.json')
          user_map = {}
          if users_entry
            users_data = JSON.parse(users_entry.get_input_stream.read)
            users_data.each { |u| user_map[u['id']] = u['real_name'] || u['name'] }
          end

          # 2. Iterate Channels (Folders)
          zip_file.each do |entry|
            next unless entry.file?
            next if entry.name.end_with?('.json') && !entry.name.include?('/') # Skip root files except users

            # Structure: channel_name/date.json
            parts = entry.name.split('/')
            next if parts.length < 2
            
            channel_name = parts[0]
            
            # Parse Channel History
            messages = JSON.parse(entry.get_input_stream.read)
            
            # Group into chunks (Daily Digest per Channel)
            process_channel_day(channel_name, messages, user_map)
          end
        end
      end
    end

    private

    def process_channel_day(channel, messages, user_map)
      # Filter for real messages
      content_buffer = "Channel: ##{channel}\n\n"
      
      messages.each do |msg|
        next unless msg['type'] == 'message' && msg['text'].present?
        
        user_name = user_map[msg['user']] || "Unknown User"
        ts = Time.at(msg['ts'].to_f).strftime("%H:%M")
        
        content_buffer += "[#{ts}] #{user_name}: #{msg['text']}\n"
      end

      # Create chunk(s) from this buffer
      # If massive, we might need to split, but let's assume one day per channel fits well enough or split if huge.
      if content_buffer.length > 5000
        # Split logic
        chunks = TextChunker.split(content_buffer, chunk_size: 2000, chunk_overlap: 100)
        chunks.each { |c| save_chunk(c) }
      else
        save_chunk(content_buffer)
      end
    end

    def save_chunk(content)
      ContentChunk.create!(
        sourceable: @slack_export,
        content: content,
        user: @slack_export.user,
        visibility: @slack_export.visibility
      )
    end
  end
end
