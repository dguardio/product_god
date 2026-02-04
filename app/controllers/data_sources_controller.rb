class DataSourcesController < ApplicationController
  before_action :authenticate_user!

  def index
    @episodes = current_user.episodes.order(created_at: :desc).page(params[:episodes_page]).per(5)
    @pdfs = current_user.pdf_documents.order(created_at: :desc).page(params[:pdfs_page]).per(5)
    @slacks = current_user.slack_exports.order(created_at: :desc).page(params[:slacks_page]).per(5)
    @webs = current_user.web_pages.order(created_at: :desc).page(params[:webs_page]).per(5)
    @whatsapps = current_user.whats_app_chats.order(created_at: :desc).page(params[:whatsapps_page]).per(5)
  end

  def create_pdf
    @pdf = current_user.pdf_documents.build(pdf_params)
    @pdf.visibility = 'private' # Default
    
    if @pdf.save
      IngestPdfJob.perform_later(@pdf.id)
      redirect_to data_sources_path, notice: "PDF uploaded and queuing for ingestion."
    else
      redirect_to data_sources_path, alert: "Failed to upload PDF."
    end
  end

  def create_slack
    @slack = current_user.slack_exports.build(slack_params)
    @slack.visibility = 'private'
    
    if @slack.save
      IngestSlackJob.perform_later(@slack.id)
      redirect_to data_sources_path, notice: "Slack export uploaded."
    else
      redirect_to data_sources_path, alert: "Failed to upload Slack export."
    end
  end

  def create_web
    @web = current_user.web_pages.build(web_params)
    @web.visibility = 'private'
    
    if @web.save
      IngestWebJob.perform_later(@web.id)
      redirect_to data_sources_path, notice: "Web page added."
    else
      redirect_to data_sources_path, alert: "Failed to add web page."
    end
  end

  def create_episode
    # Manual transcript upload
    @episode = current_user.episodes.build(
      title: params[:episode][:title], 
      guest: params[:episode][:guest],
      description: "Manual Upload",
      published_at: Time.current,
      visibility: 'private' # User uploaded transcripts are private by default
    )
    
    if @episode.save
      # Content is passed separately, not stored in DB as a giant blob on Episode model 
      # (Though real app probably should store it in ActiveStorage or text col).
      # For now, passing to Job directly.
      IngestEpisodeJob.perform_later(@episode.id, params[:episode][:content])
      redirect_to data_sources_path, notice: "Transcript uploaded."
    else
      redirect_to data_sources_path, alert: "Failed to upload transcript."
    end
  end

  private

  def pdf_params
    params.require(:pdf_document).permit(:title, :file)
  end

  def slack_params
    params.require(:slack_export).permit(:title, :file)
  end

  def web_params
    params.require(:web_page).permit(:title, :url)
  end
end
