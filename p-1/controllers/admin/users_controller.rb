class Admin::UsersController < Admin::AdminController
  def index
    @demos = Demographic.all
    @user_count = User.count
    @study_completions = StudyCompletion.count
    @social_hash = @demos.political_on_social_hash
    @economic_hash = @demos.political_on_economic_hash
    @ethnicity_hash = @demos.ethnicity_hash
    @education_hash = @demos.education_hash
    @percent_english = @demos.percent_english
    @average_studies_completed_per_user = (@study_completions.to_f / @user_count).round(2)
  end
end