class Admin::UserAdminsController < Admin::AdminController
  def index
    params[:sort_order] = 'asc' if params[:sort_order].blank?
    params[:sort_field] = 'email' if params[:sort_field].blank?

    @users = User.all
    if params[:email_cont].present?
      user_ids = @users.search_like_plaintext(:email, params[:email_cont]).map(&:id)
      @users = @users.where(id: user_ids)
    end

    if params[:role_eq].present?
      user_ids = @users.search_by_plaintext(:role, params[:role_eq].to_i).map(&:id)
      @users = @users.where(id: user_ids)
    end
    orderd_users = @users.sort_by { |u| u.try(params[:sort_field]) }
    orderd_users = orderd_users.reverse if params[:sort_order] == 'desc'
    orderd_users

    @users =  Kaminari.paginate_array(orderd_users).page(params[:page]).per(20)
    # @users = @users.where(id: user_ids).page(params[:page]).per(20)

    flash.now[:error] = "Email not available" if @users.blank?

    authorize! :read, User
  end

  def update
    @user = User.find(params[:id])
    authorize! :read, User

    respond_to do |format|
      if @user.update(role: params[:user][:role].to_i)
        format.html { redirect_to admin_user_admins_path, notice: 'User was successfully updated.' }
        format.json { render :show, status: :ok, location: admin_user_admins_path }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end
end
