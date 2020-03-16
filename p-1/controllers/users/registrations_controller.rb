class Users::RegistrationsController < Devise::RegistrationsController
  # before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up

  before_action :set_ethnicity_param, only: :create

  def new
    if ActiveModel::Type::Boolean.new.cast(params[:save]) == true
      cookies[:save_data] = true
    end
    if ActiveModel::Type::Boolean.new.cast(cookies[:pre_registration_consent]) != true
      cookies[:from_nav_bar] = true if params[:from_nav_bar].present?
      redirect_to pre_registration_consent_index_path
    else
      @sign_up_from_nav_bar = true if params[:from_nav_bar].present? || cookies[:from_nav_bar].present?
      @sign_up_with_demographics = true
      super
    end
  end

  # POST /resource
  def create
    @sign_up_with_demographics = true if params[:user][:demographic_attributes].present?

    if verify_recaptcha || Rails.env.development?
      cookies[:pre_registration_consent] = nil
      super { cookies[:current_user_session_id] = nil }
    else
      self.resource = resource_class.new sign_up_params
      resource.validate
      render :new
    end
  end

  # GET /resource/edit
  def edit
    super
  end

  # PUT /resource
  def update
    super
  end

  # DELETE /resource
  def destroy
    if params[:delete_study_data]
      current_user.delete_all_associated_results(Feedback::FEEDBACK_TYPE_HASH[:delete_account_and_results])
      cookies[:get_account_deletion_feedback] = Feedback::FEEDBACK_TYPE_HASH[:delete_account_and_results][:key].to_s
    else
      current_user.set_nil_for_all_associated_results(Feedback::FEEDBACK_TYPE_HASH[:delete_account])
      cookies[:get_account_deletion_feedback] = Feedback::FEEDBACK_TYPE_HASH[:delete_account][:key].to_s
    end
    cookies[:pre_registration_consent] = nil
    cookies[:facebook_redir] = nil
    cookies[:email] = current_user.email
    super
  end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:study_completion_id,
    demographic_attributes: [:gender, :total_household_income, :political_on_social, 
      :political_on_economic, :number_of_people_in_household, :highest_level_of_education, 
      :language, :other_language, :birth_year,  :country, :postal_code_longest, :postal_code_current, 
      :ethnicity, :ethnicity_description]])
  end

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation, :study_completion_id, 
        :user_session_id, demographic_attributes: [:gender, :total_household_income, 
        :political_on_social, :political_on_economic, :number_of_people_in_household, 
        :highest_level_of_education, :language, :other_language, :birth_year, :postal_code_longest, 
        :postal_code_current, :ethnicity, :ethnicity_description, :country])
  end

  def set_ethnicity_param
    ethnicity = params.dig(:user, :demographic_attributes, :ethnicity)
    if ethnicity.present?
      params[:user][:demographic_attributes].merge!(ethnicity: ethnicity.join(','))
    end
  end
  # If you have extra params to permit, append them to the sanitizer.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.permit(:account_update, keys: [:attribute])
  # end

  # The path used after sign up.
  def after_sign_up_path_for(resource)
    post_registration_demographics_path
  end

  # The path used after sign up for inactive accounts.
  def after_inactive_sign_up_path_for(resource)
    # 2 demographics records are created for anon user
    # Quick fix, delete all demographics record except latest one
    Demographic.where(user_id: resource.id).order(created_at: :desc).each_with_index do |demo, i|
      next if i == 0
      demo.destroy
    end
    after_signup_path
  end

  # To send the confirmation link to the user
  def resend_confirmation
    if params[:user].present?
      user = search_user_by_plain_text(email: params[:user][:email])
      if user.present?
        user.send_confirmation_instructions
        flash[:notice] = I18n.t('devise.confirmations.send_instructions.')
        redirect_to new_user_session_path
      else
        flash[:error] = I18n.t('errors.messages.unable_to_send_confirmation.')
        redirect_to new_user_session_path
      end
    end
  end

  # Find the user by email
  def search_user_by_plain_text(email:)
    User.search_by_plaintext(:email, email)&.first
  end
end
