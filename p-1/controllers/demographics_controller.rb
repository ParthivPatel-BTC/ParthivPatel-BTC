class DemographicsController < ApplicationController
  before_action :validate_current_user, only: [:show, :edit, :update]

  before_action :find_current_user_demographic, only: [:show, :edit, :update]

  # Probably not required anymore. Renamed from wrong 'Index' action
  def study_completion_step
    # set demographic information here
    reset_desired_study # if you made it this far, you no longer need to be redirected to a study after sign up

    @submit_path = demographics_path
    if current_user
      if current_user.demographic
      # already done the demographics, redirect to end of survey questions

        redirect_to end_of_study_index_path(ue_id: params[:ue_id])
      else
        @ue_id = params[:ue_id]

        @demographic = current_user.build_demographic
      end
    else
      # not logged in
      @ue_id = cookies[:user_study_completion_id]
      @demographic = StudyCompletion.find(@ue_id).build_demographic
    end
  end

  def create
    if current_user
      @demographic = current_user.build_demographic(demographic_params)
    else
      create_params = demographic_params
      create_params.merge!(user_session_id: cookies[:current_user_session_id]) if cookies[:current_user_session_id].present?
      @demographic = StudyCompletion.find(cookies[:user_study_completion_id]).build_demographic(create_params)
    end

    respond_to do |format|
      if @demographic.save
        format.html { redirect_to end_of_study_index_path(ue_id: params[:ue_id]) }
        format.json { render :show, status: :created, location: @contact }
      else
        format.html { render :index }
        format.json { render json: @contact.errors, status: :unprocessable_entity }
      end
    end
  end

  def new
    @demographic = Demographic.new
    @ue_id = cookies[:user_study_completion_id]
  end

  def show

  end

  def edit
    @edit = true
    @ue_id = params[:ue_id]
  end

  def update
    if @demographic.update_attributes(demographic_params)
      redirect_to demographics_path
    else
      redirect_to edit_demographics_path
    end
  end

  # DELETE /experiments/1
  # DELETE /experiments/1.json
  # def destroy
  #   current_user.delete_all_associated_results(Feedback::FEEDBACK_TYPE_HASH[:delete_results])
  #   respond_to do |format|
  #     format.html { redirect_to settings_path, notice: 'Demographic and Study Data was successfully deleted.' }
  #     format.json { head :no_content }
  #   end
  # end


  private
  # Never trust parameters from the scary internet, only allow the white list through.
  def demographic_params
    params[:demographic].merge!(ethnicity: []) if params[:demographic].keys.exclude?('ethnicity')

    if params[:demographic][:ethnicity].exclude?('Other')
      params[:demographic].merge!(ethnicity_description: nil)
    end

    # we can still succeed when user leaves ethnicity blank
    params.require(:demographic).permit(:gender, :total_household_income,
      :political_on_social, :political_on_economic, :number_of_people_in_household,
      :highest_level_of_education, :language, :other_language, :birth_year, :country,
      :postal_code_longest, :postal_code_current, :ethnicity_description)
      .merge(ethnicity: params[:demographic][:ethnicity].join(","))
  end

  def find_current_user_demographic
    @demographic = current_user.demographic || current_user.build_demographic
  end
end
