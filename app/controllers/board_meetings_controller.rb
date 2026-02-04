class BoardMeetingsController < ApplicationController
  def new
    @personas = GraphNode.where("label ILIKE ?", 'Person')
  end

  def create
    @meeting = BoardMeeting.new(
      topic: params[:topic],
      guest_ids: params[:guest_ids]&.map(&:to_i) || [],
      status: 'active'
    )

    if @meeting.save
      # Generate opening statements in background or inline? 
      # Let's do it in a job so we can redirect immediately.
      BoardMeetingStartJob.perform_later(@meeting.id)
      
      redirect_to @meeting
    else
      render :new
    end
  end

  def show
    @meeting = BoardMeeting.find(params[:id])
    @messages = @meeting.board_messages.chronological
    @guests = GraphNode.where(id: @meeting.guest_ids)
  end
end
