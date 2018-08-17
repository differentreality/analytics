class HomeController < ApplicationController
  require 'net/http'

  def make_graph
    @result = []
    #
    # uri = URI("https://graph.facebook.com/#{@page_id}")
    # params = {access_token: @token}
    # uri.query = URI.encode_www_form( params )
    # @result = Net::HTTP.get(uri)
    #
    # puts "result: #{@result}"

    # @graph = Koala::Facebook::API.new(@access_token)
    # Koala.config.api_version = "v2.0"
    # @graph.get_object("me", {}, api_version: "v2.0")
    # @result = @graph.get_connections(@page_id, "feed")
    # me/posts?fields=message, created_time,reactions

    # me/insights/page_fans
    # @result = @graph.get_connections(@page_id, "insights/page_fans")

    # me/posts?fields=created_time
    # Returns array of hashes
    # @result = @connection.get_object("#{@page_id}/posts", { fields: 'created_time' })
    #
    # next_page = @result.next_page
    # while next_page.present?
    #   @result << next_page
    #   next_page.map{ |x| @result << x}
    #   next_page = next_page.next_page
    # end
    @result = [
      {"created_time"=>"2018-07-30T04:45:20+0000", "id"=>"295754757450351_291408578279339"},  {"created_time"=>"2018-05-02T16:40:47+0000", "id"=>"295754757450351_589995214692969"},
      {"created_time"=>"2018-04-25T20:02:24+0000", "id"=>"295754757450351_170162407029320"}, {"created_time"=>"2018-04-25T18:00:47+0000", "id"=>"295754757450351_586812398344584"}, {"created_time"=>"2016-09-09T11:28:00+0000", "id"=>"295754757450351_304858289873331"}
    ]
    # puts "result: #{@result.first['created_time'].to_datetime.strftime('%A')}"
    @result = @result.map{ |x| x['created_time'].to_s }.group_by{ |x| x.to_datetime.strftime('%A') }.map{ |k, v| [k,v.count]  }


    # posts?fields=insights.metric(post_reactions_by_type_total).period(lifetime).as(post_reactions_by_type_total)

    respond_to do |format|
      format.html { render template: 'home/index'
                    #render json: @result
                  }
    end
  end

  def index
    # @page_title = get_page_title || 'Lambda Space'
    # @page_fans_count = get_page_fans || 933
  end
end
