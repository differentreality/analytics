class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :credentials

  before_action :save_return_to

  def credentials
    @access_token = ENV['access_token']
    @page_id = ENV['facebook_page_id']
    @connection = Koala::Facebook::API.new(@access_token)
  end

  def redirect_to_back_or(path)
    if request.env['HTTP_REFERER']
      redirect_to :back
    else
      redirect_to path
    end
  end

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

  def get_page_title
    @result = @connection.get_object(@page_id)
    return @result['name']
  end

  def get_page_fans
    @result = @connection.get_connections(@page_id, "insights/page_fans")
    return @result.first['values'].first['value']
  end

  protected

  def save_return_to
    return unless request.get?
    if request.path != '/user/' && !request.xhr?
      session[:return_to] = request.fullpath
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name])
  end
end
