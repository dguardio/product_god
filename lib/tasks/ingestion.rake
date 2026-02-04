namespace :ingest do
  desc "Ingest podcast transcripts from GitHub"
  task transcripts: :environment do
    IngestionService.new.call
  end
end
