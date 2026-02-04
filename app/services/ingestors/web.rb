require 'open-uri'
require 'nokogiri'

module Ingestors
  class Web
    def self.call(web_page)
      new(web_page).call
    end

    def initialize(web_page)
      @web_page = web_page
    end

    def call
      return if @web_page.url.blank?

      begin
        html = URI.open(@web_page.url).read
        doc = Nokogiri::HTML(html)

        # Remove clutter
        doc.css('script, style, nav, footer, iframe, header').remove

        # Extract main text (simple heuristic: specific tags or body)
        # Using a simple text extraction for MVP.
        text = doc.css('body').text.squeeze(" \n").strip
        
        # Save snapshot
        @web_page.update!(content_snapshot: text)

        create_chunks(text)
      rescue => e
        Rails.logger.error "Web Ingestion Error for #{@web_page.url}: #{e.message}"
      end
    end

    private

    def create_chunks(text)
      chunks = TextChunker.split(text, chunk_size: 1000, chunk_overlap: 100)
      
      chunks.each do |chunk_text|
        ContentChunk.create!(
          sourceable: @web_page,
          content: chunk_text.strip,
          user: @web_page.user,
          visibility: @web_page.visibility
        )
      end
    end
  end
end
