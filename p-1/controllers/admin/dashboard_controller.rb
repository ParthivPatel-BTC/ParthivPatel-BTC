class Admin::DashboardController < Admin::AdminController
  def index
    @studies = if current_user.superadmin?
      Study.all
    else
      current_user.studies
    end
    authorize! :read, StudyCompletion
  end
end
