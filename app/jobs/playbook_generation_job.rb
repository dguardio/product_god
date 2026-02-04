class PlaybookGenerationJob < ApplicationJob
  queue_as :default

  def perform(playbook_id)
    playbook = Playbook.find(playbook_id)
    
    # Delegate logic to service
    # We need to slightly modify the service to accept an existing playbook instance 
    # OR we can just update the instance here.
    # The service currently returns a new object. Let's refactor the service slightly or just use it here.
    
    # Actually, let's keep the service cleanly separated but adapt usage.
    # We will instantiate the service with the goal, but we need to update THIS playbook, not create a new one.
    
    begin
      # Mark as generating (optional, if we had a status column)
      
      service = PlaybookGenerationService.new(playbook.title)
      
      # We'll monkey-patch or refactor the service to separate generation from persistence
      # OR just copy the logic.
      # Ideally, let's update the service to support saving into an existing record.
      # For now, to keep it simple without changing the service signature too much:
      # We will extract the logic into a `generate_content` method in the service or just call the service 
      # and update our record with its result (ignoring the duplicate DB record created by the service is wasteful).
      
      # Better approach: Refactor service to allow passing a playbook instance.
      
      # Let's do the logic here for now, or update the service. 
      # Updating service is cleaner.
      
      content, sources = PlaybookGenerationService.new(playbook.title).generate
      
      playbook.update!(
        content: content,
        sources: sources,
        # status: 'completed' # if we add status
      )
      
      # Broadcast completion to the view
      Turbo::StreamsChannel.broadcast_replace_to(
        "playbook_#{playbook.id}",
        target: "playbook_#{playbook.id}",
        partial: "playbooks/playbook_content",
        locals: { playbook: playbook }
      )
      
    rescue => e
      Rails.logger.error "Job failed: #{e.message}"
      # Broadcast error state
       Turbo::StreamsChannel.broadcast_update_to(
        "playbook_#{playbook.id}",
        target: "playbook_generation_status",
        html: "<div class='text-red-500'>Failed to generate. Please try again.</div>"
      )
    end
  end
end
