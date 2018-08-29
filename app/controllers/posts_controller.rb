class PostsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :webhook_notification
  load_resource

  def show
  end
end
