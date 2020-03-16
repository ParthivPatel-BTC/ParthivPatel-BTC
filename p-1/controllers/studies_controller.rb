class StudiesController < ApplicationController
  before_action :set_study, only: %i[show]
  layout 'minimal_distractions', only: [:show]
  skip_before_action :reset_consent, only: [:show]

  def index
    @studies = if current_user.superadmin?
      Study.all.order(study_order: :asc)
    elsif current_user.admin?
      Study.where(created_by: current_user.id).order(study_order: :asc)
    end
  end

  # TODO Remove later - This end point is used to create EMA Presentation files
  def ema_results_data
    if params[:study_id].present? and params[:user_id].present?
      @study = Study.find_by(id: params[:study_id])
      @user = User.find_by(id: params[:user_id])
      @result = StudyCompletion.where(user_id: params[:user_id], study_id: params[:study_id]).last
      respond_to do |format|
        format.html
      end
    end
  end

  def ema_results
    if params[:study_id].present? and params[:user_id].present?
      @result = StudyCompletion.EMA_custom_results(user_id: params[:user_id], study_id: params[:study_id]) 
      respond_to do |format|
        format.html
        format.json  { render :json => @result }
      end
    end
  end

  def create
    # upon creation, redirect to demographics_path --> params[:survey_id]
    # we wont always have current_user... nor will the javascript program know who the current user is cuz it is off-site
    #
    @user_study_completion = if current_user
                               current_user.study_completions.new(study_params)
                             else
                               StudyCompletion.new(study_params)
                             end
    @user_study_completion.save
    cookies[:user_study_completion_id] = @user_study_completion.id
    # send this redirect url back to the javascript experiment, it will redirect to the next page.
    # This can only be
    redirect_url = if current_user && current_user.demographic
                     reset_desired_study
                     end_of_study_index_path(ue_id: @user_study_completion.id)
                   elsif current_user
                     edit_demographics_path(survey_id: @user_study_completion.study_id, ue_id: @user_study_completion.id)
                   else
                     new_demographics_path(survey_id: @user_study_completion.study_id, ue_id: @user_study_completion.id)
                   end
    respond_to do |format|
      format.json { render json: {'redirect_url' => redirect_url}.to_json }
    end
  end

  def show
    redirect_to(root_url, alert: 'Study does not exists') && return if Study.ema_daily?(@study)
    cookies[:desired_study] = params[:id] # cookie is used to redirect to the study after sign up or sign in
    if has_consent?
      current_user.start_study(params[:id]) if current_user && !get_started_study(@study_id)
      set_started_study(@study_id)
      @study_id = @study.id
    else
      cookies[:current_user_session_id] = "#{Time.now.to_i.to_s + ':' + params[:id]}" if cookies[:current_user_session_id].blank?
      redirect_to consent_index_path(study_id: params[:id])
    end

    respond_to do |format|
      format.html
      format.json  { render :json => @study }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_study
    @study = Study.find_by(id: params[:id])
    return unless @study.nil?

    redirect_to(admin_dashboard_index_url, notice: 'Study does not exists') && return
  end

  def study_params
    if current_user.blank?
      params.require(:study).permit(:custom_study_results, :user_id, :study_id, :score).merge(completed_on: Time.now, user_session_id: cookies[:current_user_session_id])
    else
      params.require(:study).permit(:custom_study_results, :user_id, :study_id, :score).merge(completed_on: Time.now)
    end
  end
end
