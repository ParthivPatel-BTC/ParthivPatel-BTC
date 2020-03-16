class FacebookRedirController < ApplicationController
  def index
    if cookies[:pre_registration_consent] == nil || cookies[:pre_registration_consent] == ""
      cookies[:facebook_redir] = true
      redirect_to pre_registration_consent_index_path
    else
      redirect_to omniauth_authorize_path(:user, :facebook)
    end
  end
end
