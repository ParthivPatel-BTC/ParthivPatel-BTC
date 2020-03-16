class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # You should configure your model like this:
  # devise :omniauthable, omniauth_providers: [:twitter]

  # You should also create an action method in this controller like this:
  # def twitter
  # end
    def facebook
      auth = request.env["omniauth.auth"]
      @user = User.search_by_plaintext(:email, auth.info.email)&.first

      if @user
        @user.provider = auth.provider
        @user.uid = auth.uid
        @user
      else
        @user = User.from_omniauth(auth)
      end
      sign_in @user

      @user.update(study_completion_id: cookies[:user_study_completion_id])

      # if someone clicks the save data button, ensure they have their data saved if they do a facebook signup.
      @user.set_study_completions_with_user_id
      redirect_to post_registration_demographics_path
    end

  # More info at:
  # https://github.com/plataformatec/devise#omniauth

  # GET|POST /resource/auth/twitter
  # def passthru
  #   super
  # end

  # GET|POST /users/auth/twitter/callback
  # def failure
  #   super
  # end

  # protected

  # The path used when OmniAuth fails
  # def after_omniauth_failure_path_for(scope)
  #   super(scope)
  # end
end
