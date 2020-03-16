class PagesController < ApplicationController
  before_action :reset_desired_study

  def home
    cookies[:facebook_redir] = nil
    completed_studies_ids = User.current_completed_studies(
        user_id: current_user&.id,
        current_user_session_id: cookies[:current_user_session_id]
    ).pluck(:study_id).uniq
    @completed_studies = Study.reject_expired_study(Study.where(id: completed_studies_ids).is_published).sort_by(&:study_order)
    @pending_studies = Study.reject_expired_study(Study.where.not(id: completed_studies_ids).is_published).sort_by(&:study_order)
  end

  # I added this in here because I hate the route /contact/new. I wanted /contact.
  def contact
    @contact = Contact.new
  end

  def contact_confirmation
  end

  def privacy
  end

  def terms
  end

  def about
  end
end
