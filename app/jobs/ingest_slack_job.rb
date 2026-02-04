class IngestSlackJob < ApplicationJob
  queue_as :default

  def perform(slack_export_id)
    export = SlackExport.find(slack_export_id)
    Ingestors::Slack.call(export)
    
    export.content_chunks.each do |chunk|
      VectorizeChunkJob.perform_later(chunk.id)
    end
  end
end
