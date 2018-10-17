module Api
  class PagesController < Api::BaseController
    # respond_to :json
    skip_before_action :verify_authenticity_token

    def page_fans_city
      result = []
      result = connection_result('get_connections',
                                 "#{@page_id}/insights/page_fans_city")
      puts "Api result: #{result}"

      render json: @result.to_json
    end
  end
end
