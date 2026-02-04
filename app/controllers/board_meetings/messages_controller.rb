class BoardMeetings::MessagesController < ApplicationController
  def create
    @meeting = BoardMeeting.find(params[:board_meeting_id])
    
    # 1. Create User Message immediately
    @user_message = @meeting.board_messages.create!(
      sender_type: 'User',
      content: params[:content],
      sequence: (@meeting.board_messages.maximum(:sequence) || 0) + 1
    )

    # 2. Enqueue AI Response Job
    # We will reuse BoardMeetingStartJob or create a new one. 
    # Let's verify BoardMeetingStartJob. It calls `start_simulation`.
    # We need a `BoardMeetingReplyJob` that calls `handle_user_input`.
    
    BoardMeetingReplyJob.perform_later(@meeting.id, @user_message.content)

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("new_message", partial: "board_meetings/messages/form", locals: { meeting: @meeting }) }
      format.html { redirect_to @meeting }
    end
  end
end
