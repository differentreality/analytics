class HomeController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :webhook_notification

  def make_graph
    @result = { data: [], graph_type: params[:graph_type]}


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
    # @result[:data] = [
    #   {"created_time"=>"2018-07-30T04:45:20+0000", "id"=>"295754757450351_291408578279339"},  {"created_time"=>"2018-05-02T16:40:47+0000", "id"=>"295754757450351_589995214692969"},
    #   {"created_time"=>"2018-04-25T20:02:24+0000", "id"=>"295754757450351_170162407029320"}, {"created_time"=>"2018-04-25T18:00:47+0000", "id"=>"295754757450351_586812398344584"}, {"created_time"=>"2016-09-09T11:28:00+0000", "id"=>"295754757450351_304858289873331"}
    # ]
    # puts "result: #{@result.first['created_time'].to_datetime.strftime('%A')}"
    # @result[:data] = @result[:data].map{ |x| x['created_time'].to_s }.group_by{ |x| x.to_datetime.strftime('%A') }.map{ |k, v| [k,v.count]  }


    # posts?fields=insights.metric(post_reactions_by_type_total).period(lifetime).as(post_reactions_by_type_total)
    object = params[:x_axis]
    period = params[:y_axis]
    @result[:data] = get_data(object, period) if object && period

    respond_to do |format|
      format.html { render template: 'home/index'
                    #render json: @result
                  }
      format.js
    end
  end

  def index
    @page_title = @page.try(:name) || get_page_title || 'Lambda Space'
    @page_fans_count = @page.try(:fans) || get_page_fans
    @result = {}
  end

  # Receives
  # GET https://www.your-clever-domain-name.com/webhooks?
  # hub.mode=subscribe&
  # hub.challenge=1158201444&
  # hub.verify_token=meatyhamhock

  # Must return the hub.challenge value
  def confirm_webhook
    puts "In webhook!"
    puts "params: #{params}"
    if params['hub.verify_token'] == 'StellasToken!'
      render plain: params['hub.challenge']
      puts "param to return: #{params['hub.challenge']}"
    else
      render plain: 'Error!'
      puts "returned error"
    end
  end

  # {"entry"=> [{"changes"=>
               # [{"field"=>"feed", "value"=> {"reaction_type"=>"like", "from"=>{"id"=>"2037320319611866",
                                                                    # "name"=>"Stella   Rouzi Differentreality"},
                                      # "parent_id"=>"295754757450351_637257263300097", "post_id"=>"295754757450351_637257263300097", "verb"=>"remove", "item"=>"reaction", "created_time"=>1534875091}}],
    # "id"=>"295754757450351", "time"=>1534875092}],

    # "object"=>"page", "home"=>{"entry"=>[{"changes"=>[{"field"=>"feed", "value"=>{"reaction_type"=>"like", "from"=>{"id"=>"2037320319611866", "name"=>"Stella Rouzi Differentreality"}, "parent_id"=>"295754757450351_637257263300097", "post_id"=>"295754757450351_637257263300097", "verb"=>"remove", "item"=>"reaction", "created_time"
    # =>1534875091}}], "id"=>"295754757450351", "time"=>1534875092}], "object"=>"page"}}

  def webhook_notification
    verb = params['entry'].first['changes'].first['value']['verb']
    posted_at = Time.at(params['entry'].first['changes'].first['value']['created_time'])
    post_id = params['entry'].first['changes'].first['value']['post_id']
    post = Post.where(object_id: post_id).first_or_create

    puts "verb: #{verb}\n posted_at: #{posted_at}\n post: #{post.inspect}"

    if verb == 'add'
      reaction_type = params['entry'].first['changes'].first['value']['reaction_type']
      reaction = Reaction.create!(reactionable: post, name: reaction_type, posted_at: posted_at)
      puts "reaction: #{reaction.inspect}"
    elsif verb == 'remove'
      reaction_type = params['entry'].first['changes'].first['value']['item']
    end

    head :ok
  end
end
