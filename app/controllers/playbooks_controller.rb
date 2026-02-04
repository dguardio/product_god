class PlaybooksController < ApplicationController
  def index
    @playbooks = current_user.playbooks.order(created_at: :desc)
  end

  def new
    @playbook = current_user.playbooks.build
  end

  def create
    goal = params[:goal]
    if goal.blank?
      flash[:alert] = "Please enter a goal."
      redirect_to new_playbook_path and return
    end

    # Create loading state record
    @playbook = current_user.playbooks.create!(
      title: goal,
      content: "Generating your playbook... this usually takes about 10-20 seconds. Grab a coffee! ☕",
      sources: []
    )
    
    # Enqueue background job
    PlaybookGenerationJob.perform_later(@playbook.id)
    
    redirect_to @playbook
  end

  def show
    @playbook = Playbook.find(params[:id])
  end
end
