class UsersController < ApplicationController
  before_action :authenticate_user!

  def get_pages
    begin
     current_user.get_pages
   rescue => e
     Rails.logger.debug "Error occured while updating user pages. #{e.message}"
   end

    redirect_to pages_path
  end

  def edit
  end

  def update
    unless user_params[:access_token].present?
      flash.now[:error] = 'Access token cannot be empty.'
      render :edit and return
    end

    if current_user.update(user_params)
      redirect_to edit_user_path(current_user)
    else
      flash[:error] = 'Could not update profile. ' + @user.errors.full_messages.to_sentence
      render :edit
    end

  end

  private

  def user_params
    params.require(:user).permit(:access_token)
  end
end
