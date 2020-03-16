class FeedbacksController < ApplicationController

  # This is actually feedback edit action. Action name is 'new' because we don't want to reveal feedback id to user
  # Feedback will be retrieved from cookie as the user has already been destroyed
  def new
    if cookies[:email] && cookies[:get_account_deletion_feedback]
      @feedback = Feedback.where(email: cookies[:email]).last
    else
      redirect_to root_path
    end
  end

  def update
    if cookies[:email] && cookies[:get_account_deletion_feedback]
      feedback = Feedback.where(email: cookies[:email]).last
      feedback.update_attributes(content: params[:feedback][:content])
      mailer = AccountDeletionFeedbackMailer.deletion_notification(feedback)
      mailer.deliver!
    end
    redirect_to root_path
  end
end
