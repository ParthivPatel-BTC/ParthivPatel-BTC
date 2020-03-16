class ConsentController < ApplicationController
  def index
    @study_id = params[:study_id]
  end

  def create
    # consent and redirect to survey!
    cookies[:consent] = true
    if current_user
      current_user.set_consent
    end

    if verify_recaptcha || Rails.env.development?
      redirect_to(study_path(params[:study_id]))
    else
      render js: "alert('Please verify that you are human.')"
    end
  end
end
