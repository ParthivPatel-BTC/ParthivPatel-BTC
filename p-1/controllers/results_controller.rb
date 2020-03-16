class ResultsController < ApplicationController
  before_action :validate_current_user, only: :destroy

  def show
    @result = if current_user
                current_user.study_completions.where(id: params[:id]).first
              elsif cookies[:current_user_session_id].present?
                StudyCompletion.where(id: cookies[:user_study_completion_id], user_session_id: cookies[:current_user_session_id]).first
              end
    if @result.blank?
      redirect_to(root_path, notice: 'You are not authorized to view that page.') and return
    end
    @study = @result.study
    @recommended_studies = User.recommended_studies(user_id: current_user&.id, current_user_session_id: cookies[:current_user_session_id], study_taken: @study)
    @study_path_encoded = URI.encode(study_url(@study))
    @social_message = URI.encode("I just took #{@study.name} study, you should too. ")
    @show_standard_results = !@study.js_presentation_url.url

    @graph_data = @result.linear_gradient_graph_computation

    respond_to do |format|
      format.html
      format.json  { render :json => @result }
    end
  end

  def destroy
    current_user.delete_all_associated_results(Feedback::FEEDBACK_TYPE_HASH[:delete_results])
    respond_to do |format|
      format.html { redirect_to setting_path, notice: 'Study Data was successfully deleted.' }
      format.json { head :no_content }
    end
  end
end
