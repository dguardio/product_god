class BoardMeetingReplyJob < ApplicationJob
  queue_as :default

  def perform(meeting_id, user_content)
    meeting = BoardMeeting.find(meeting_id)
    # The service's handle_user_input creates the USER message but we already created it in controller.
    # We should refactor the service to NOT create the user message, effectively "handle_ai_reply".
    # Or we just pass the content context.
    
    # Update service to just handle the REPLY part.
    BoardMeetingService.new(meeting).generate_ai_reply(user_content)
  end
end
