module Ingestors
  class Pdf
    def self.call(pdf_document)
      new(pdf_document).call
    end

    def initialize(pdf_document)
      @pdf_document = pdf_document
    end

    def call
      return unless @pdf_document.file.attached?

      @pdf_document.file.open do |tempfile|
        reader = PDF::Reader.new(tempfile)
        
        full_content = ""
        reader.pages.each_with_index do |page, i|
          text = page.text
          next if text.blank?
          
          full_content += "\n\n--- Page #{i+1} ---\n\n"
          full_content += text
        end

        create_chunks(full_content)
      end
      
      # Mark processed? (If we add a processed flag to the model later)
    end

    private

    def create_chunks(text)
      chunks = TextChunker.split(text, chunk_size: 1000, chunk_overlap: 100)
      
      chunks.each_with_index do |chunk_text, index|
        ContentChunk.create!(
          sourceable: @pdf_document,
          content: chunk_text.strip,
          user: @pdf_document.user,
          visibility: @pdf_document.visibility
        )
      end
    end
  end
end
