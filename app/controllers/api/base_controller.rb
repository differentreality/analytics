module Api
  class BaseController < ActionController::Base
    before_action :credentials
    protect_from_forgery with: :exception


    def connection_result(method, object, params=nil)
      @result = begin
                  if method == 'get_object'
                    @connection.get_object(object)
                  elsif method == 'get_connections'
                    @connection.get_connections(object, params)
                  end
                rescue => e
                  Rails.logger.debug "Could not retrieve data from Facebook. #{e.message}"
                  error = "Could not retrieve data from Facebook. #{e.message}"
                end
      if error
        return error
      else
        return @result
      end
    end

    def credentials
      @access_token = params['access_token'] || ENV['access_token']
      @page_id = params['facebook_page_id'] || ENV['facebook_page_id']
      @page = Page.find_by(object_id: @page_id)
      @connection = Koala::Facebook::API.new(@access_token)
    end

  end
end
