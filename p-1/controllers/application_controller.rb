class ApplicationController < ActionController::Base
  before_action :reset_consent
  before_action :get_account_closure_feedback
  rescue_from ActiveSupport::MessageEncryptor::InvalidMessage, with: :decrypted_key_issue

  include Pundit
  protect_from_forgery with: :exception

  helper_method :date_as_mmddyy, :is_admin?, :is_admin_or_superadmin?

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end

  def after_sign_in_path_for(resource)
    if cookies[:desired_study] == "" || cookies[:desired_study] == nil
      request.env['omniauth.origin'] || root_path
    else
      study_path(cookies[:desired_study])
    end
  end

  def date_as_mmddyy(date)
    date&.strftime('%m/%d/%y')
  end

  def has_consent?
    current_user || ActiveModel::Type::Boolean.new.cast(cookies[:consent])
  end

  def is_admin?
    if current_user
      return current_user.admin?
    end

    return false
  end

  def is_superadmin?
    if current_user
      return current_user.superadmin?
    end

    return false
  end

  def is_admin_or_superadmin?
    if current_user
      return current_user.superadmin? || current_user.admin?
    end

    return false
  end

  def reset_consent
    cookies[:consent] = false
  end

  def get_account_closure_feedback
    if cookies[:get_account_deletion_feedback].present?
      cookies[:get_account_deletion_feedback] = nil
      redirect_to new_feedback_path
    end
  end

  def reset_desired_study
    cookies[:desired_study] = nil
  end

  def get_started_study study_id
    cookies["started_study_#{study_id}".to_sym]
  end

  def set_started_study study_id
    cookies["started_study_#{study_id}".to_sym] = { value: study_id, expires: Time.zone.now + 10.minutes}
  end

  def reset_started_study study_id
    cookies.delete "started_study_#{study_id}".to_sym
  end

  def validate_current_user
    if !current_user
      redirect_to root_path, notice: "You must be logged in to view that page."
    end
  end

  private

  def decrypted_key_issue
    Rollbar.error('crypt_keeper key errors')
  end
end
