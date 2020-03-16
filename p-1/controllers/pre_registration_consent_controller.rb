class PreRegistrationConsentController < ApplicationController
  def index
    if cookies[:facebook_redir] == nil || cookies[:facebook_redir] == ""
      @next_page_path = new_user_registration_path
    else
      @next_page_path = omniauth_authorize_path(:user, :facebook)
    end
  end

  def create
    # consent and redirect to sign up path!
    cookies[:pre_registration_consent] = true

    redirect_to(new_user_registration_path)
  end
end
