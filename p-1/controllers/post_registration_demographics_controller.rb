class PostRegistrationDemographicsController < ApplicationController
 def index
   # set demographic information here

   # set this cookie to nil because we used it to associate their logged out data with their new account
   cookies[:user_study_completion_id] = nil
   cookies[:save_data] = nil

          # when the user signs up from a save my results button, they may already have demographic information, if so, go ahead and skip the demographic
    if current_user.demographic
      if cookies[:desired_study] == "" || cookies[:desired_study] == nil
        redirect_to root_path
      else
        redirect_to study_path(cookies[:desired_study])
      end
    else
      if cookies[:current_user_session_id].present?
        current_session_id, study_id = cookies[:current_user_session_id].split(':').map(&:to_i)
        # Associate demographics
        Demographic.where(user_session_id: cookies[:current_user_session_id]).update_all(user_id: current_user.id, user_session_id: -1)

        # Associate study_completions
        StudyCompletion.where('user_id IS NULL AND user_session_id iLIKE ?', "#{current_session_id}%").update_all(user_id: current_user.id, user_session_id: -1)
        cookies[:current_user_session_id] = nil
        redirect_to root_path
      else
        @demographic = current_user.build_demographic
        @submit_path = post_registration_demographics_path
      end
    end
  end

  def create
    @submit_path = post_registration_demographics_path
    @demographic = current_user.build_demographic(demographic_params)
    respond_to do |format|
      if @demographic.save
        if cookies[:desired_study] == "" || cookies[:desired_study] == nil
          format.html { redirect_to root_path }
          format.json { render :show, status: :created, location: @contact }
        else
          format.html { redirect_to study_path(cookies[:desired_study]) }
          format.json { render :show, status: :created, location: @contact }
        end
      else
        format.html { render :index }
        format.json { render json: @contact.errors, status: :unprocessable_entity }
      end
    end
  end

 private
 # Never trust parameters from the scary internet, only allow the white list through.
 def demographic_params
   # we can still succeed when user leaves ethnicity blank
   if params[:demographic][:ethnicity]
     params.require(:demographic).permit(:gender, :total_household_income, :political_on_social,
      :political_on_economic, :number_of_people_in_household, :highest_level_of_education,
      :language, :other_language, :birth_year, :postal_code_longest, :postal_code_current, :country,
      :ethnicity_description).merge(ethnicity: params[:demographic][:ethnicity].join(","))
   else
     params.require(:demographic).permit(:gender, :total_household_income, :ethnicity, 
      :political_on_social, :political_on_economic, :number_of_people_in_household, 
      :highest_level_of_education, :language, :other_language, :birth_year, :postal_code_longest, 
      :postal_code_current, :country)
   end
 end
end
