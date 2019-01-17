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

    begin
      # Update current user access_token
      current_user.update(user_params)
      # Update access tokens for current user's pages
      current_user.get_pages
      redirect_to edit_user_path(current_user) and return
    else
      Rails.logger.info "Could not update access token for user and user's pages, with error: #{current_user.errors.full_messages.to_sentence}"
      flash[:error] = 'Could not update profile. ' + current_user.errors.full_messages.to_sentence
      render :edit and return
    end

  end

  private

  def user_params
    params.require(:user).permit(:access_token)
  end
end
