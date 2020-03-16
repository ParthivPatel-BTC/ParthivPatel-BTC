class EndOfStudyController < ApplicationController
  def index
    reset_desired_study # if you made it this far, you no longer need to be redirected to a study after sign up

    if current_user
      @user_study_completion_id = params[:ue_id]
      @end_of_study = current_user.study_completions.find(@user_study_completion_id)
      reset_started_study(@end_of_study.study_id)
    else
      @end_of_study = StudyCompletion.find(cookies[:user_study_completion_id])
    end
  end


  def create
    if current_user
      @user_study_completion_id = params[:user_study_completion_id]
      @end_of_study = current_user.study_completions.find(@user_study_completion_id)
      if @end_of_study.update_attributes(end_of_study_params)
        redirect_to result_path(@user_study_completion_id)
      end
    else
      @user_study_completion_id = cookies[:user_study_completion_id]
      @end_of_study = StudyCompletion.find(@user_study_completion_id)
      if @end_of_study.update_attributes(end_of_study_params)
        redirect_to result_path(@user_study_completion_id)
      end
    end
  end

  private
  # Never trust parameters from the scary internet, only allow the white list through.
  def end_of_study_params
    params.require(:study_completion).permit(:similar_experiment, :taken_survey_before,
      :technical_problems, :technical_problem_description, :did_you_cheat, :cheating_description ,:people_in_room, :comments)
  end

end
