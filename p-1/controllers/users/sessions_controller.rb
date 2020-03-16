class Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  def create
    resource = User.search_by_plaintext(:email, sign_in_params[:email])&.first
    if resource.present? && resource.valid_password?(sign_in_params[:password])
      set_flash_message!(:notice, :signed_in) if resource.confirmed?
      sign_in(resource_name, resource)
      yield resource if block_given?
      respond_with resource, location: after_sign_in_path_for(resource)
    else
      super
    end
  end

  # DELETE /resource/sign_out
  def destroy
    reset_desired_study
    cookies[:user_study_completion_id] = nil
    cookies[:save_data] = nil
    cookies[:current_user_session_id] = nil
    super
  end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
end
