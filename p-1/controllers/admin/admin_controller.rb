class Admin::AdminController < ApplicationController
  before_action :authenticate_user!, :authorize_admin_or_super_admin!

  def authorize_admin_or_super_admin!
    unless (current_user.admin?) || current_user.superadmin?
      raise CanCan::AccessDenied
    end
  end
end
