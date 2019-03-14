class UsersController < ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource

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

  def destroy
    # user_id = @user.id
    begin
      user_pages = @user.pages.select{ |page| page.users == [@user] }
      user_pages.each(&:destroy)
      @user.destroy
      flash[:notice] = "We have permanently deleted your user account, and #{user_pages.count} page(s)."
      redirect_to root_path
    rescue => e
      Rails.logger.debug "Error deleting user #{@user.inspect} and user pages: #{user_pages.count}. #{e.message}"
      flash[:error] = 'There was an error while deleting your account and its information. Please try again or contact us.'
      redirect_to edit_user_path
    end
  end

  private

  def user_params
    params.require(:user).permit(:access_token)
  end
end
