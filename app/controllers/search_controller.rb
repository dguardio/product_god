class SearchController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :query]

  def index

    # Renders the search form
  end

  def query
    @query = params[:q]
    
    if @query.present?
      target_user = User.find(params[:scope_user_id]) if params[:scope_user_id].present?
      
      result = RagSearchService.new(user: current_user, target_user: target_user).ask(@query)
      @answer = result[:answer]
      @sources = result[:sources]
    end

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update("results", partial: "results") }
      format.html { render :index }
    end
  end
end
