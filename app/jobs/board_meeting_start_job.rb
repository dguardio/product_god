class BoardMeetingStartJob < ApplicationJob
  queue_as :default

  def perform(meeting_id)
    meeting = BoardMeeting.find(meeting_id)
    BoardMeetingService.new(meeting).start_simulation
    
    # Broadcast update? 
    # The messages creation will trigger broadcasts (if we add callbacks to model)
    # OR we broadcast specifically here.
    # Let's add broadcast callbacks to BoardMessage model for simplicity.
  end
end
